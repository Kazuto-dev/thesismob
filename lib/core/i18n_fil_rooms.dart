// Filipino for the room schedule. Kept apart from i18n_fil.dart so each part of the
// app keeps its own table; see [filipinoTables].
const filipinoRooms = <String, String>{
  // Rooms screen and project card.
  'Rooms': 'Mga kuwarto',
  'Room schedule': 'Listahan ng mga kuwarto',
  'Enter rooms': 'Ilagay ang mga kuwarto',
  'Add a room': 'Magdagdag ng kuwarto',
  'Open rooms': 'Buksan ang mga kuwarto',
  '1 room': '1 kuwarto',
  '{n} rooms': '{n} kuwarto',
  'Finishes up to date': 'Bago ang mga finish',
  'Finishes need updating': 'Kailangang i-update ang mga finish',
  'Update finishes': 'I-update ang mga finish',
  'Update finishes from rooms': 'I-update ang finish mula sa mga kuwarto',
  'Back to the project': 'Bumalik sa proyekto',
  'Project not found': 'Hindi makita ang proyekto',
  'It may have been deleted.': 'Baka nabura na ito.',
  'Enter each room of {project} once. Rooms on the same level that share a finish become one estimate, made with that finish\'s calculator.':
      'Ilagay nang isang beses ang bawat kuwarto ng {project}. Ang mga '
      'kuwarto sa iisang palapag na pareho ang finish ay nagiging isang '
      'estimate, gawa sa calculator ng finish na iyon.',
  'No rooms yet. Add the first one: its size, doors and windows, and the finishes of its floor, walls and ceiling.':
      'Wala pang kuwarto. Idagdag ang una: ang sukat, mga pinto at bintana, '
      'at ang finish ng sahig, pader at kisame.',
  'No level': 'Walang palapag',
  'Walls, less doors and windows': 'Pader, bawas ang pinto at bintana',
  'Ceilings': 'Mga kisame',
  'Add rooms, then make their finish estimates here.':
      'Magdagdag ng mga kuwarto, saka gawin dito ang estimate ng finish.',
  'The {n} finish estimates match the rooms.':
      'Tugma sa mga kuwarto ang {n} estimate ng finish.',
  'The rooms have no finish estimates yet.':
      'Wala pang estimate ng finish ang mga kuwarto.',
  'The rooms changed since the finishes were last updated.':
      'Nagbago ang mga kuwarto mula nang huling i-update ang mga finish.',
  'Your own estimates are never changed. In a finish estimate, the measurements come from the rooms; options and prices you set in its calculator are kept.':
      'Hindi kailanman binabago ang sarili mong mga estimate. Sa estimate ng '
      'finish, galing sa mga kuwarto ang mga sukat; nananatili ang mga '
      'pinili at presyong itinakda mo sa calculator nito.',
  'Updated the finishes: {n} estimates from the rooms.':
      'Na-update ang mga finish: {n} estimate mula sa mga kuwarto.',
  'Some finishes were left out': 'May mga finish na hindi naisama',
  'OK': 'OK',
  '{name} (copy)': '{name} (kopya)',
  'Deleted {name}.': 'Binura ang {name}.',
  'Actions for {name}': 'Mga gagawin sa {name}',
  'Unnamed room': 'Kuwartong walang pangalan',
  '{height} high': '{height} ang taas',
  'Wall length taken as a square room':
      'Haba ng pader kinuha na parang parisukat na kuwarto',
  'Floor: tiles {size}': 'Sahig: tiles {size}',
  'Walls: paint': 'Pader: pintura',
  'Walls: tiles {size}, full height': 'Pader: tiles {size}, hanggang kisame',
  'Walls: tiles {size} to {height}, paint above':
      'Pader: tiles {size} hanggang {height}, pintura sa itaas',
  'Ceiling: paint': 'Kisame: pintura',
  'painted': 'may pintura',
  '{lights} lights, {outlets} outlets': '{lights} ilaw, {outlets} outlet',
  'Made from the room schedule. Its measurements are replaced when you update finishes from rooms; options and prices you set in the calculator are kept.':
      'Gawa mula sa listahan ng mga kuwarto. Napapalitan ang mga sukat nito '
      'kapag in-update mo ang finish mula sa mga kuwarto; nananatili ang mga '
      'pinili at presyong itinakda mo sa calculator.',

  // Room editor.
  'New room': 'Bagong kuwarto',
  'Edit room': 'Baguhin ang kuwarto',
  'Room name': 'Pangalan ng kuwarto',
  'Living room, Bedroom 1, T&B': 'Sala, Kuwarto 1, CR',
  'Level': 'Palapag',
  'Rooms on the same level share estimates':
      'Iisa ang estimate ng mga kuwarto sa iisang palapag',
  'Size': 'Sukat',
  'Rectangle': 'Parihaba',
  'Other shape': 'Ibang hugis',
  'Length': 'Haba',
  'Width': 'Lapad',
  'Height': 'Taas',
  'Sill': 'Pasimano',
  'How many': 'Ilan',
  'Round the room. Empty: taken as a square':
      'Paikot sa kuwarto. Kung walang laman: parang parisukat',
  'Ceiling height': 'Taas ng kisame',
  'Floor to ceiling': 'Mula sahig hanggang kisame',
  'Left out of the wall finishes. Enter a door between two rooms in both.':
      'Ibinabawas sa finish ng pader. Ilagay sa dalawang kuwarto ang pintong '
      'nasa pagitan nila.',
  'Window': 'Bintana',
  'Remove {name}': 'Alisin ang {name}',
  'Add a door': 'Magdagdag ng pinto',
  'Add a window': 'Magdagdag ng bintana',
  'Floor': 'Sahig',
  'Floor finish': 'Finish ng sahig',
  'Skirting': 'Skirting',
  'Not needed below wall tiles': 'Hindi kailangan sa ilalim ng wall tiles',
  '10 cm strips cut from the floor tiles':
      'Pirasong 10 cm na hiniwa mula sa floor tiles',
  'Trims round the walls': 'Trim paikot sa mga pader',
  'Walls': 'Pader',
  'Wall finish': 'Finish ng pader',
  'Tile height': 'Taas ng tiles',
  'At the ceiling height or more: full height':
      'Kasintaas ng kisame o higit pa: buong taas',
  'Ceiling boards': 'Board ng kisame',
  'Paint the ceiling': 'Pinturahan ang kisame',
  'The slab or roof underside': 'Ang ilalim ng slab o bubong',
  'The boards': 'Ang mga board',
  'Light points': 'Mga ilaw',
  'Outlets': 'Mga outlet',
  'floor': 'sahig',
  'walls': 'pader',
  'skirting': 'skirting',
  'Give the room a name': 'Bigyan ng pangalan ang kuwarto',
  'Enter the length': 'Ilagay ang haba',
  'Enter the width': 'Ilagay ang lapad',
  'Enter the floor area': 'Ilagay ang sukat ng sahig',
  'Enter the ceiling height': 'Ilagay ang taas ng kisame',
  'The doors and windows are larger than the walls':
      'Mas malaki ang mga pinto at bintana kaysa sa mga pader',

  // Finishes.
  'Tiles': 'Tiles',
  'SPC or vinyl planks': 'SPC o vinyl planks',
  'Laminated wood planks': 'Laminated na kahoy na planks',
  'Cement topping': 'Cement topping',
  'Tiles, paint above': 'Tiles, pintura sa itaas',
  'No boards': 'Walang board',
  'Fiber cement board': 'Fiber cement board',
  'Gypsum board': 'Gypsum board',
};
