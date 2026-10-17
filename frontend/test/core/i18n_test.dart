import 'package:flutter_test/flutter_test.dart';
import 'package:thesismob/core/i18n.dart';
import 'package:thesismob/core/i18n_fil_beginner.dart';
import 'package:thesismob/core/i18n_fil_materials.dart';
import 'package:thesismob/materials/catalog.dart';
import 'package:thesismob/materials/material_spec.dart';
import 'package:thesismob/materials/plain_language.dart';

void main() {
  test('translations keep their placeholders', () {
    final placeholder = RegExp(r'\{\w+\}');
    Set<String> names(String s) => {
      for (final m in placeholder.allMatches(s)) m[0]!,
    };
    for (final MapEntry(:key, :value) in {
      for (final table in filipinoTables) ...table,
    }.entries) {
      expect(names(value), names(key), reason: key);
    }
  });

  test('calculator labels are translated by their exact English', () {
    // A typo in a key would leave the label in English unnoticed.
    final english = <String>{
      for (final m in allMaterials) ...[
        m.name,
        m.blurb,
        for (final f in m.numbers) ...[f.label, ?f.hint],
        for (final c in m.choices) ...[
          c.label,
          ?c.helper,
          for (final o in c.options) o.label,
        ],
      ],
    };
    final category = {
      for (final c in MaterialCategory.values) ...[c.label, c.tagline],
    };
    for (final key in filipinoMaterials.keys) {
      expect(
        english.contains(key) || category.contains(key),
        isTrue,
        reason: key,
      );
    }
  });

  test('every calculator and group has everyday words, in Filipino too', () {
    for (final m in allMaterials) {
      expect(plainMaterialWords, contains(m.id), reason: m.id);
    }
    for (final c in MaterialCategory.values) {
      expect(plainCategoryWords, contains(c.name), reason: c.name);
    }
    for (final (a, b) in [
      ...plainMaterialWords.values,
      ...plainCategoryWords.values,
    ]) {
      expect(filipinoBeginner, contains(a));
      expect(filipinoBeginner, contains(b));
    }
  });

  test('missing translations fall back to English, and fill in values', () {
    expect(translate('Wall length', AppLanguage.filipino), 'Haba ng pader');
    expect(translate('Wall length', AppLanguage.english), 'Wall length');
    expect(
      translate('Nonexistent text', AppLanguage.filipino),
      'Nonexistent text',
    );
    expect(
      translate('Add to {project}', AppLanguage.filipino, {'project': 'Bahay'}),
      'Idagdag sa Bahay',
    );
  });
}
