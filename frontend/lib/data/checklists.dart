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
    'wall_footing',
    'column',
    'beam',
    'slab',
    'chb',
    'lintel',
    'fence',
    'roof',
    'flashing',
    'fascia',
    'soffit',
    'insulation',
    'ceiling',
    'doors',
    'windows',
    'gate',
    'tiles',
    'paint',
    'rough_in',
    'service_entrance',
    'bulb',
    'switch',
    'outlet',
    'pvc',
    'water_heater',
    'toilet',
    'sink',
    'faucet',
    'shower',
    'bath_accessories',
    'water_tank',
    'septic_tank',
    'pavement',
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
