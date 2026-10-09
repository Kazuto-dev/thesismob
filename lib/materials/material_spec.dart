import 'package:flutter/foundation.dart';

/// The four groups shown on the home screen.
enum MaterialCategory {
  structural('Structural', 'Walls, panels and insulation'),
  architectural('Architectural', 'Paint, tiles, roofing and finishes'),
  electrical('Electrical', 'Lighting, wiring and devices'),
  plumbing('Plumbing', 'Pipes and fixtures');

  const MaterialCategory(this.label, this.tagline);

  final String label;
  final String tagline;

  static MaterialCategory? byId(String id) {
    for (final c in values) {
      if (c.name == id) return c;
    }
    return null;
  }
}

/// How a quantity is counted, with singular and plural labels.
enum QuantityUnit {
  pieces('pc', 'pcs'),
  blocks('block', 'blocks'),
  sheets('sheet', 'sheets'),
  rolls('roll', 'rolls'),
  gallons('gallon', 'gallons'),
  metres('m', 'm');

  const QuantityUnit(this.singular, this.plural);

  final String singular;
  final String plural;

  String labelFor(num quantity) => quantity == 1 ? singular : plural;

  static QuantityUnit byName(String name) =>
      values.firstWhere((u) => u.name == name, orElse: () => pieces);
}

/// A numeric input such as a dimension, a count or a price.
@immutable
class NumberField {
  const NumberField({
    required this.id,
    required this.label,
    this.unit,
    this.hint,
    this.max = 100000,
    this.integer = false,
    this.isPrice = false,
  });

  final String id;
  final String label;

  /// Suffix shown in the field, e.g. `m` or `sqm/L`.
  final String? unit;
  final String? hint;
  final double max;
  final bool integer;
  final bool isPrice;

  /// Returns the parsed value, or null when [raw] is not a valid entry.
  double? parse(String raw) =>
      validate(raw) == null ? double.parse(raw.trim()) : null;

  /// Returns an error message for [raw], or null when it is valid. Every
  /// field must be a finite number greater than zero and at most [max].
  String? validate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return 'Enter ${_article(label)}';
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) return 'Enter a number, like 2.5';
    if (integer && value != value.roundToDouble()) {
      return 'Enter a whole number';
    }
    if (value <= 0) return 'Must be more than 0';
    if (value > max) return 'Must be ${_formatLimit(max)} or less';
    return null;
  }

  static String _article(String label) {
    final lower = label.toLowerCase();
    return lower.startsWith('price') || lower.startsWith('number')
        ? 'the $lower'
        : 'a $lower';
  }

  static String _formatLimit(double max) {
    final whole = max.truncate();
    final digits = whole.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// One entry of a dropdown. [value] carries the number the calculation needs
/// (an area in m², a contingency fraction, a length in metres…).
@immutable
class ChoiceOption {
  const ChoiceOption(this.id, this.label, [this.value = 0]);

  final String id;
  final String label;
  final double value;
}

@immutable
class ChoiceField {
  const ChoiceField({
    required this.id,
    required this.label,
    required this.options,
    this.initial,
    this.helper,
    this.visibleWhen,
  });

  final String id;
  final String label;
  final List<ChoiceOption> options;

  /// Option preselected for the user. When null the user must pick one.
  final String? initial;
  final String? helper;

  /// Shows the field only when this returns true for the other selections.
  final bool Function(Map<String, String> selected)? visibleWhen;

  ChoiceOption? option(String? id) {
    for (final o in options) {
      if (o.id == id) return o;
    }
    return null;
  }

  bool isVisible(Map<String, String> selected) =>
      visibleWhen == null || visibleWhen!(selected);
}

/// A titled paragraph in the Definitions or Solution sheet. [formula] is
/// shown highlighted below the body.
@immutable
class InfoSection {
  const InfoSection(this.title, this.body, {this.formula});

  final String title;
  final String body;
  final String? formula;
}

/// Validated inputs handed to a calculation.
class CalcInput {
  const CalcInput(this.numbers, this.choices);

  final Map<String, double> numbers;
  final Map<String, ChoiceOption> choices;

  double operator [](String id) {
    final value = numbers[id];
    if (value == null) throw ArgumentError.value(id, 'id', 'missing number');
    return value;
  }

  ChoiceOption choice(String id) {
    final option = choices[id];
    if (option == null) throw ArgumentError.value(id, 'id', 'missing choice');
    return option;
  }
}

/// A labelled line in the result breakdown, e.g. "Contingency (5%)" / "+19".
@immutable
class ResultDetail {
  const ResultDetail(this.label, this.value);

  final String label;
  final String value;
}

/// The outcome of a calculation. [total] is rounded to the centavo.
@immutable
class CalcResult {
  CalcResult({
    required this.label,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    this.area,
    this.details = const [],
  }) : total = (quantity * unitPrice * 100).roundToDouble() / 100;

  /// Short description used in the summary, e.g. `CHB 4"`.
  final String label;
  final double quantity;
  final QuantityUnit unit;
  final double unitPrice;

  /// Covered area in m², when the material is measured by area.
  final double? area;
  final List<ResultDetail> details;
  final double total;
}

typedef Calculation = CalcResult Function(CalcInput input);

@immutable
class MaterialSpec {
  const MaterialSpec({
    required this.id,
    required this.name,
    required this.category,
    required this.image,
    required this.blurb,
    required this.numbers,
    required this.compute,
    this.choices = const [],
    this.definitions = const [],
    this.solution = const [],
    this.references = const [],
  });

  final String id;
  final String name;
  final MaterialCategory category;

  /// Asset path of the material icon.
  final String image;

  /// One line shown under the name in lists.
  final String blurb;
  final List<NumberField> numbers;
  final List<ChoiceField> choices;
  final Calculation compute;
  final List<InfoSection> definitions;
  final List<InfoSection> solution;
  final List<String> references;

  /// Dropdown selections a fresh form starts with.
  Map<String, String> get initialChoices => {
    for (final c in choices)
      if (c.initial != null) c.id: c.initial!,
  };

  /// The dropdowns that apply to the current [selected] options.
  List<ChoiceField> visibleChoices(Map<String, String> selected) => [
    for (final c in choices)
      if (c.isVisible(selected)) c,
  ];

  /// Runs [compute] with validated [numbers] and the [selected] option ids.
  /// Throws an [ArgumentError] when a visible dropdown has no valid choice.
  CalcResult calculate(
    Map<String, double> numbers,
    Map<String, String> selected,
  ) {
    final options = <String, ChoiceOption>{};
    for (final field in visibleChoices(selected)) {
      final option = field.option(selected[field.id]);
      if (option == null) {
        throw ArgumentError.value(
          selected[field.id],
          field.id,
          'Choose ${field.label}',
        );
      }
      options[field.id] = option;
    }
    return compute(CalcInput(numbers, options));
  }
}
