import 'package:thesismob/data/contract.dart';
import 'package:thesismob/data/estimate.dart';
import 'package:thesismob/data/project.dart';
import 'package:thesismob/materials/catalog.dart';

/// An estimate from calculator [id] with [inputs] and the calculator's
/// default choices, changed by [choices].
Estimate calculated(
  String id,
  Map<String, double> inputs, [
  Map<String, String> choices = const {},
]) {
  final spec = materialById(id)!;
  final all = {...spec.initialChoices, ...choices};
  return Estimate.fromResult(
    materialId: id,
    result: spec.calculate(inputs, all),
    inputs: inputs,
    choices: all,
  );
}

/// A two-storey house of about 140 m² (7 × 10 m on each floor), measured
/// the way an estimator would from its plans: footings to fixtures, every
/// trade, with a contractor's markups and monthly general requirements.
Project sampleHouse({ContractData contract = const ContractData()}) {
  final direct = 3500000.0;
  return Project.create('Two-storey house').copyWith(
    floorArea: 140,
    costs: CostSettings.contractor.copyWith(
      general: suggestGeneralRequirements(direct),
      monthly: suggestMonthlyRequirements(direct),
    ),
    contract: contract,
    items: [
      // Earthworks: 15 column footing pits and the wall footing trench.
      calculated(
        'earthworks',
        {
          'count': 15,
          'length': 1.5,
          'width': 1.5,
          'depth': 1.5,
          'structure': 12,
          'price': 450,
        },
        {'space': '0.5'},
      ),
      calculated('earthworks', {
        'count': 1,
        'length': 60,
        'width': 0.6,
        'depth': 0.8,
        'structure': 9,
        'price': 450,
      }),
      calculated('footing', {
        'count': 15,
        'length': 1.5,
        'width': 1.5,
        'thickness': 0.3,
        'price': 255,
      }),
      calculated('column', {
        'count': 15,
        'width': 0.3,
        'depth': 0.3,
        'height': 4.5,
        'price': 255,
      }),
      calculated('column', {
        'count': 15,
        'width': 0.25,
        'depth': 0.25,
        'height': 3,
        'price': 255,
      }),
      calculated('beam', {
        'count': 22,
        'width': 0.25,
        'depth': 0.4,
        'length': 4,
        'price': 255,
      }),
      calculated('beam', {
        'count': 22,
        'width': 0.2,
        'depth': 0.3,
        'length': 4,
        'price': 255,
      }),
      calculated('slab', {
        'length': 10,
        'width': 7,
        'thickness': 0.1,
        'price': 255,
      }),
      calculated(
        'slab',
        {'length': 10, 'width': 7, 'thickness': 0.125, 'price': 255},
        {'type': 'suspended'},
      ),
      calculated('stairs', {
        'width': 1,
        'height': 3,
        'landing': 1,
        'price': 255,
      }),
      calculated(
        'chb',
        {'length': 68, 'height': 3, 'openings': 24, 'price': 22},
        {'size': '6'},
      ),
      calculated('chb', {
        'length': 40,
        'height': 3,
        'openings': 14,
        'price': 17,
      }),
      calculated(
        'roof',
        {
          'eave': 11,
          'width': 8,
          'rafter': 4.6,
          'price': 1200,
          'priceMetre': 450,
        },
        {'type': 'longspan', 'purlins': 'yes', 'gutter': 'eaves'},
      ),
      calculated('insulation', {'eave': 11, 'rafter': 4.6, 'price': 3500}),
      calculated('ceiling', {'length': 14, 'width': 10, 'price': 450}),
      calculated('doors', {'quantity': 8, 'price': 9500}),
      calculated('windows', {
        'width': 1.2,
        'height': 1.2,
        'quantity': 12,
        'price': 4500,
      }),
      calculated(
        'tiles',
        {
          'length': 14,
          'width': 10,
          'skirting': 90,
          'price': 95,
          'boxPrice': 380,
        },
        {'size': '60x60'},
      ),
      calculated('paint', {
        'length': 150,
        'height': 3,
        'openings': 38,
        'price': 750,
      }),
      calculated(
        'rough_in',
        {
          'lights': 20,
          'outlets': 24,
          'switches': 12,
          'aircons': 3,
          'homeRun': 12,
          'price': 6500,
        },
        {'storeys': '2'},
      ),
      calculated(
        'bulb',
        {'length': 1, 'width': 1, 'quantity': 20, 'price': 180},
        {'mode': 'count'},
      ),
      calculated('switch', {'quantity': 12, 'price': 120}),
      calculated(
        'outlet',
        {'length': 1, 'width': 1, 'quantity': 24, 'price': 150},
        {'mode': 'count'},
      ),
      calculated('pvc', {'run': 60, 'price': 160}),
      calculated('pvc', {'run': 40, 'price': 420}, {'diameter': '3'}),
      calculated('toilet', {'quantity': 3, 'price': 6500, 'piecePrice': 0}),
      calculated('sink', {'quantity': 3, 'price': 3500, 'piecePrice': 0}),
      calculated('faucet', {'quantity': 6, 'price': 650}),
      calculated('shower', {'quantity': 2, 'price': 2500}),
      calculated('water_tank', {'persons': 5, 'price': 9000}),
      calculated('septic_tank', {
        'bedrooms': 3,
        'persons': 5,
        'price': 17,
        'tankPrice': 0,
      }),
    ],
  );
}
