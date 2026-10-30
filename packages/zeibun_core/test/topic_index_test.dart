import 'package:test/test.dart';
import 'package:zeibun_core/zeibun_core.dart';

void main() {
  test('a practitioner word finds its topic', () {
    expect(topicsFor('インボイス').map((t) => t.name), ['インボイス（適格請求書）']);
  });

  test('a longer word that contains a keyword still finds the topic', () {
    expect(topicsFor('インボイス制度 登録').map((t) => t.name), ['インボイス（適格請求書）']);
    expect(topicsFor('給与所得').map((t) => t.name), contains('給与'));
  });

  test('a word unrelated to any topic finds nothing', () {
    expect(topicsFor('課税標準'), isEmpty);
    expect(topicsFor('  '), isEmpty);
  });

  test('every article in the index points to a well-formed article number', () {
    for (final topic in builtInTopics) {
      expect(topic.articles, isNotEmpty, reason: topic.name);
      for (final a in topic.articles) {
        expect(a.articleNum, matches(RegExp(r'^\d+(_\d+)*$')),
            reason: '${topic.name} ${a.articleTitle}');
        expect(articleNumFromTitle(a.articleTitle), a.articleNum,
            reason: '${topic.name}: 条名と条番号が食い違う');
      }
    }
  });
}
