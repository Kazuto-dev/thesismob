// Filipino for structural calculators: footings, beams, lintels and paving. Kept apart from i18n_fil.dart so each part of the
// app keeps its own table; see [filipinoTables].
const filipinoStructure = <String, String>{
  // Forms
  'Plywood and lumber are reused from pour to pour, about 3 times on a house':
      'Ginagamit ulit ang plywood at kahoy sa bawat buhos, mga 3 beses sa '
      'isang bahay',
  '4 times': '4 beses',
  'Lap splice': 'Patong ng bakal sa dugtungan',
  'Floor beam forms stay up while the slab cures, so 2 uses is usual':
      'Nakatayo ang porma ng beam habang tumitigas ang slab, kaya karaniwang '
      '2 gamit',
  'Stair forms are cut to fit the steps, so 2 uses is usual':
      'Pinuputol ang porma ng hagdan ayon sa baitang, kaya karaniwang 2 gamit',
  'Edge to form': 'Gilid na popormahan',
  'Optional. Leave empty to form the whole perimeter':
      'Opsyonal. Iwanang blangko para sa buong paligid',
  'Edge forms': 'Porma sa gilid ng slab',
  'Edges not poured against a beam or wall need forms':
      'Kailangan ng porma ang gilid na hindi nakasandal sa beam o pader',
  'Edges not poured against a curb or wall need forms':
      'Kailangan ng porma ang gilid na hindi nakasandal sa gutter o pader',
  'Around the slab': 'Sa paligid ng slab',
  'None, poured against beams or walls': 'Wala, nakasandal sa beam o pader',
  'None, poured against curbs or walls': 'Wala, nakasandal sa gutter o pader',

  // Beams and tie beams
  'Beam': 'Beam',
  'Floor or roof beam': 'Beam ng sahig o bubong',
  'Tie beam at ground level': 'Tie beam sa lupa',
  'Slab on the beam': 'Slab sa ibabaw ng beam',
  'Side forms stop under the slab: outer beams carry it on one side, inner beams on both, roof beams on none':
      'Hanggang ilalim ng slab lang ang porma sa gilid: isang gilid sa '
      'labas na beam, dalawa sa loob, wala sa beam ng bubong',
  'One side': 'Isang gilid',
  'Slab thickness': 'Kapal ng slab',
  'Compacted gravel under the tie beam':
      'Siniksik na graba sa ilalim ng tie beam',
  'Working space': 'Luwag sa paghuhukay',
  'Room beside the beam to set the forms':
      'Luwag sa tabi ng beam para sa porma',
  '0.30 m each side': '0.30 m bawat gilid',
  '0.50 m each side': '0.50 m bawat gilid',

  // Wall footings
  'Wall Footings': 'Wall Footing',
  'Strip footings under walls, with bars, trench and backfill':
      'Tuloy-tuloy na footing sa ilalim ng pader, may bakal, hukay at tambak',
  'Wall footing length': 'Haba ng wall footing',
  'All runs of the same size, added up':
      'Pinagsamang haba ng lahat ng magkasinlaki',
  'Usually 0.45–0.80 m under a house wall':
      'Karaniwang 0.45–0.80 m sa ilalim ng pader ng bahay',
  'Usually 0.20–0.25 m': 'Karaniwang 0.20–0.25 m',
  'Excavation depth': 'Lalim ng hukay',
  'From the ground to the bottom, gravel bed included':
      'Mula lupa hanggang ilalim, kasama ang sapin na graba',
  'Cross bar size': 'Laki ng bakal na pahalang',
  'Cross bar spacing': 'Pagitan ng bakal na pahalang',
  'The main bars, across the width of the footing':
      'Ang main bar, pahalang sa lapad ng footing',
  'Lengthwise bars': 'Bakal na pahaba',
  'Follow the plans; 3 or 4 is usual under a house wall':
      'Sundin ang plano; karaniwang 3 o 4 sa ilalim ng pader ng bahay',
  '3 bars': '3 bakal',
  'Lengthwise bar size': 'Laki ng bakal na pahaba',
  'Wall on the footing': 'Pader sa ibabaw ng footing',
  'Its part below the ground takes the place of backfill':
      'Ang bahagi nito sa ilalim ng lupa ay hindi na tatambakan',
  'Compacted gravel under the footing':
      'Siniksik na graba sa ilalim ng footing',
  'Room beside the footing to set bars and lay the blocks':
      'Luwag sa tabi ng footing para sa bakal at hollow blocks',

  // Lintels, stiffeners and sills
  'Lintels and Stiffeners': 'Lintel at Stiffener',
  'Lintel beams, stiffener columns and sills in a block wall':
      'Lintel beam, stiffener column at sill sa pader na hollow blocks',
  'Walls of the same block size, added up':
      'Pinagsamang haba ng pader na magkasinlaki ang block',
  'From the slab or footing to the beam above':
      'Mula slab o footing hanggang beam sa itaas',
  'Doors': 'Pinto',
  'Optional. Openings with a lintel only':
      'Opsyonal. Butas na may lintel lamang',
  'Door opening width': 'Lapad ng butas ng pinto',
  'Windows': 'Bintana',
  'Optional. Openings with a lintel and a sill':
      'Opsyonal. Butas na may lintel at sill',
  'Window opening width': 'Lapad ng butas ng bintana',
  'Lintels, stiffeners and sills are as wide as the wall':
      'Kasinlapad ng pader ang lintel, stiffener at sill',
  'Stiffener columns': 'Stiffener column',
  'Usually one for about every 3 m of wall between columns':
      'Karaniwang isa bawat 3 m ng pader sa pagitan ng mga column',
  'Every 2.4 m': 'Bawat 2.4 m',
  'Every 3.0 m': 'Bawat 3.0 m',
  'Every 3.6 m': 'Bawat 3.6 m',
  'Lintel bearing': 'Patong ng lintel',
  'How far a lintel rests on the wall at each side of an opening':
      'Gaano kalayo nakapatong ang lintel sa pader sa bawat gilid ng butas',
  '15 cm each side': '15 cm bawat gilid',
  '20 cm each side': '20 cm bawat gilid',
  'Window sills': 'Sill ng bintana',
  'Concrete sill under each window': 'Konkretong sill sa ilalim ng bintana',
  'Bars per lintel and stiffener': 'Bakal bawat lintel at stiffener',
  'Usually 2 in a 4" wall and 4 in 6" and 8" walls; sills get 2':
      'Karaniwang 2 sa pader na 4" at 4 sa 6" at 8"; 2 sa sill',
  'Usual for the block': 'Karaniwan sa block',
  '2 bars': '2 bakal',

  // Pavement
  'Concrete Pavement': 'Konkretong Daanan',
  'Driveway, sidewalk or carport slab with base, joints and curing':
      'Driveway, bangketa o carport, may graba, joint at curing',
  'Pavement length': 'Haba ng daanan',
  'Pavement width': 'Lapad ng daanan',
  '100 mm for walks and carports, 150 mm where cars drive often':
      '100 mm sa daanan ng tao at carport, 150 mm kung madalas daanan ng '
      'sasakyan',
  'Gravel base': 'Sapin na graba',
  'Compacted gravel under the pavement':
      'Siniksik na graba sa ilalim ng daanan',
  'Reinforcement': 'Bakal',
  'Bars both ways': 'Bakal sa magkabilang direksyon',
  'Welded wire mesh': 'Welded wire mesh',
  'Follow the plans; 30 cm is usual where cars drive':
      'Sundin ang plano; karaniwang 30 cm kung dinadaanan ng sasakyan',
  'Control joints': 'Control joint',
  'Cut or tooled grooves across the slab, so it cracks along them':
      'Ukang hiwa sa slab para doon ito bumitak',
  'Usual for the thickness': 'Karaniwan sa kapal',
  'Every 1.5 m': 'Bawat 1.5 m',
  'Every 2 m': 'Bawat 2 m',
  'Every 3 m': 'Bawat 3 m',
  'Joint sealant': 'Sealant ng joint',
  'Polyurethane sealant': 'Polyurethane sealant',
  'None, tooled joints': 'Wala, hinulma lang ang joint',
  'Curing': 'Pagku-curing',
  'New concrete is kept moist for 7 days':
      'Pinapanatiling basa ang bagong konkreto nang 7 araw',
  'Curing compound': 'Curing compound',
  'Kept wet with water': 'Binabasa ng tubig',
};
