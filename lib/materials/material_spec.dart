import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart' show IconData;

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
  bulbs('bulb', 'bulbs'),
  bags('bag', 'bags'),
  cubicMetres('m³', 'm³'),
  kilograms('kg', 'kg'),
  sets('set', 'sets'),
  lengths('length', 'lengths'),
  litres('L', 'L'),
  pails('pail', 'pails');

  const QuantityUnit(this.singular, this.plural);

  final String singular;
  final String plural;

  String labelFor(num quantity) => quantity == 1 ? singular : plural;

  static QuantityUnit byName(String name) =>
      values.firstWhere((u) => u.name == name, orElse: () => pieces);
}

/// Shows a field only when this returns true for the selected options.
typedef VisibleWhen = bool Function(Map<String, String> selected);

/// Feet in a metre.
const feetPerMetre = 1 / 0.3048;

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
    this.typical,
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

  /// The values usually entered, in [unit]. A value well outside them is
  /// probably in the wrong unit, such as centimetres typed into a field in
  /// metres, and the form asks about it.
  final ({double min, double max})? typical;

  /// This field in feet instead of metres: lengths become `ft` and areas
  /// `ft²`, with [max], [typical] and the measurements in [hint]
  /// converted. Other fields are returned as they are.
  NumberField inFeet() {
    final factor = switch (unit) {
      'm' => feetPerMetre,
      'm²' => feetPerMetre * feetPerMetre,
      _ => null,
    };
    if (factor == null) return this;
    final t = typical;
    return NumberField(
      id: id,
      label: label,
      unit: unit == 'm' ? 'ft' : 'ft²',
      hint: hint == null ? null : _hintInFeet(hint!),
      initial: initial == null
          ? null
          : _trim((double.parse(initial!) * factor).toStringAsFixed(2)),
      max: (max * factor).roundToDouble(),
      integer: integer,
      isPrice: isPrice,
      optional: optional,
      visibleWhen: visibleWhen,
      typical: t == null ? null : (min: t.min * factor, max: t.max * factor),
    );
  }

  /// Converts the measurements in metres in a hint, e.g. "Usually
  /// 0.25–0.30 m", to feet.
  static String _hintInFeet(String hint) => hint.replaceAllMapped(
    RegExp(r'(\d+(?:\.\d+)?)(?:–(\d+(?:\.\d+)?))? m\b'),
    (m) {
      String ft(String metres) =>
          _trim((double.parse(metres) * feetPerMetre).toStringAsFixed(1));
      return m[2] == null ? '${ft(m[1]!)} ft' : '${ft(m[1]!)}–${ft(m[2]!)} ft';
    },
  );

  static String _trim(String number) => number.contains('.')
      ? number.replaceFirst(RegExp(r'\.?0+$'), '')
      : number;

  /// A likelier value when [value] is far above what is [typical], read as
  /// a smaller unit by mistake: centimetres or millimetres in a field in
  /// metres, inches in one in feet. Returns null when [value] looks right
  /// or no smaller unit makes sense of it.
  ({double value, String unit})? likelyMeant(double value) {
    final t = typical;
    if (t == null || value <= t.max) return null;
    final smaller = switch (unit) {
      'm' => const [(100.0, 'cm'), (1000.0, 'mm')],
      'ft' => const [(12.0, 'in')],
      _ => const <(double, String)>[],
    };
    for (final (divisor, name) in smaller) {
      final meant = value / divisor;
      if (meant >= t.min && meant <= t.max) return (value: meant, unit: name);
    }
    return null;
  }

  /// Whether [value] is well above what is [typical].
  bool isUnusual(double value) => typical != null && value > typical!.max;

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

/// Another material the job needs, such as cement for laying blocks. It is
/// bought from the price book entry [itemKey]; [quantity] is in that
/// item's unit and already rounded to what can be bought.
@immutable
class Companion {
  const Companion(
    this.itemKey,
    this.quantity, {
    this.label,
    this.unitPrice,
    this.work,
  });

  final String itemKey;
  final double quantity;

  /// The work item this material goes into, by [Work] key, when it is not
  /// the calculation's main work. Bars and tie wire go to the rebar work
  /// and form materials to the formwork by themselves.
  final String? work;

  /// Replaces the item's name, e.g. "Cement, laying and plaster".
  final String? label;

  /// A fixed price that overrides the price book, for allowances worked
  /// out from the main cost.
  final double? unitPrice;
}

/// How much of a work item a calculation measured, such as 2.4 m³ of
/// footing concrete or 310 kg of reinforcing steel, in the work item's
/// unit. [effort] multiplies the crew time, e.g. by the number of coats.
@immutable
class WorkQuantity {
  const WorkQuantity(this.key, this.quantity, {this.effort = 1});

  /// A [Work] key from `work_items.dart`.
  final String key;
  final double quantity;
  final double effort;
}

/// Points a calculator's price field at a price book entry. The suggested
/// price is the entry's price × [factor], e.g. a per-foot price × 8 ft.
@immutable
class PriceRef {
  const PriceRef(this.itemKey, [this.factor = 1]);

  final String itemKey;
  final double factor;
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
    this.itemKey,
    this.works = const [],
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

  /// Other materials the job needs, priced from the price book.
  final List<Companion> companions;

  /// Price book entry of the main material, so the same material from
  /// several estimates can be bought as one line.
  final String? itemKey;

  /// A short remark shown under the breakdown.
  final String? note;
  final double total;

  /// The work this measures for a bill of quantities, main work first:
  /// the main material and companions without a work of their own go into
  /// it.
  final List<WorkQuantity> works;
}

typedef Calculation = CalcResult Function(CalcInput input);

@immutable
class MaterialSpec {
  const MaterialSpec({
    required this.id,
    required this.name,
    required this.category,
    this.image,
    this.icon,
    required this.blurb,
    required this.numbers,
    required this.compute,
    this.choices = const [],
    this.definitions = const [],
    this.solution = const [],
    this.references = const [],
    this.keywords = const [],
    this.priceRef,
  }) : assert(image != null || icon != null);

  final String id;
  final String name;
  final MaterialCategory category;

  /// Asset path of the material's drawn icon.
  final String? image;

  /// A Material icon, for calculators without a drawn one.
  final IconData? icon;

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

  /// The price book entry that suggests a price for the main material,
  /// for the selected options.
  final PriceRef? Function(Map<String, String> selected)? priceRef;

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
