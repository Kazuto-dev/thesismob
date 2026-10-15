import 'package:flutter/foundation.dart';

import '../materials/catalog.dart';
import '../materials/material_spec.dart';
import '../materials/work_items.dart';
import 'project.dart';
import 'unit_prices.dart';

/// A finish level for a quick budget by floor area.
enum FinishLevel {
  economy('Economy', 'Plain finishes, local fixtures', 28000, 36000),
  standard('Standard', 'Tiles throughout, mid-range fixtures', 36000, 50000),
  premium('Premium', 'Stone, engineered wood, imported fixtures', 50000, 75000);

  const FinishLevel(this.label, this.description, this.low, this.high);

  final String label;
  final String description;

  /// Cost per m² of floor area, a contractor's price with VAT, in Metro
  /// Manila in late 2026.
  final double low;
  final double high;
}

/// How a house's cost usually splits by trade.
const parametricSplit = <(MaterialCategory?, double)>[
  (MaterialCategory.structural, 0.45),
  (MaterialCategory.architectural, 0.33),
  (MaterialCategory.electrical, 0.08),
  (MaterialCategory.plumbing, 0.09),
  (null, 0.05),
];

/// A quick budget for a house of [area] m² over [storeys] floors: a low
/// and a high figure. Upper floors add stairs and suspended slabs.
({double low, double high}) parametricBudget(
  double area,
  int storeys,
  FinishLevel level,
) {
  final factor = switch (storeys) {
    <= 1 => 1.0,
    2 => 1.05,
    _ => 1.10,
  };
  return (low: area * level.low * factor, high: area * level.high * factor);
}

/// How a check came out.
enum CheckLevel { ok, info, warning }

/// One check of a project's numbers against usual ranges.
@immutable
class ProjectCheck {
  const ProjectCheck(this.level, this.title, this.detail);

  final CheckLevel level;
  final String title;
  final String detail;
}

String _n(double v) =>
    v >= 100 ? v.round().toString() : ((v * 10).round() / 10).toString();

String _peso(double v) {
  final whole = v.round().toString();
  final b = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) b.write(',');
    b.write(whole[i]);
  }
  return '₱$b';
}

