import 'architectural.dart';
import 'concrete.dart';
import 'fixtures.dart';
import 'interiors.dart';
import 'material_spec.dart';
import 'openings.dart';
import 'services.dart';
import 'sitework.dart';
import 'structural.dart';
import 'utilities.dart';

/// Every calculator in the app, in the order shown in each category.
final List<MaterialSpec> allMaterials = [
  chb,
  slab,
  footing,
  column,
  beam,
  plywood,
  ceiling,
  insulation,
  paint,
  tiles,
  roof,
  doors,
  windows,
  carpet,
  wallpaper,
  bulb,
  lightSwitch,
  junctionBox,
  outlet,
  wires,
  utilityBox,
  roughIn,
  pvc,
  sink,
  toilet,
  faucet,
  shower,
  waterTank,
  septicTank,
  ...siteworkMaterials,
  ...interiorsMaterials,
  ...utilitiesMaterials,
];

final Map<String, MaterialSpec> _byId = {for (final m in allMaterials) m.id: m};

MaterialSpec? materialById(String id) => _byId[id];

List<MaterialSpec> materialsIn(MaterialCategory category) => [
  for (final m in allMaterials)
    if (m.category == category) m,
];
