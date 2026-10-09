// Definitions shown in each calculator's "Definitions" sheet.
// Ported from the original per-material screens, with copy errors fixed.

import 'material_spec.dart';

const Map<String, List<InfoSection>> materialDefinitions = {
  'chb': [
    InfoSection(
      'CHB',
      'Concrete hollow blocks are construction materials commonly used in building walls.',
    ),
    InfoSection(
      'Wall Height',
      'Wall height refers to the vertical measurement from the floor to the ceiling or the top of the wall. It represents the distance along the upright structure of a wall, indicating how tall the wall is. Wall height can vary within a building or room, depending on architectural design, room functionality, and overall construction specifications.',
    ),
    InfoSection(
      'Wall Length',
      'Wall length is the horizontal measurement from one end of the wall to the other. It is usually described in terms of linear feet or meters, representing the horizontal distance between two endpoints or the total span of the wall. Wall width can vary within a building or room, depending on architectural design, room functionality, and overall construction specifications.',
    ),
    InfoSection(
      'CHB Size',
      'The size of concrete hollow blocks can vary, but they are typically identified by their width, height, and length. Common sizes include:\n4 inches: This is a standard width for smaller applications.\n5 inches: A commonly used size for both residential and commercial construction.\n6 inches: Larger and heavier blocks, often used for load-bearing walls or firewalls.\nThe length and height of CHBs can also vary, and they may have one or more hollow cores running through them, providing insulation and reducing the overall weight. The specific dimensions of concrete hollow blocks depend on regional standards, construction requirements, and the intended use in a building project.',
    ),
    InfoSection(
      'CHB Contingency',
      'CHB contingency refers to an additional amount or provision set aside to address unforeseen circumstances or changes in project requirements. It’s an extra allocation of CHBs beyond the initially estimated quantity. This allowance could account for potential changes in design, unexpected construction challenges, or variations in the actual number of blocks needed. It is a practical approach to mitigate the risk of running short on materials during the construction process.',
    ),
  ],
  'plywood': [
    InfoSection(
      'Plywood',
      'A foundational and indispensable material in construction, renowned for its structural strength, versatility, and reliability. Plywood\'s inherent strength allows it to efficiently distribute loads, making it a preferred choice for structural components in residential, commercial, and industrial construction projects. Its ease of use, cost-effectiveness, and adaptability to different construction needs make plywood a key player in the construction industry, contributing to the stability and longevity of structures worldwide.',
    ),
    InfoSection(
      'Area Length',
      'Area length refers to the measurement of the longest dimension of a surface, such as a wall or ceiling. It is typically measured from one end to the other, representing the linear distance along a wall. This measurement provides an indication of the overall size of the room in that specific direction.',
    ),
    InfoSection(
      'Area Width',
      'Area width refers to the measurement of the shorter dimension of a surface, such as a wall or a ceiling. It is typically measured from one side to the other, perpendicular to the length. Together with the area length, the area width helps define the overall size and shape of a room or surface.',
    ),
    InfoSection(
      'Plywood Size',
      'The most common and standard size for plywood sheets is 4’ by 8’ used in construction and carpentry. It is the size always available in the Philippine market.',
    ),
    InfoSection(
      'Plywood Contingency',
      'Plywood contingency refers to an additional amount or provision set aside in a construction project to account for unforeseen circumstances or changes related to the quantity of plywood needed. This might involve allocating an extra percentage of plywood sheets beyond the initially estimated quantity. This extra allowance helps mitigate the risk of running short on materials and provides flexibility in adapting to any changes or unexpected events during the construction project.',
    ),
  ],
  'insulation': [
    InfoSection(
      'Foam Insulation',
      'PE foam insulation is made from polyethylene foam. It is an excellent thermal insulator for roofs, walls, floors and air ducts.',
    ),
    InfoSection(
      'Foil Laminated Insulation',
      'Can be laminated with MPET reflective film or aluminum foil as an outer skin for increased durability and to reflect heat.',
    ),
    InfoSection(
      'Adhesive Backed',
      'Available with pressure sensitive adhesive for easy installation to air ducts and metal sheets.',
    ),
    InfoSection(
      'Area Length',
      'Area length refers to the measurement of the longest dimension of the ceiling. It is typically measured from one end to the other, representing the linear distance along a wall. This measurement provides an indication of the overall size of the room in that specific direction.',
    ),
    InfoSection(
      'Area Width',
      'Area width refers to the measurement of the shorter dimension of the ceiling. It is typically measured from one side to the other, perpendicular to the length. Together with the area length, the area width helps define the overall size and shape of a room or surface.',
    ),
    InfoSection(
      'Insulation Thickness',
      'Insulation thickness refers to the depth or thickness of the insulation material installed in a building\'s walls, ceilings, floors, or other areas to reduce heat transfer. The thickness of insulation is a critical factor in determining its effectiveness in providing thermal resistance (R-value).\n\nTo determine the required insulation thickness for a specific area, it\'s important to consider local building codes, energy efficiency standards, and the recommended R-values for the climate zone. You may refer to specifications indicated on your architectural or engineering plans.',
    ),
    InfoSection(
      'Insulation Size',
      'Insulation size refers to the physical dimensions of insulation materials, such as the width and length of rolls. Common dimensions for insulation products include the width of rolls (e.g., 1 meter) and the length of batts (e.g., 50 meters).',
    ),
    InfoSection(
      'Insulation Type',
      'Insulation with aluminum sides typically refers to insulation materials that have a layer of aluminum on one or both sides. This aluminum layer serves various purposes, including enhancing the insulation\'s performance and providing additional features.',
    ),
  ],
  'paint': [
    InfoSection(
      'Paint',
      'Beyond its role in providing a protective layer to surfaces, such as walls and ceilings, paint contributes significantly to the overall design and ambiance of a space. It allows for personalization, creativity, and the expression of architectural style. The process of selecting paint involves considerations such as color, finish, and durability, ensuring that it aligns with both the practical requirements and the desired aesthetic of a construction project. Whether used to refresh the appearance of existing structures or to finalize the finishing touches on newly built spaces, paint stands as a versatile and essential component in the construction industry.',
    ),
    InfoSection(
      'Area Length',
      'Area length refers to the measurement of the longest dimension of a surface, such as a wall or ceiling. It is typically measured from one end to the other, representing the linear distance along a wall. This measurement provides an indication of the overall size of the room in that specific direction.',
    ),
    InfoSection(
      'Area Width',
      'Area width refers to the measurement of the shorter dimension of a surface, such as a wall or a ceiling. It is typically measured from one side to the other, perpendicular to the length. Together with the area length, the area width helps define the overall size and shape of a room or surface.',
    ),
    InfoSection(
      'Number of Coats',
      'The number of coats required for paint coverage depends on factors like surface type, paint color, and desired finish. Primer is often recommended before applying two or more top coats. Darker colors, porous surfaces, or textured walls may need extra coats. Follow the manufacturer\'s instructions for the specific paint product to achieve optimal coverage and finish.',
    ),
    InfoSection(
      'Paint Coverage',
      'Paint coverage refers to the area that a specific amount of paint can cover on a surface. It is usually measured in square feet or square meters per gallon or liter of paint. Understanding paint coverage is important when planning a painting project, as it helps determine how much paint you need to purchase based on the size of the surfaces you intend to paint.\n\nManufacturers typically provide an estimated coverage rate on the paint can or product data sheet. This information helps consumers determine how much paint to buy based on the size of the area to be painted. However, it\'s important to note that these estimates are general guidelines, and actual coverage may vary based on several factors (surface porosity, texture, color, sheen, and paint quality) and the application method.',
    ),
  ],
  'tiles': [
    InfoSection(
      'Tiles',
      'Tiles are versatile and integral elements in construction and interior design, commonly employed for surfacing floors, walls, and various spaces. These thin, flat pieces of material, often made from ceramics, porcelain, natural stone, or glass, come in an extensive array of sizes, shapes, colors, and patterns. Whether used to enhance the functionality of a kitchen or bathroom, create intricate mosaic designs, or add a touch of sophistication to living spaces, tiles serve both practical and decorative purposes.',
    ),
    InfoSection(
      'Room Length',
      'Room length refers to the measurement of the longest dimension of a room, typically measured from one end to the other. It represents the linear distance along one of the walls and gives an indication of the overall size of the room in that particular direction.',
    ),
    InfoSection(
      'Room Width',
      'Room width refers to the measurement of the distance between the two parallel walls that form the sides of a room. It is the dimension that runs perpendicular to the length of the room. The width, along with the length and height, contributes to the overall spatial characteristics of the room.',
    ),
    InfoSection(
      'Tile Size',
      'Tile size refers to the physical dimensions of individual tiles used in flooring, wall covering, or other tiling applications. Tiles come in various sizes, and the choice of size depends on factors such as the intended use, design preferences, and the dimensions of the space.\n\nSelection of tile size should be based on design specified on architectural plans or client’s design preference.',
    ),
    InfoSection(
      'Tile Contingency',
      'Tile contingency refers to an additional quantity of tiles that is ordered and kept in reserve during a tiling project. This extra amount is intended to account for potential mistakes, breakages, or unforeseen issues that may arise during the installation process. The purpose of having tile contingency is to ensure that there are enough tiles available to complete the project even if there are unexpected challenges.\n\nFactors such as irregularities in the space, cutting errors, breakage during handling, or changes in design preferences can contribute to the need for extra tiles beyond the initially estimated quantity. By having a tile contingency, contractors or homeowners can avoid delays in the project and ensure that they have enough matching tiles to complete the installation without having to wait for additional orders.',
    ),
  ],
  'roof': [
    InfoSection(
      'Roof',
      'A roof is the uppermost covering of a building or structure, providing protection from weather elements such as rain, snow, sunlight, and wind. Roofs serve the essential function of sheltering the interior space beneath them and play a crucial role in the overall structure and design of a building. Roofs can be constructed using various materials, including shingles, tiles, metal, or concrete, and they come in different shapes and styles.',
    ),
    InfoSection(
      'Rib Roof',
      'A rib roof typically refers to a type of roofing structure characterized by the use of ribs or raised ridges along the surface of the roof. These ribs can add strength and support to the roof structure while also creating a distinctive architectural appearance. Rib roofs are often associated with certain types of metal roofing systems or architectural designs that incorporate ribbed patterns for both functional and aesthetic purposes. The ribs can enhance the structural integrity of the roof and may also contribute to efficient water drainage.',
    ),
    InfoSection(
      'Roof Length',
      'Roof area length refers to the measurement of the longest dimension of a roof surface. It is typically measured from one end to the other, providing the linear distance along the roof.',
    ),
    InfoSection(
      'Roof Width',
      'Roof area width refers to the measurement of the shortest dimension of a roof surface. It is typically measured from one end to the other, providing the linear distance along the roof.',
    ),
    InfoSection(
      'Roof Sheet Dimension',
      'Roof sheet dimensions encompass the specific length and width measurements of the individual sheets utilized in roofing applications. The dimensions are contingent upon the type of roofing material selected for a particular project. Prior to initiating a roofing project, it is advisable to refer to the product documentation and specifications provided by the manufacturer to ensure accurate measurements and adherence to installation guidelines.',
    ),
    InfoSection(
      'Corrugation',
      'Roof corrugation refers to the wavy pattern on roofing materials, commonly seen in metal sheets. This design enhances structural strength, rigidity, and facilitates efficient water drainage, making it suitable for areas with heavy rainfall. Corrugated roofing is known for its durability, affordability, and widespread use in construction.',
    ),
  ],
  'carpet': [
    InfoSection(
      'Room Length',
      'Room length refers to the measurement of the longest dimension of a room, typically measured from one end to the other. It represents the linear distance along one of the walls and gives an indication of the overall size of the room in that particular direction.',
    ),
    InfoSection(
      'Room Width',
      'Room width refers to the measurement of the distance between the two parallel walls that form the sides of a room. It is the dimension that runs perpendicular to the length of the room. The width, along with the length and height, contributes to the overall spatial characteristics of the room.',
    ),
    InfoSection(
      'Carpet Size',
      'Carpet size refers to the physical dimensions of each carpet or rug used in a flooring application. Carpets come in various sizes, and the choice of size depends on factors such as the intended use, design preferences, and the dimensions of the space.\n\nSelection of carpet size should be based on the design specified on architectural plans or the client’s preference.',
    ),
    InfoSection(
      'Carpet Contingency',
      'Carpet contingency refers to an additional quantity of carpet that is ordered and kept in reserve during an installation. This extra amount is intended to account for potential mistakes, breakages, or unforeseen issues that may arise during the installation process. The purpose of having tile contingency is to ensure that there are enough tiles available to complete the project even if there are unexpected challenges.\n\nFactors such as irregularities in the space, cutting errors, breakage during handling, or changes in design preferences can contribute to the need for extra tiles beyond the initially estimated quantity. By having a tile contingency, contractors or homeowners can avoid delays in the project and ensure that they have enough matching tiles to complete the installation without having to wait for additional orders.',
    ),
  ],
  'wallpaper': [
    InfoSection(
      'Wall Height',
      'Wall height refers to the vertical measurement from the floor to the ceiling or the top of the wall. It represents the distance along the upright structure of a wall, indicating how tall the wall is. Wall height can vary within a building or room, depending on architectural design, room functionality, and overall construction specifications.',
    ),
    InfoSection(
      'Wall Width',
      'Wall width refers to the horizontal measurement from a wall to another. It is usually described in terms of linear feet or meters, representing the horizontal distance between two endpoints or the total span of the wall. Wall width can vary within a building or room, depending on architectural design, room functionality, and overall construction specifications.',
    ),
    InfoSection(
      'Wallpaper Coverage',
      'Wallpaper coverage refers to the area that a specific quantity of wallpaper can cover on a wall or surface, typically measured in square feet or square meters per roll or package. It considers factors like wall dimensions, pattern repeats, and a waste factor to determine the amount needed for a project. Manufacturers provide coverage information to help consumers estimate the quantity of wallpaper required based on the size of the area to be covered.',
    ),
  ],
  'bulb': [
    InfoSection(
      'Bulb',
      'In construction, the term \'bulb\' typically refers to a light bulb, an essential element in both residential and commercial buildings. Modern construction incorporates a variety of bulb types, including incandescent, fluorescent, LED, and others, each with distinct characteristics such as color temperature, brightness, and energy consumption. Properly planned lighting design not only enhances visibility and safety within a construction but also contributes to the mood and functionality of different areas. The selection of bulbs in construction is, therefore, a thoughtful consideration, aligning with the architectural and functional requirements of the space while also addressing energy efficiency and sustainability concerns.',
    ),
    InfoSection(
      'Bulb Quantity',
      'Light bulb quantity refers to the number of light bulbs, included in a set, package, or specific lighting fixture. It is a measure of how many individual light sources are provided. When purchasing lighting products, the bulb quantity specification is essential for knowing how much illumination the product will provide and for determining if it meets the lighting requirements for a particular space or application.',
    ),
    InfoSection(
      'Bulb Type',
      'Light bulb type refers to the specific design and technology of a light bulb. Common types include incandescent, CFL (Compact Fluorescent Lamp), LED (Light Emitting Diode), halogen, fluorescent tubes, candelabra, and smart bulbs. Each type has unique features, energy efficiency, and applications. Consider factors like brightness, color temperature, and specific lighting needs when choosing a light bulb type for a particular space or task.',
    ),
    InfoSection(
      'Wattage',
      'Light wattage refers to the amount of electrical power consumed by a light bulb and is measured in watts (W). It indicates the bulb\'s energy consumption and provides a general indication of its brightness. In traditional incandescent bulbs, higher wattages typically correspond to brighter light output. When selecting light bulbs, consider the wattage to ensure it meets the desired brightness and energy efficiency for the intended application.',
    ),
  ],
  'switch': [
    InfoSection(
      'Switch',
      'A switch is an electrical component that can break an electrical circuit, interrupting the current or diverting it from one conductor to another. The mechanism of a switch removes or restores the conducting path in a circuit when it is operated. It may be operated manually, for example, a light switch or a keyboard button, may be operated by a moving object such as a door, or may be operated by some sensing element for pressure, temperature, or flow. A switch will have one or more sets of contacts, which may operate simultaneously, sequentially, or alternately. Switches in high-powered circuits must operate rapidly to prevent destructive arcing, and may include special features to assist in rapidly interrupting a heavy current. Multiple forms of actuators are used for operation by hand or to sense position, level, temperature or flow. Special types are used, for example, for control of machinery, to reverse electric motors, or to sense liquid level.',
    ),
    InfoSection(
      'Switch Quantity',
      'Light switch quantity refers to the number of individual light switches in a given space or area. It indicates how many separate controls are available to operate the lighting fixtures. The quantity of light switches in a room or building depends on factors such as the room\'s layout, size, and the desired lighting configurations.',
    ),
  ],
  'junction_box': [
    InfoSection(
      'Junction Box',
      'A junction box is a container that houses electrical connections, such as wire splices, and is used to protect the connections from the elements. It is typically made of metal or plastic and is designed to be weatherproof. Junction boxes are used in a variety of applications, including outdoor lighting, irrigation systems, and electrical wiring for buildings. They are an essential component of any electrical system and are designed to provide a safe and secure environment for electrical connections.',
    ),
    InfoSection(
      'Junction Box Quantity',
      'Junction box quantity refers to the number of junction boxes installed in a particular electrical system or building. A junction box is an enclosure that houses electrical connections, protecting them from environmental factors, preventing accidental contact, and containing potential sparks or fires. The quantity of junction boxes is a critical consideration in electrical installations to ensure proper wiring organization, safety, and compliance with electrical codes.',
    ),
  ],
  'outlet': [
    InfoSection(
      'Outlet',
      'An outlet (also called a socket or convenience outlet) is the wall-mounted receptacle that electrical devices plug into for power. Outlets come in 1-gang, 2-gang and 3-gang versions, meaning one, two or three sockets on a single plate. Choose the type that matches the number of devices expected at each location in the electrical plan.',
    ),
    InfoSection(
      'Outlet Quantity',
      'Outlet quantity refers to the number of electrical outlets or receptacles installed in a particular space, building, or area. An electrical outlet is a device equipped with one or more sockets where electrical devices can be plugged in to access power. The determination of outlet quantity is a crucial aspect of electrical system design and planning, ensuring that there are sufficient access points for powering various devices.',
    ),
  ],
  'wires': [
    InfoSection(
      'Wire Length',
      'Electrical wires linear meter refers to the measurement of the length of electrical wires in linear meters. In this context, \'linear meter\' indicates the straight-line distance or length of the electrical wire. The linear meter measurement for electrical wires is a practical way to estimate the quantity needed, plan installations, and manage material costs in various electrical and construction projects.',
    ),
    InfoSection(
      'Wire Type',
      'Electrical wire types refer to the various categories and classifications of wires used in electrical systems based on their composition, insulation, and intended applications. Different wire types are designed to meet specific requirements in terms of electrical conductivity, insulation properties, and environmental conditions.',
    ),
  ],
  'utility_box': [
    InfoSection(
      'Utility Box Quantity',
      'Utility box is typically a container or enclosure used to house electrical components, such as switches, outlets, or circuit breakers. The quantity would depend on factors such as the size of the building, the number of electrical devices needed, and the layout of the electrical system.',
    ),
  ],
  'pvc': [
    InfoSection(
      'Linear Meter',
      'Linear meter refers to the measurement of the length of pipes in a straight line. It is a unit of length used to quantify the amount of pipe needed for a project. The length is measured in meters, and it represents the total linear distance of the pipes, considering any bends, curves, or straight sections. To calculate the linear meterage of pipes, you need to measure the actual length of each pipe section, account for any twists and turns, and sum up the total length.',
    ),
    InfoSection(
      'PVC Length',
      'PVC length refers to the various sizes and lengths of PVC (Polyvinyl Chloride) pipes that are commercially available for purchase. PVC pipes come in a range of dimensions to suit different applications and project requirements. The lengths of PVC pipes can vary, and they are typically available in standard measurements.',
    ),
    InfoSection(
      'PVC Diameter',
      'PVC diameter refers to the size or width of a PVC (Polyvinyl Chloride) pipe, and it\'s a critical dimension that influences the pipe\'s applications and compatibility with various systems. PVC pipes come in a range of diameters, and the selection of the appropriate size depends on the specific requirements of the intended use.',
    ),
  ],
  'sink': [
    InfoSection(
      'Sink Quantity',
      'Sink refers to the number of sinks in a particular context, such as a building, room, or facility. A sink is a fixture designed for washing hands, dishes, or other items and is commonly found in kitchens, bathrooms, and utility areas.',
    ),
    InfoSection(
      'Sink Type',
      'There are various types of sinks designed for different purposes and settings. The choice of sink type depends on the intended use, available space, and aesthetic preferences. Each type of sink has its advantages and is suitable for specific applications. You may select the type of sink based on architectural and engineering plans.',
    ),
  ],
  'toilet': [
    InfoSection(
      'Toilet Quantity',
      'Toilet quantity refers to the number of toilet units installed in a particular building, area, or facility. It is a crucial aspect of planning and designing spaces, such as restrooms or bathrooms, and is essential for providing adequate facilities for occupants.',
    ),
    InfoSection(
      'Toilet Fixture',
      'Toilet fixture refers to the complete unit or assembly that includes the necessary components for the disposal of human waste.',
    ),
  ],
  'faucet': [
    InfoSection(
      'Faucet Quantity',
      'Faucet quantity refers to the number of faucet units installed in a particular building, area, or facility. A faucet is a device that controls the flow of water and is commonly found in kitchens, bathrooms, utility rooms, and other spaces where water access is required.',
    ),
    InfoSection(
      'Faucet Type',
      'Faucet type refers to the specific design or style of a water delivery device used to control the flow of water in plumbing fixtures. Faucets come in various types, each designed for different purposes, preferences, and settings. The choice of faucet type depends on factors such as the style of the space, functionality requirements, and personal preferences. Different faucet types offer varying features and aesthetics to meet the needs of specific applications and design styles.',
    ),
  ],
  'shower': [
    InfoSection(
      'Shower Quantity',
      'Shower quantity refers to the number of shower units installed in a building or facility, determined by factors such as occupancy, usage needs, and building codes. It is crucial for efficient space utilization and meeting the requirements of the intended users in areas like bathrooms, gyms, or residential buildings.',
    ),
    InfoSection(
      'Shower Type',
      'Shower type refers to the specific design or style of a shower unit, each catering to different preferences, spatial considerations, and functionalities. The term encompasses a variety of shower designs.Choosing a specific shower type depends on factors such as available space, aesthetic preferences, and desired features for an optimal showering experience.',
    ),
  ],
};

