import 'package:material_ui/material_ui.dart';

import 'i18n_fil.dart';
import 'i18n_fil_account.dart';
import 'i18n_fil_beginner.dart';
import 'i18n_fil_bids.dart';
import 'i18n_fil_contract.dart';
import 'i18n_fil_costs.dart';
import 'i18n_fil_exterior.dart';
import 'i18n_fil_fees.dart';
import 'i18n_fil_install.dart';
import 'i18n_fil_materials.dart';
import 'i18n_fil_rooms.dart';
import 'i18n_fil_structure.dart';

/// Every Filipino table, looked up in order.
const filipinoTables = [
  filipino,
  filipinoMaterials,
  filipinoCosts,
  filipinoStructure,
  filipinoExterior,
  filipinoContract,
  filipinoFees,
  filipinoBids,
  filipinoRooms,
  filipinoAccount,
  filipinoInstall,
  filipinoBeginner,
];

String? _filipino(String english) {
  for (final table in filipinoTables) {
    if (table[english] case final text?) return text;
  }
  return null;
}

/// The languages the app is shown in. Calculations, documents and the
/// definitions behind each calculator stay in English.
enum AppLanguage {
  english('English'),
  filipino('Filipino');

  const AppLanguage(this.label);

  /// The language's name in itself.
  final String label;
}

/// Makes the user's language available to [Translate.tr] below it.
class AppLanguageScope extends InheritedWidget {
  const AppLanguageScope({
    super.key,
    required this.language,
    required super.child,
  });

  final AppLanguage language;

  static AppLanguage of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AppLanguageScope>()
          ?.language ??
      AppLanguage.english;

  @override
  bool updateShouldNotify(AppLanguageScope oldWidget) =>
      oldWidget.language != language;
}

/// [english] in [language], with each `{name}` replaced by its value in
/// [args]. Text without a translation is shown in English.
String translate(
  String english,
  AppLanguage language, [
  Map<String, Object> args = const {},
]) {
  var text = switch (language) {
    AppLanguage.english => english,
    AppLanguage.filipino => _filipino(english) ?? english,
  };
  for (final MapEntry(:key, :value) in args.entries) {
    text = text.replaceAll('{$key}', '$value');
  }
  return text;
}

extension Translate on BuildContext {
  /// [english] in the user's language; see [translate].
  String tr(String english, [Map<String, Object> args = const {}]) =>
      translate(english, AppLanguageScope.of(this), args);
}