/// Checks a project's numbers against what is usual for houses, to catch
/// a wrong input before the estimate goes out: cost per m², steel per m³
/// of concrete, formwork, the labour share, missing prices and old
/// prices.
List<ProjectCheck> checkProject(Project project, {DateTime? today}) {
  final checks = <ProjectCheck>[];
  if (project.items.isEmpty) return checks;
  final b = project.breakdown;
  final now = today ?? DateTime.now();

  // Cost per m² of floor area.
  final area = project.floorArea;
  if (area != null && area > 0) {
    final perM2 = b.total / area;
    final range = parametricBudget(area, 1, FinishLevel.standard);
    final low = FinishLevel.economy.low * 0.5;
    final high = FinishLevel.premium.high * 1.5;
    checks.add(
      ProjectCheck(
        perM2 < low || perM2 > high ? CheckLevel.warning : CheckLevel.ok,
        'Cost per m² of floor area: ${_peso(perM2)}',
        perM2 < low
            ? 'Far below the usual ${_peso(FinishLevel.economy.low)} or more '
                  'for a finished house. Is the whole house estimated?'
            : perM2 > high
            ? 'Far above the usual. Check the floor area and the biggest items.'
            : 'A finished standard house usually costs '
                  '${_peso(range.low / area)}–${_peso(range.high / area)} a '
                  'm²; finishes and the site move this a lot.',
      ),
    );
  }

  // Steel and formwork per m³ of concrete.
  var concrete = 0.0;
  var steel = 0.0;
  var forms = 0.0;
  for (final e in project.items) {
    for (final w in worksOf(e)) {
      if (w.key.startsWith('concrete_') || w.key == 'stairs_concrete') {
        concrete += w.quantity;
      } else if (w.key == Work.rebar &&
          materialById(e.materialId)?.category == MaterialCategory.structural &&
          !e.materialId.startsWith('chb')) {
        steel += w.quantity;
      } else if (w.key == Work.formwork) {
        forms += w.quantity;
      }
    }
  }
  if (concrete > 0) {
    final ratio = steel / concrete;
    checks.add(
      ProjectCheck(
        ratio < 40 || ratio > 250 ? CheckLevel.warning : CheckLevel.ok,
        'Reinforcing steel: ${_n(ratio)} kg per m³ of concrete',
        ratio < 40
            ? 'Low for reinforced concrete, usually 80–150 kg/m³ in houses. '
                  'Are bars missing from some items?'
            : ratio > 250
            ? 'High; usually 80–150 kg/m³ in houses. Check the bar sizes and '
                  'spacing.'
            : 'Within the usual 40–250 kg/m³ (80–150 in most houses).',
      ),
    );
    if (forms > 0) {
      final ratio = forms / concrete;
      checks.add(
        ProjectCheck(
          ratio > 15 ? CheckLevel.warning : CheckLevel.ok,
          'Formwork: ${_n(ratio)} m² per m³ of concrete',
          ratio > 15
              ? 'More than usual (about 4–12 m²/m³). Check the member sizes.'
              : 'Within the usual range for footings, columns, beams and '
                    'slabs.',
        ),
      );
    }
  }

  // Labour against materials.
  if (b.materials > 0) {
    final share = b.labour / b.materials * 100;
    checks.add(
      ProjectCheck(
        share < 15 || share > 90 ? CheckLevel.warning : CheckLevel.ok,
        'Labour is ${_n(share)}% of materials',
        share < 15 || share > 90
            ? 'Houses usually run 30–60%. Check the crew productivity and '
                  'daily rates.'
            : 'Houses usually run 30–60%.',
      ),
    );
  }

  // Lines without a price.
  final unpriced = <String>{
    for (final e in project.items) ...[
      if (e.unitPrice <= 0) e.label,
      for (final l in e.companions)
        if (l.unitPrice <= 0) l.label,
    ],
  };
  if (unpriced.isNotEmpty) {
    checks.add(
      ProjectCheck(
        CheckLevel.warning,
        '${unpriced.length} material${unpriced.length == 1 ? ' has' : 's have'} '
            'no price',
        '${unpriced.take(3).join(', ')}${unpriced.length > 3 ? '…' : ''}. '
            'Set prices under To buy.',
      ),
    );
  }

  // Old prices.
  final oldest = project.items
      .map((e) => e.createdAt)
      .where((d) => d.year > 2000)
      .fold<DateTime?>(null, (a, d) => a == null || d.isBefore(a) ? d : a);
  if (oldest != null) {
    final months = (now.difference(oldest).inDays / 30.4).floor();
    if (months >= 6) {
      checks.add(
        ProjectCheck(
          CheckLevel.warning,
          'Some prices are $months months old',
          'Material prices change. Update the prices under To buy, or add '
              'a price escalation in the budget.',
        ),
      );
    }
  }

  // Scope that usually goes together.
  final materials = {for (final e in project.items) e.materialId};
  bool has(String id) => materials.contains(id);
  final structuralConcrete =
      has('slab') || has('footing') || has('column') || has('beam');
  if (structuralConcrete && !has('chb')) {
    checks.add(
      const ProjectCheck(
        CheckLevel.info,
        'Concrete but no walls',
        'Most houses also need CHB walls. Add them if they are part of '
            'the job.',
      ),
    );
  }
  if (has('chb') && !has('paint')) {
    checks.add(
      const ProjectCheck(
        CheckLevel.info,
        'Walls but no paint',
        'Plastered walls are usually painted. Add paint if it is part of the '
            'job.',
      ),
    );
  }
  if ((has('chb') || structuralConcrete) &&
      !project.items.any(
        (e) =>
            materialById(e.materialId)?.category == MaterialCategory.electrical,
      )) {
    checks.add(
      const ProjectCheck(
        CheckLevel.info,
        'No electrical work',
        'A house needs wiring, outlets and lights. Add the electrical '
            'rough-in if it is part of the job.',
      ),
    );
  }
  return checks;
}
