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
  metres('m', 'm'),
  boxes('box', 'boxes'),
  squareMetres('m²', 'm²'),
  pipes('pipe', 'pipes'),
  bulbs('bulb', 'bulbs');

  const QuantityUnit(this.singular, this.plural);

  final String singular;
  final String plural;

  String labelFor(num quantity) => quantity == 1 ? singular : plural;

  static QuantityUnit byName(String name) =>
      values.firstWhere((u) => u.name == name, orElse: () => pieces);
}

/// Shows a field only when this returns true for the selected options.
typedef VisibleWhen = bool Function(Map<String, String> selected);

/// A numeric input such as a dimension, a count or a price.
@immutable
class NumberField {
  const NumberField({
    required this.id,
    required this.label,
    this.unit,
    this.hint,
    this.initial,
    this.max = 100000,
    this.integer = false,
    this.isPrice = false,
    this.optional = false,
    this.visibleWhen,
  });

  final String id;
  final String label;

  /// Suffix shown in the field, e.g. `m` or `m²`.
  final String? unit;

  /// Helper text under the field.
  final String? hint;

  /// Value a fresh form starts with, such as the usual number of coats.
  final String? initial;
  final double max;
  final bool integer;
  final bool isPrice;

  /// Optional fields may be left empty or 0, which counts as 0.
  final bool optional;
  final VisibleWhen? visibleWhen;

  bool isVisible(Map<String, String> selected) =>
      visibleWhen == null || visibleWhen!(selected);

  /// Returns the parsed value, or null when [raw] is not a valid entry.
  double? parse(String raw) {
    if (validate(raw) != null) return null;
    final text = raw.trim();
    return text.isEmpty ? 0 : double.parse(text);
  }

  /// Returns an error message for [raw], or null when it is valid. Required
  /// fields must be a finite number greater than zero and at most [max].
  String? validate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return optional ? null : 'Enter ${_article(label)}';
    final value = double.tryParse(text);
    if (value == null || !value.isFinite) return 'Enter a number, like 2.5';
    if (integer && value != value.roundToDouble()) {
      return 'Enter a whole number';
    }
    if (value < 0 || (value == 0 && !optional)) return 'Must be more than 0';
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

/// One option of a choice. [value] carries the number the calculation
/// needs (an area in m², a waste fraction, a length in metres…).
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
    this.leading = false,
  });

  final String id;
  final String label;
  final List<ChoiceOption> options;

  /// Option preselected for the user. When null the user must pick one.
  final String? initial;
  final String? helper;
  final VisibleWhen? visibleWhen;

  /// Shown above the measurements because it changes which ones are asked.
  final bool leading;

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

  /// An optional number, 0 when it was left empty or is not shown.
  double optional(String id) => numbers[id] ?? 0;

  ChoiceOption choice(String id) {
    final option = choices[id];
    if (option == null) throw ArgumentError.value(id, 'id', 'missing choice');
    return option;
  }

  /// Whether the choice [id] is shown and set to [optionId].
  bool chose(String id, String optionId) => choices[id]?.id == optionId;
}

/// A labelled line in the result breakdown, e.g. "Waste (5%)" / "+19".
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
    this.companions = const [],
    this.note,
  }) : total = (quantity * unitPrice * 100).roundToDouble() / 100;

  /// Short description used in the summary, e.g. `CHB 4"`.
  final String label;
  final double quantity;
  final QuantityUnit unit;
  final double unitPrice;

  /// Covered area in m², when the material is measured by area.
  final double? area;

  /// How the quantity was worked out, step by step.
  final List<ResultDetail> details;

  /// Other materials the job needs, with quantities but no price.
  final List<ResultDetail> companions;

  /// A short remark shown under the breakdown.
  final String? note;
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
    this.keywords = const [],
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

  /// Other words people search for, including Filipino terms.
  final List<String> keywords;

  /// Choices a fresh form starts with.
  Map<String, String> get initialChoices => {
    for (final c in choices)
      if (c.initial != null) c.id: c.initial!,
  };

  /// The choices that apply to the current [selected] options.
  List<ChoiceField> visibleChoices(Map<String, String> selected) => [
    for (final c in choices)
      if (c.isVisible(selected)) c,
  ];

  /// The number fields that apply to the current [selected] options.
  List<NumberField> visibleNumbers(Map<String, String> selected) => [
    for (final f in numbers)
      if (f.isVisible(selected)) f,
  ];

  /// Whether [query] matches this material's name, blurb, category or
  /// keywords, ignoring case.
  bool matches(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return [
      name,
      blurb,
      category.label,
      ...keywords,
    ].any((text) => text.toLowerCase().contains(q));
  }

  /// Runs [compute] with validated [numbers] and the [selected] option ids.
  /// Throws an [ArgumentError] when a visible choice has no valid option or
  /// a visible required number is missing.
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
    final values = <String, double>{};
    for (final field in visibleNumbers(selected)) {
      final value = numbers[field.id];
      if (value == null && !field.optional) {
        throw ArgumentError.value(null, field.id, 'Enter ${field.label}');
      }
      if (value != null) values[field.id] = value;
    }
    return compute(CalcInput(values, options));
  }
}
