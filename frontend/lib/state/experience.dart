import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../core/i18n.dart';
import '../data/account.dart';
import '../materials/material_spec.dart';
import '../materials/plain_language.dart';
import 'account_controller.dart';
import 'appearance_controller.dart';

/// Names and descriptions in the words that suit the user: everyday words
/// on the Homeowners Edition for someone new to construction, trade names
/// for everyone else. The Business and Enterprise editions always use
/// trade names.
extension ExperienceWords on BuildContext {
  /// Whether the Homeowners Edition is in force, where the app asks
  /// whether the user knows construction.
  bool get asksExperience =>
      select<AccountController, bool>((a) => a.plan == AppPlan.free);

  /// Whether to show everyday words instead of trade names.
  bool get plainWords =>
      asksExperience &&
      select<AppearanceController, bool>(
        (a) => a.experience == Experience.beginner,
      );

  /// The calculator's name, in the user's language.
  String materialName(MaterialSpec spec) =>
      tr(plainWords ? plainWordsFor(spec)?.$1 ?? spec.name : spec.name);

  /// One line on what the calculator works out.
  String materialBlurb(MaterialSpec spec) =>
      tr(plainWords ? plainWordsFor(spec)?.$2 ?? spec.blurb : spec.blurb);

  String categoryLabel(MaterialCategory category) => tr(
    plainWords
        ? plainCategoryWords[category.name]?.$1 ?? category.label
        : category.label,
  );

  String categoryTagline(MaterialCategory category) => tr(
    plainWords
        ? plainCategoryWords[category.name]?.$2 ?? category.tagline
        : category.tagline,
  );
}

/// The everyday name and explanation of [spec], when it has them.
(String, String)? plainWordsFor(MaterialSpec spec) =>
    plainMaterialWords[spec.id];
