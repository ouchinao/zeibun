// Phase 0 スパイク CLI。
//
//   dart run bin/spike.dart catalog [--out DIR]
//       実 API に対して設計書 §4.2 の一覧取得を行い、件数・通信量・asof の挙動・CORS を確認する
//   dart run bin/spike.dart fetch   [--out DIR] [--ids ID,ID] [--formats xml,json]
//       主要税法の本文（XML / JSON）を取得して保存し、サイズと所要時間を記録する
//   dart run bin/spike.dart bench   --dir DIR [--repeat N]
//       DIR 内の *.xml / *.json を Dart でパースし、時間・メモリ・条数を計測する
//   dart run bin/spike.dart synth   --articles N --out DIR
//       合成法令を生成する（実 API に届かない環境での規模感の確認用）
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:xml/xml.dart';
import 'package:zeibun_spike/zeibun_spike.dart';

/// 設計書 §13 Phase 0 の計測対象（主要税法 10 件 + 地方法人税法）。
const List<String> benchmarkLawIds = [
  '340AC0000000033', // 所得税法
  '340CO0000000096', // 所得税法施行令
  '340AC0000000034', // 法人税法
  '340CO0000000097', // 法人税法施行令
  '363AC0000000108', // 消費税法
  '325AC0000000073', // 相続税法
  '332AC0000000026', // 租税特別措置法
  '332CO0000000043', // 租税特別措置法施行令
  '337AC0000000066', // 国税通則法
  '325AC0000000226', // 地方税法
  '426AC0000000011', // 地方法人税法
];

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addCommand('catalog', ArgParser()..addOption('out', defaultsTo: 'out'))
    ..addCommand(
        'fetch',
        ArgParser()
          ..addOption('out', defaultsTo: 'out/bodies')
          ..addOption('ids', help: 'law_id をカンマ区切り。既定は benchmarkLawIds')
          ..addOption('formats', defaultsTo: 'xml,json'))
    ..addCommand(
        'bench',
        ArgParser()
          ..addOption('dir', mandatory: true)
          ..addOption('repeat', defaultsTo: '3'))
    ..addCommand(
        'synth',
        ArgParser()
          ..addOption('articles', defaultsTo: '2000')
          ..addOption('out', defaultsTo: 'out/synth'));
  final args = parser.parse(argv);
  final cmd = args.command;
  if (cmd == null) {
    stderr.writeln(parser.usage);
    for (final c in parser.commands.entries) {
      stderr.writeln('  ${c.key}\n${c.value.usage}');
    }
    exit(2);
  }
  switch (cmd.name) {
    case 'catalog':
      await runCatalog(cmd['out'] as String);
    case 'fetch':
      await runFetch(
        cmd['out'] as String,
        (cmd['ids'] as String?)?.split(',') ?? benchmarkLawIds,
        (cmd['formats'] as String).split(','),
      );
    case 'bench':
      await runBench(cmd['dir'] as String, int.parse(cmd['repeat'] as String));
    case 'synth':
      await runSynth(
          int.parse(cmd['articles'] as String), cmd['out'] as String);
  }
}

String _kb(int bytes) => '${(bytes / 1024).toStringAsFixed(1)} KB';
String _mb(int bytes) => '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
String _ms(Duration d) => '${d.inMilliseconds} ms';

// ---------------------------------------------------------------- catalog

