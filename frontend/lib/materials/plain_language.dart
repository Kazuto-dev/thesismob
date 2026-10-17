/// Everyday words for each calculator, for people new to construction: the
/// job it helps with and one line on what it works out. Keyed by calculator
/// id; experienced users see the trade names instead.
const plainMaterialWords = <String, (String name, String explanation)>{
  'chb': (
    'Build a block wall',
    'How many hollow blocks, cement and sand a wall needs',
  ),
  'lintel': (
    'Strengthen a block wall',
    'Small concrete beams over doors and windows, and posts in long walls',
  ),
  'slab': (
    'Pour a concrete floor',
    'Concrete, steel bars and forms for a floor or upper deck',
  ),
  'footing': (
    'Dig and pour the base under posts',
    'The concrete pads in the ground that carry each post of the house',
  ),
  'wall_footing': (
    'Pour the base under walls',
    'A strip of concrete in the ground that carries a wall',
  ),
  'column': (
    'Pour concrete posts',
    'The upright concrete posts that hold up the house',
  ),
  'beam': (
    'Pour concrete beams',
    'The concrete bars across the top of posts that carry floors and roof',
  ),
  'pavement': (
    'Pour a driveway or walkway',
    'Concrete for a driveway, carport floor or sidewalk',
  ),
  'plywood': (
    'Cover with plywood',
    'Plywood sheets for a floor, wall or ceiling',
  ),
  'ceiling': ('Put up a ceiling', 'Ceiling boards and the frame they hang on'),
  'insulation': (
    'Keep the roof heat out',
    'Foam sheets under the roof that make rooms cooler',
  ),
  'paint': ('Paint walls', 'How many gallons of paint, with primer'),
  'tiles': ('Tile a floor or wall', 'Tiles, tile glue and grout for a room'),
  'roof': (
    'Roof a house',
    'Roof sheets, screws and the gutters along the edge',
  ),
  'doors': ('Put in doors', 'Doors with their frames, hinges and locks'),
  'windows': ('Put in windows', 'Aluminium windows, by size'),
  'carpet': ('Carpet a room', 'Carpet from a roll, or carpet squares'),
  'wallpaper': ('Hang wallpaper', 'How many rolls of wallpaper, with paste'),
  'bulb': ('Light up a room', 'How many LED bulbs a room needs'),
  'switch': (
    'Add light switches',
    'Wall switches, with their boxes and covers',
  ),
  'junction_box': (
    'Add ceiling light boxes',
    'The small boxes in the ceiling where lights are wired',
  ),
  'outlet': ('Add wall sockets', 'How many sockets to plug things into'),
  'wires': ('Wire the house', 'How many boxes of electrical wire to buy'),
  'utility_box': (
    'Add boxes for switches and sockets',
    'The boxes in the wall behind each switch and socket',
  ),
  'rough_in': (
    'Wire a whole house',
    'Wire, pipes for the wire, boxes and breakers for every room',
  ),
  'pvc': ('Run water or drain pipes', 'Pipes and their fittings for a line'),
  'sink': ('Put in a sink', 'Kitchen or bathroom sinks, with their pipes'),
  'toilet': ('Put in a toilet', 'Toilets, with valves and seals'),
  'faucet': ('Put in faucets', 'Faucets by type'),
  'shower': ('Put in a shower', 'Shower sets, with the floor drain'),
  'water_tank': ('Store water', 'A water tank big enough for the household'),
  'septic_tank': (
    'Put in a septic tank',
    'The underground tank the toilets drain into',
  ),
  'earthworks': (
    'Dig and fill the ground',
    'Digging for the foundation, filling back and soil to haul away',
  ),
  'stairs': ('Build concrete stairs', 'A straight concrete stair'),
  'railing': ('Add a stair or balcony railing', 'A steel railing'),
  'trusses': (
    'Frame the roof',
    'The steel frames that hold up the roof sheets',
  ),
  'fence': ('Build a fence', 'A block fence around the lot, with posts'),
  'gate': ('Put in a gate', 'A steel gate that swings or slides'),
  'fascia': ('Finish the roof edge', 'The board along the edge of the roof'),
  'soffit': (
    'Close under the roof edge',
    'Boards under the part of the roof that sticks out',
  ),
  'flashing': (
    'Stop roof leaks at joints',
    'Metal strips where the roof meets a wall or another roof',
  ),
  'waterproofing': (
    'Waterproof a floor or deck',
    'Coatings that keep water out of decks, baths and planters',
  ),
  'flooring': (
    'Lay a floor',
    'Vinyl or wood-look floor planks, with the layer under them',
  ),
  'cabinets': (
    'Put in kitchen cabinets',
    'Kitchen or bathroom cabinets with the counter top',
  ),
  'service_entrance': (
    'Connect power to the house',
    'The meter, the pipe and the wires from the electric post',
  ),
  'water_heater': ('Get hot water', 'A water heater, with pipes for hot water'),
  'bath_accessories': (
    'Finish a bathroom',
    'Towel bars, holders, grab bars and mirrors',
  ),
  'drainage': (
    'Drain rain and waste water',
    'Drain pipes and the pits that collect water',
  ),
  'water_pump': (
    'Get better water pressure',
    'A water pump sized for the house',
  ),
  'auxiliary': (
    'Wire internet, TV and cameras',
    'Cables for internet, TV, security cameras and a doorbell',
  ),
  'light_fixtures': (
    'Choose lights for a room',
    'Ceiling lights, downlights and tube lights for a room',
  ),
};

/// Everyday names and taglines for the four groups, by category name.
const plainCategoryWords = <String, (String label, String tagline)>{
  'structural': ('Build the house', 'Walls, floors, posts and the ground'),
  'architectural': ('Finish the house', 'Paint, tiles, roof, doors and floors'),
  'electrical': ('Lights and power', 'Lights, sockets and wiring'),
  'plumbing': ('Water and toilets', 'Pipes, sinks, toilets and tanks'),
};