const Map<String, List<String>> materialReferences = {
  'chb': [
    'https://www.google.com/maps/uv?pb=!1s0x32fff3630267848b%3A0x9394e7120eb15b2c!3m1!7e131!4s!5sNEW%20ROCKS%20INC.!15sCgIgAQ&hl=en&imagekey=!1e10!2sAF1QipNO3DEL4l-e1igfzEg0dHT3CiGQT1uA1kL30b0C',
  ],
  'plywood': ['https://www.theprojectestimate.com/plywood-price-list/'],
  'insulation': [
    'https://www.ritemore.com/products/pe-foam-insulation?fbclid=IwAR31-rpqYZfO3BiIWzLUUOWgT5s7zqzAtGXmb-st2hNcXsqBHPE4nVwQFbg',
  ],
  'paint': [
    'https://www.facebook.com/BoysenPaintsPhilippines/posts/not-sure-how-many-gallons-of-paint-will-your-diy-painting-project-needone-can-av/3319103928138155/',
  ],
  'tiles': ['https://tilecenter.ph/tiles', 'https://shop.wilcon.com.ph/tiles'],
  'roof': [
    'https://www.alphasteel.ph/rib-type-roof/',
    'https://steelcaretrading.com/product/corrugated-roof-panel/',
    'https://www.metalinkretail.com/products/corrugated-roof-prepainted',
  ],
  'carpet': [
    'https://eurobel.com.ph/blogs/how-to-choose-the-right-area-rug-sizes-for-living-room/',
  ],
  'wallpaper': ['https://fancify.com.au/pages/wallpaper-calculation'],
  'bulb': [
    'https://www.felcostore.ph/products/firefly-basic-led-a-bulb?_pos=1&_sid=4210c26e4&_ss=r',
  ],
  'switch': [
    'https://jgsuperstore.com/products/omni-10a-250v-surface-convenience-outlet-for-desktop-office-and-home-electronics-1-gang-2-gang-3-gang-4-gang-wso-00',
  ],
  'junction_box': [
    'https://shop.wilcon.com.ph/catalogsearch/result/?q=Utility%20Box',
  ],
  'outlet': [
    'https://jgsuperstore.com/products/omni-10a-250v-surface-convenience-outlet-for-desktop-office-and-home-electronics-1-gang-2-gang-3-gang-4-gang-wso-00',
  ],
  'wires': [
    'https://www.askmediy.com/electrical-wire-size-calculator/',
    'https://www.affordablecebu.com/load/technology/list_of_common_types_of_wires_in_the_philippines/7-1-0-30112',
  ],
  'utility_box': [
    'https://shop.wilcon.com.ph/catalogsearch/result/?q=Utility%20Box',
  ],
  'pvc': [
    'https://pvcpipeworks.s3.amazonaws.com/docs/pvc_pipeworks_pipe_dims_ref.pdf',
    'https://www.commercial-industrial-supply.com/resource-center/pvc-pipe-and-fittings-dimensions/',
    'https://pvcpipesupplies.com/1-2-pipe-p0050rf-5.html',
  ],
  'sink': [
    'https://shop.wilcon.com.ph/products/plumbing/sink.html?p=3',
    'https://citihardware.com/dasmarinas/kitchen/100625721-sink-bremen-zw-sbw0619-5045-sb-500x450x230-ss304-w-strainer.html',
  ],
  'toilet': ['https://shop.wilcon.com.ph/catalogsearch/result/?q=toilet'],
  'faucet': ['https://shop.wilcon.com.ph/faucet-fixture'],
};