Future<void> runCatalog(String outDir) async {
  final client = EgovClient(onLog: stderr.writeln);
  final out = Directory(outDir)..createSync(recursive: true);
  final scope = LawScope.tax;
  final sw = Stopwatch()..start();
  final report = StringBuffer(
      '# catalog (${DateTime.now().toUtc().toIso8601String()})\n\n');

  // CORS: Origin ヘッダを付けて Access-Control-Allow-Origin を見る
  final cors = await client.get('laws', {
    'category_cd': '023',
    'limit': '1',
    'response_format': 'json',
  }, {
    'Origin': 'https://zeibun.example'
  });
  final acao = cors.headers['access-control-allow-origin'];
  final code023 = ((cors.json as Map)['laws'] as List).isEmpty
      ? '(none)'
      : LawSummary.fromApiRow(
              (((cors.json as Map)['laws'] as List).first as Map)
                  .cast<String, dynamic>())
          .category;
  report.writeln('- access-control-allow-origin: `${acao ?? "(なし)"}`');
  report.writeln('- category_cd=023 → `$code023`（公式表では 国債）');

  final byReason = <String, List<LawSummary>>{};
  final pending = <LawSummary>[];
  var withCurrentInfo = 0;
  var rows = 0;
  final table = StringBuffer(
      '\n| クエリ | HTTP | total_count | count | wire | raw | time |\n|---|---|---|---|---|---|---|\n');

  Future<void> run(Map<String, String> q) async {
    var offset = 0;
    while (true) {
      // repeal_status は絞らない（廃止・失効法令は「参考」として一覧に載せる）
      final query = {
        ...q,
        'asof': '2099-12-31',
        'response_format': 'json',
        if (offset > 0) 'offset': '$offset',
      };
      final r = await client.laws(query);
      final body = r.json as Map<String, dynamic>;
      final laws = (body['laws'] as List).cast<Map<dynamic, dynamic>>();
      final label = q.entries.map((e) => '${e.key}=${e.value}').join('&');
      table.writeln('| `$label` | ${r.statusCode} | ${body['total_count']} | '
          '${body['count']} | ${_kb(r.wireBytes)} | ${_kb(r.bytes.length)} | ${_ms(r.elapsed)} |');
      File('${out.path}/laws_${label.replaceAll(RegExp('[^0-9A-Za-z_]'), '_')}.json')
          .writeAsBytesSync(r.bytes);
      for (final row in laws) {
        rows++;
        final m = row.cast<String, dynamic>();
        final current = m['current_revision_info'];
        if (current is Map) withCurrentInfo++;
        final law = LawSummary.fromApiRow(m);
        final reason = scope.reasonFor(law);
        if (reason == null) continue;
        byReason.putIfAbsent(reason, () => []).add(law);
        if (law.hasPendingAmendment) pending.add(law);
      }
      final next = body['next_offset'];
      if (next is int && laws.isNotEmpty) {
        offset = next;
      } else {
        break;
      }
    }
  }

  for (final q in scope.catalogQueries()) {
    await run(q);
  }
  sw.stop();

  report.writeln(table);
  report.writeln('- 受信行数 $rows、うち current_revision_info あり $withCurrentInfo');
  for (final e in byReason.entries) {
    report.writeln('- ${e.key}: ${e.value.length} 件');
  }
  final total = byReason.values.fold<int>(0, (n, l) => n + l.length);
  report.writeln('- スコープ合計 $total 件、未施行改正あり ${pending.length} 件');
  report.writeln(
      '- リクエスト ${client.requestCount} 回、wire 合計 ${_kb(client.totalWireBytes)}、'
      'raw 合計 ${_kb(client.totalBytes)}、所要 ${_ms(sw.elapsed)}（5 req/s 制限込み）');
  report.writeln('\n## 未施行改正あり（施行日順、先頭 20 件）\n');
  pending.sort((a, b) =>
      (a.currentEnforcedAt ?? '').compareTo(b.currentEnforcedAt ?? ''));
  for (final l in pending.take(20)) {
    report.writeln('- ${l.title}（現行 ${l.currentRevisionId}）');
  }
  File('${out.path}/scope.json')
      .writeAsStringSync(const JsonEncoder.withIndent(' ').convert({
    for (final e in byReason.entries)
      e.key: e.value
          .map((l) => {
                'law_id': l.lawId,
                'title': l.title,
                'current_revision_id': l.currentRevisionId,
                'pending_revision_id': l.pendingRevisionId,
                'repeal_status': l.repealStatus
              })
          .toList(),
  }));
  File('${out.path}/catalog_report.md').writeAsStringSync(report.toString());
  stdout.write(report);
  client.close();
}

// ------------------------------------------------------------------ fetch

Future<void> runFetch(
    String outDir, List<String> ids, List<String> formats) async {
  final client = EgovClient(onLog: stderr.writeln);
  final out = Directory(outDir)..createSync(recursive: true);
  final report = StringBuffer(
      '# fetch (${DateTime.now().toUtc().toIso8601String()})\n\n'
      '| 法令 | revision_id | 形式 | HTTP | wire | raw | time |\n|---|---|---|---|---|---|---|\n');
  for (final id in ids) {
    final r = await client.laws({'law_id': id, 'limit': '1'});
    final laws =
        ((r.json as Map)['laws'] as List).cast<Map<dynamic, dynamic>>();
    if (laws.isEmpty) {
      report.writeln('| $id | (not found) | | | | | |');
      continue;
    }
    final law = LawSummary.fromApiRow(laws.first.cast<String, dynamic>());
    final rev = law.currentRevisionId!;
    for (final fmt in formats) {
      try {
        final f = await client.lawFile(fmt, rev);
        File('${out.path}/$rev.$fmt').writeAsBytesSync(f.bytes);
        report.writeln('| ${law.title} | $rev | $fmt | ${f.statusCode} | '
            '${_kb(f.wireBytes)} | ${_kb(f.bytes.length)} | ${_ms(f.elapsed)} |');
      } on EgovHttpException catch (e) {
        report.writeln(
            '| ${law.title} | $rev | $fmt | ${e.statusCode} | | | $e |');
      }
    }
  }
  report.writeln(
      '\nリクエスト ${client.requestCount} 回、wire 合計 ${_mb(client.totalWireBytes)}、'
      'raw 合計 ${_mb(client.totalBytes)}');
  File('${out.path}/fetch_report.md').writeAsStringSync(report.toString());
  stdout.write(report);
  client.close();
}

