import 'package:flutter/foundation.dart';
import 'package:zeibun_core/zeibun_core.dart';

import '../db/database.dart';
import '../egov/egov_api.dart';
import 'law_repository.dart';

/// 進み具合。実行中と終了後で同じ数字を見せるので 1 つの型にまとめる。
class PrefetchProgress {
  const PrefetchProgress({
    this.done = 0,
    this.total = 0,
    this.failed = 0,
    this.bytes = 0,
  });
  final int done;
  final int total;
  final int failed;
  final int bytes;

  PrefetchProgress copyWith({int? done, int? failed, int? bytes}) =>
      PrefetchProgress(
        done: done ?? this.done,
        total: total,
        failed: failed ?? this.failed,
        bytes: bytes ?? this.bytes,
      );
}

sealed class PrefetchState {
  const PrefetchState();
}

class PrefetchIdle extends PrefetchState {
  const PrefetchIdle();
}

class PrefetchRunning extends PrefetchState {
  const PrefetchRunning(this.progress, {this.currentTitle = ''});
  final PrefetchProgress progress;
  final String currentTitle;
}

enum PrefetchOutcome {
  completed,
  cancelled,

  /// 通信できない状態が続いたので途中でやめた
  offline,

  /// 想定していない例外（DB の書き込み失敗など）で止めた
  aborted,
}

class PrefetchFinished extends PrefetchState {
  const PrefetchFinished(this.progress, this.outcome);
  final PrefetchProgress progress;
  final PrefetchOutcome outcome;
}

/// 起動時同期に組み込まず利用者の明示操作にしているのは、数百 MB の通信を
/// 本人の知らないうちに始めないため（設計書 §4.4、§11 D）。並列に取らないのは
/// 5 req/s の自主制限を守るため。
class PrefetchService {
  PrefetchService({
    required this.db,
    required this.repo,
    this.maxConsecutiveOfflineFailures = 3,
  });

  final AppDatabase db;
  final LawRepository repo;

  /// 最後まで試さずに打ち切るのは、圏外で 400 件ぶんのタイムアウトを待たせないため。
  final int maxConsecutiveOfflineFailures;

  final ValueNotifier<PrefetchState> state =
      ValueNotifier(const PrefetchIdle());

  Future<PrefetchState>? _inFlight;
  bool _cancelRequested = false;

  /// 廃止・失効を除くのは参考扱いで検索の主対象にしないため。一覧から消えた法令を
  /// 除くのは、現行リビジョンの裏付けが無く取っても古い可能性があるため。
  Future<List<Law>> targets() async => [
        for (final l in await db.allLaws())
          if (!l.isReference &&
              l.missingSince == null &&
              l.currentRevisionId != null &&
              l.bodyCache != BodyCache.current)
            l,
      ];

  /// 実行中なら同じ実行に相乗りする（画面の連打で 2 本走らせない）。
  Future<PrefetchState> start() =>
      _inFlight ??= _run().whenComplete(() => _inFlight = null);

  /// 今取っている法令が終わった時点で止まる。取得途中の法令は保存されない
  /// （`replaceArticles` が 1 トランザクション）ので、中断で本文が欠けることはない。
  void cancel() => _cancelRequested = true;

  Future<PrefetchState> _run() async {
    _cancelRequested = false;
    // 対象を数え終わる前から「実行中」にする。待機のままだと、その間の再タップで
    // 画面が確認ダイアログをもう一度出してしまう
    state.value = const PrefetchRunning(PrefetchProgress());
    var progress = const PrefetchProgress();
    var outcome = PrefetchOutcome.completed;
    try {
      final laws = await targets();
      progress = PrefetchProgress(total: laws.length);
      var offlineStreak = 0;
      for (final law in laws) {
        if (_cancelRequested) {
          outcome = PrefetchOutcome.cancelled;
          break;
        }
        state.value = PrefetchRunning(progress, currentTitle: law.title);
        try {
          final bytes = await repo.fetchBody(law.lawId, law.currentRevisionId!,
              includeAmendSuppl: law.bodyIncludesAmendSuppl);
          progress = progress.copyWith(
              done: progress.done + 1, bytes: progress.bytes + bytes);
          offlineStreak = 0;
        } on EgovApiException catch (e) {
          progress = progress.copyWith(failed: progress.failed + 1);
          if (e.kind.isOffline &&
              ++offlineStreak >= maxConsecutiveOfflineFailures) {
            outcome = PrefetchOutcome.offline;
            break;
          }
        } on FormatException catch (e) {
          // その法令だけ飛ばす。次に開いたときに取り直す
          progress = progress.copyWith(failed: progress.failed + 1);
          debugPrint('prefetch: malformed body for ${law.lawId}: $e');
        } on RevisionMismatch catch (e) {
          progress = progress.copyWith(failed: progress.failed + 1);
          debugPrint('prefetch: ${law.lawId}: $e');
        }
      }
    } catch (e) {
      // 分類できない例外で「実行中」のまま残さない。残したままだと画面が進捗表示で
      // 固まり、やり直す手段が無くなる
      debugPrint('prefetch aborted: $e');
      outcome = PrefetchOutcome.aborted;
    }
    return state.value = PrefetchFinished(progress, outcome);
  }
}
