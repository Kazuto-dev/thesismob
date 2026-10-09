import 'calc_helpers.dart';
import 'definitions.dart';
import 'material_spec.dart';
import 'solutions.dart';

/// A dropdown that describes the item without changing the cost.
ChoiceField _descriptor(
  String id,
  String label,
  List<(String, String)> options,
) => ChoiceField(
  id: id,
  label: label,
  initial: notSpecified,
  options: [
    const ChoiceOption(notSpecified, 'Not specified'),
    for (final (oid, olabel) in options) ChoiceOption(oid, olabel),
  ],
);

MaterialSpec _fixture({
  required String id,
  required String name,
  required String summaryName,
  required MaterialCategory category,
  required String blurb,
  required String quantityLabel,
  List<ChoiceField> choices = const [],
}) => MaterialSpec(
  id: id,
  name: name,
  category: category,
  image: 'assets/images/materials/$id.png',
  blurb: blurb,
  numbers: [quantityField(quantityLabel), priceField('Price per piece')],
  choices: choices,
  compute: perPiece(summaryName, descriptors: [for (final c in choices) c.id]),
  definitions: materialDefinitions[id] ?? const [],
  solution: perPieceSolution(quantityLabel.replaceFirst('Number of ', '')),
  references: materialReferences[id] ?? const [],
);

final bulb = _fixture(
  id: 'bulb',
  name: 'Light Bulb',
  summaryName: 'Light bulb',
  category: MaterialCategory.electrical,
  blurb: 'Bulbs by type and wattage',
  quantityLabel: 'Number of bulbs',
  choices: [
    _descriptor('type', 'Bulb type', [
      ('incandescent', 'Incandescent'),
      ('halogen', 'Halogen'),
      ('cfl', 'CFL'),
      ('led', 'LED'),
    ]),
    _descriptor('watts', 'Wattage', [
      for (final w in [3, 5, 7, 9, 11, 13, 15, 18, 20, 25, 30, 40])
        ('$w', '$w W'),
    ]),
  ],
);

final lightSwitch = _fixture(
  id: 'switch',
  name: 'Switch',
  summaryName: 'Switch',
  category: MaterialCategory.electrical,
  blurb: 'Wall switches by type',
  quantityLabel: 'Number of switches',
  choices: [
    _descriptor('type', 'Switch type', [
      ('single', 'Single-pole'),
      ('double', 'Double-pole'),
      ('three_way', 'Three-way'),
    ]),
  ],
);

final junctionBox = _fixture(
  id: 'junction_box',
  name: 'Junction Box',
  summaryName: 'Junction box',
  category: MaterialCategory.electrical,
  blurb: 'Boxes that enclose wire connections',
  quantityLabel: 'Number of boxes',
);

final outlet = _fixture(
  id: 'outlet',
  name: 'Outlet',
  summaryName: 'Outlet',
  category: MaterialCategory.electrical,
  blurb: 'Convenience outlets by number of gangs',
  quantityLabel: 'Number of outlets',
  choices: [
    _descriptor('type', 'Outlet type', [
      ('1', '1 gang'),
      ('2', '2 gang'),
      ('3', '3 gang'),
    ]),
  ],
);

final wires = MaterialSpec(
  id: 'wires',
  name: 'Electrical Wire',
  category: MaterialCategory.electrical,
  image: 'assets/images/materials/wires.png',
  blurb: 'Wire by the metre',
  numbers: const [
    NumberField(id: 'quantity', label: 'Wire length', unit: 'm', max: 100000),
    NumberField(
      id: 'price',
      label: 'Price per metre',
      unit: '₱',
      isPrice: true,
      max: 1000000,
    ),
  ],
  choices: [
    _descriptor('type', 'Wire type', [
      ('solid', 'Solid'),
      ('stranded', 'Stranded'),
      ('twisted_pair', 'Twisted pair'),
    ]),
  ],
  compute: perPiece('Wire', descriptors: ['type'], unit: QuantityUnit.metres),
  definitions: materialDefinitions['wires']!,
  solution: materialSolutions['wires']!,
  references: materialReferences['wires'] ?? const [],
);

final utilityBox = _fixture(
  id: 'utility_box',
  name: 'Utility Box',
  summaryName: 'Utility box',
  category: MaterialCategory.electrical,
  blurb: 'Boxes for switches, outlets and breakers',
  quantityLabel: 'Number of boxes',
);

final pvc = _fixture(
  id: 'pvc',
  name: 'PVC Pipe',
  summaryName: 'PVC pipe',
  category: MaterialCategory.plumbing,
  blurb: 'Pipes by length and diameter',
  quantityLabel: 'Number of pipes',
  choices: [
    _descriptor('diameter', 'Diameter', [
      ('1/2', '½"'),
      ('3/4', '¾"'),
      ('1', '1"'),
      ('1-1/4', '1¼"'),
      ('1-1/2', '1½"'),
    ]),
    _descriptor('length', 'Pipe length', [('5', '5 ft'), ('10', '10 ft')]),
  ],
);

final sink = _fixture(
  id: 'sink',
  name: 'Sink',
  summaryName: 'Sink',
  category: MaterialCategory.plumbing,
  blurb: 'Kitchen and bathroom sinks',
  quantityLabel: 'Number of sinks',
  choices: [
    _descriptor('type', 'Sink type', [
      ('wall', 'Wall-mounted'),
      ('vessel', 'Vessel'),
      ('drop_in', 'Drop-in'),
      ('undermount', 'Undermount'),
      ('semi_recessed', 'Semi-recessed'),
      ('pedestal', 'Pedestal'),
    ]),
  ],
);

final toilet = _fixture(
  id: 'toilet',
  name: 'Toilet',
  summaryName: 'Toilet',
  category: MaterialCategory.plumbing,
  blurb: 'Water closets by flush type',
  quantityLabel: 'Number of toilets',
  choices: [
    _descriptor('type', 'Toilet type', [
      ('gravity', 'Gravity-flush'),
      ('pressure', 'Pressure-assisted'),
      ('one_piece', 'One-piece'),
      ('two_piece', 'Two-piece'),
    ]),
  ],
);

final faucet = _fixture(
  id: 'faucet',
  name: 'Faucet',
  summaryName: 'Faucet',
  category: MaterialCategory.plumbing,
  blurb: 'Faucets by handle and spout type',
  quantityLabel: 'Number of faucets',
  choices: [
    _descriptor('type', 'Faucet type', [
      ('single', 'Single-handle'),
      ('double', 'Double-handle'),
      ('bridge', 'Bridge'),
      ('gooseneck', 'Gooseneck'),
      ('pull_out', 'Pull-out spout'),
      ('pull_down', 'Pull-down spout'),
    ]),
  ],
);

final shower = _fixture(
  id: 'shower',
  name: 'Shower',
  summaryName: 'Shower',
  category: MaterialCategory.plumbing,
  blurb: 'Shower sets by type',
  quantityLabel: 'Number of showers',
  choices: [
    _descriptor('type', 'Shower type', [
      ('concealed', 'Concealed'),
      ('exposed', 'Exposed'),
      ('two_way', 'Two-way'),
      ('mixer', 'Mixer'),
    ]),
  ],
);
