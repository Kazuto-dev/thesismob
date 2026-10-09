import 'architectural.dart';
import 'fixtures.dart';
import 'material_spec.dart';
import 'structural.dart';

/// Every calculator in the app, in the order shown in each category.
final List<MaterialSpec> allMaterials = [
  chb,
  plywood,
  insulation,
  paint,
  tiles,
  roof,
  carpet,
  wallpaper,
  bulb,
  lightSwitch,
  junctionBox,
  outlet,
  wires,
  utilityBox,
  pvc,
  sink,
  toilet,
  faucet,
  shower,
];

final Map<String, MaterialSpec> _byId = {for (final m in allMaterials) m.id: m};

MaterialSpec? materialById(String id) => _byId[id];

List<MaterialSpec> materialsIn(MaterialCategory category) => [
  for (final m in allMaterials)
    if (m.category == category) m,
];