// ------------------------------------------------------------------ bench

class _Bench {
  _Bench(this.name, this.format, this.bytes);
  final String name;
  final String format;
  final int bytes;
  Duration decode = Duration.zero; // bytes → LawNode
  Duration parse = Duration.zero; // LawNode → ArticleRecord[]
  int elements = 0;
  int main = 0, suppl = 0, appdx = 0;
  int plainChars = 0;
  int bodyJsonGz = 0;
  int rssDeltaMb = 0;
}

Future<void> runBench(String dir, int repeat) async {
  final files = Directory(dir)
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.xml') || f.path.endsWith('.json'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  if (files.isEmpty) {
    stderr.writeln('no *.xml / *.json in $dir');
    exit(1);
  }
  const lawParser = LawParser();
  final results = <_Bench>[];
  for (final f in files) {
    final bytes = f.readAsBytesSync();
    final fmt = f.path.endsWith('.xml') ? 'xml' : 'json';
    final b = _Bench(f.uri.pathSegments.last, fmt, bytes.length);
    Duration bestDecode = const Duration(days: 1),
        bestParse = const Duration(days: 1);
    LawNode? law;
    List<ArticleRecord>? records;
    final rssBefore = ProcessInfo.currentRss;
    var rssPeak = rssBefore;
    for (var i = 0; i < repeat; i++) {
      final sw = Stopwatch()..start();
      final text = utf8.decode(bytes);
      law = fmt == 'xml'
          ? LawNode.fromXml(XmlDocument.parse(text).rootElement)
          : LawNode.fromJson(jsonDecode(text) as Map<String, dynamic>);
      sw.stop();
      if (sw.elapsed < bestDecode) bestDecode = sw.elapsed;
      final sw2 = Stopwatch()..start();
      records = lawParser.parse(law);
      sw2.stop();
      if (sw2.elapsed < bestParse) bestParse = sw2.elapsed;
      final rss = ProcessInfo.currentRss;
      if (rss > rssPeak) rssPeak = rss;
    }
    b.decode = bestDecode;
    b.parse = bestParse;
    b.elements = law!.elementCount;
    b.main = records!.where((r) => r.section == 'main').length;
    b.suppl = records.where((r) => r.section == 'suppl').length;
    b.appdx = records.where((r) => r.section == 'appdx').length;
    b.plainChars = records.fold(0, (n, r) => n + r.plainText.length);
    b.bodyJsonGz = records.fold(
        0,
        (n, r) =>
            n + gzip.encode(utf8.encode(jsonEncode(r.body.toJson()))).length);
    b.rssDeltaMb = ((rssPeak - rssBefore) / 1024 / 1024).round();
    results.add(b);
    stderr.writeln('${b.name}: decode ${_ms(b.decode)} parse ${_ms(b.parse)}');
  }
  final md = StringBuffer(
      '# bench (${DateTime.now().toUtc().toIso8601String()}, Dart ${Platform.version.split(' ').first}, '
      '${Platform.operatingSystem}, best of $repeat)\n\n'
      '| ファイル | 形式 | サイズ | 要素数 | decode→LawNode | parse→条 | 条(本則/附則/別表) | plain_text 文字数 | body_json gz | RSS増 |\n'
      '|---|---|---|---|---|---|---|---|---|---|\n');
  for (final b in results) {
    md.writeln(
        '| ${b.name} | ${b.format} | ${_mb(b.bytes)} | ${b.elements} | ${_ms(b.decode)} | '
        '${_ms(b.parse)} | ${b.main}/${b.suppl}/${b.appdx} | ${b.plainChars} | ${_mb(b.bodyJsonGz)} | ${b.rssDeltaMb} MB |');
  }
  File('$dir/bench_report.md').writeAsStringSync(md.toString());
  stdout.write(md);
}

// ------------------------------------------------------------------ synth

Future<void> runSynth(int articles, String outDir) async {
  final out = Directory(outDir)..createSync(recursive: true);
  final s = SyntheticLaw(articles: articles);
  final xml = s.toXmlString();
  final json = s.toJsonString();
  File('${out.path}/synth_$articles.xml').writeAsStringSync(xml);
  File('${out.path}/synth_$articles.json').writeAsStringSync(json);
  stdout.writeln(
      'synth_$articles: xml ${_mb(utf8.encode(xml).length)}, json ${_mb(utf8.encode(json).length)}');
}
