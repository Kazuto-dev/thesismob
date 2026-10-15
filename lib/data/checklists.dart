/// A list of the calculators a kind of job usually needs, so nothing is
/// forgotten.
typedef ChecklistTemplate = ({
  String id,
  String name,
  String description,
  List<String> materials,
});

/// A one- or two-storey house, from the footings to the fixtures, in
/// building order.
const houseChecklist = (
  id: 'house',
  name: 'House',
  description: 'From the footings to the fixtures, in building order',
  materials: [
    'footing',
    'column',
    'beam',
    'slab',
    'chb',
    'roof',
    'insulation',
    'ceiling',
    'doors',
    'windows',
    'tiles',
    'paint',
    'rough_in',
    'bulb',
    'switch',
    'outlet',
    'pvc',
    'toilet',
    'sink',
    'faucet',
    'shower',
    'water_tank',
    'septic_tank',
  ],
);

/// Refreshing rooms that are already built.
const renovationChecklist = (
  id: 'renovation',
  name: 'Renovation',
  description: 'New finishes, fixtures and wiring for existing rooms',
  materials: [
    'ceiling',
    'tiles',
    'paint',
    'doors',
    'windows',
    'bulb',
    'switch',
    'outlet',
    'wires',
    'toilet',
    'sink',
    'faucet',
    'shower',
  ],
);

const checklistTemplates = [houseChecklist, renovationChecklist];
