# How BuildQuantify calculates

Every calculator follows common Philippine estimating practice and the sizes
sold in Philippine hardware stores. Quantities are planning estimates: confirm
them with your supplier and engineer before buying.

Counts always round **up** (you cannot buy 0.3 of a block), ignoring
floating-point noise so that an exact 375.0000001 stays 375. Waste allowances
are rounded up separately. Costs are quantity × unit price, rounded to the
centavo. Items under **Also needed** are planning quantities and are not part
of the cost.

The formulas live in [`lib/materials/`](../lib/materials) and are tested in
[`test/materials/calculators_test.dart`](../test/materials/calculators_test.dart)
with hand-worked examples.

## Structural

### Concrete hollow blocks (CHB)

| Step | Formula |
| --- | --- |
| Area | length × height − doors and windows |
| Blocks | ⌈area × 12.5⌉ (a 0.40 × 0.20 m face with its joint) |
| Waste | + ⌈blocks × 5%⌉ by default (None, 5, 10 or 15%) |
| Cement, 40 kg bags | ⌈area × (mortar + faces × 0.192)⌉ |
| Sand | area × (mortar sand + faces × 0.016) m³ |
| Rebar, 10 mm | area × 4.28 m, in 6 m bars |

Class B mortar per m² of wall (Fajardo, *Simplified Construction Estimate*,
Table 2-2): 4" 0.522 bags + 0.0435 m³ sand, 6" 1.018 + 0.0844, 8" 1.500 +
0.125. Plaster 16 mm thick, Class B: 0.192 bags + 0.016 m³ per face. Rebar:
vertical bars at 0.60 m (2.13 m/m²) and horizontal bars every third course
(2.15 m/m²).

Sources: [AEDO CHB estimator](https://aedoconstruction.com/blog/chb-quantity-estimator-philippines/),
[AEDO CHB sizes](https://aedoconstruction.com/blog/chb-size-dimensions-philippines/),
[AEDO rebar spacing](https://aedoconstruction.com/blog/chb-wall-rebar-spacing-philippines/).

### Plywood

⌈area ÷ 2.977 m²⌉ for a 1.22 × 2.44 m (4' × 8') sheet, plus 10% waste by
default. Thickness (6, 9, 12, 18 mm) describes the item only.

### PE foam insulation

| Step | Formula |
| --- | --- |
| Slope length | rafter × pitch factor √(1 + (rise ÷ run)²) |
| Strips per side | ⌈roof length ÷ 0.95⌉ (1 m rolls, 50 mm taped lap) |
| Rolls | ⌈strips × (slope + 0.05) × sides × 1.05 ÷ roll length⌉ |
| Foil tape | (strips − 1) × (slope + 0.05) × sides |

Rolls are 1 × 50 m or 1 × 25 m. Pitch factors: 3:12 1.031, 4:12 1.054, 6:12
1.118, 8:12 1.202, 12:12 1.414 ([roofonline](https://roofonline.com/roof-pitch-factor/)).

## Architectural

### Paint

| Step | Formula |
| --- | --- |
| Area | length × height − doors and windows |
| Litres | area × coats ÷ (coverage ÷ 4) × 1.10 |
| Gallons | ⌈litres ÷ 4⌉ |
| Primer | area ÷ (25 ÷ 4) × 1.10 litres, in gallons |

A Philippine paint "gallon" is **4 litres**. Coverage per 4 L per coat: latex
30 m², enamel 25 m² (the low end of Boysen's published ranges, since rough
walls take more paint). Sources: [Boysen Permacoat](https://www.boysen.com.ph/products/boysen-permacoat-latex),
[Boysen Quick Drying Enamel](https://www.boysen.com.ph/products/boysen-quick-drying-enamel).

### Tiles

| Step | Formula |
| --- | --- |
| Tiles | ⌈length ÷ tile⌉ × ⌈width ÷ tile⌉, trying both orientations |
| Waste | + ⌈tiles × 10%⌉ straight, 15% diagonal |
| Boxes | ⌈total ÷ tiles per box⌉ (default 25, 17, 16, 8, 6, 4) |
| Adhesive, 25 kg | ⌈area × 3 kg (≤ 30 cm) or 5 kg (larger) ÷ 25⌉ |
| Grout | area × (a + b) ÷ (a × b) × 3 mm × depth × 1.6 kg |

Sizes: 20 × 20, 20 × 30, 30 × 30, 30 × 60, 40 × 40, 60 × 60 cm. Sources:
[Wilcon tiles](https://shop.wilcon.com.ph/tiles),
[Bostik Fixall data sheet](https://www.bostik.com/files/live/sites/shared_bostik/files/import-philippines/bostik-fixall-excel-tds-fa-rev1.pdf).

### Roofing sheets

| Sheet | Formula |
| --- | --- |
| Corrugated GI | ⌈roof length ÷ cover⌉ × ⌈(slope − 0.25) ÷ (sheet length − 0.25)⌉ × sides |
| Long-span rib type | ⌈roof length ÷ cover⌉ × sides sheets, each cut to slope + 0.05 m, sold per metre |

Corrugated sheets are 0.80 m wide and cover 0.70 m (1½ corrugation lap) or
0.60 m (2½); lengths 5–12 ft; end lap 0.25 m. Long-span covers about 1 m
(1.07 m and 0.98 m profiles also offered). Sources:
[Union Galvasteel Durarib](https://www.ugc.ph/product/durarib/),
[Multi-rib8](https://www.ugc.ph/product/multi-rib8/).

### Carpet

Broadloom: drops = ⌈room width ÷ roll width⌉, each room length + 0.10 m,
choosing the direction that needs less carpet; sold per m² from 4 m or
3.66 m rolls. Carpet tiles: ⌈area × 1.05 ÷ 0.25⌉ tiles in boxes of 20.
Also needed: underlay (area × 1.05), gripper (room perimeter), seam tape.

### Wallpaper

Strip = wall height + 0.10 m, rounded up to whole pattern repeats;
strips per roll = ⌊roll length ÷ strip⌋; rolls = ⌈⌈wall width ÷ roll
width⌉ ÷ strips per roll⌉. Rolls: 0.53 × 10.05 m standard, 1.06 × 15.6 m
jumbo, 0.45 × 10 m. Source: [Screwfix wallpaper guide](https://www.screwfix.com/guides/painting-decorating/wallpaper/how-much-wallpaper-do-i-need).

## Electrical

| Material | Formula |
| --- | --- |
| LED bulbs | ⌈lux × area ÷ (lumens × 0.5)⌉; bedroom 100 lx, living 150, bathroom 200, kitchen 300, study 500; 5–18 W at about 100 lm/W |
| Outlets | ⌈(2 × (length + width) − doorways) ÷ 3.6⌉ |
| Wire (THHN) | circuit length × wires (2, or 3 with ground) × 1.10, in 150 m boxes or by the metre |
| Switches, junction boxes, utility boxes | count × price |

The outlet rule follows the Philippine Electrical Code: no point along a wall
may be more than 1.8 m from an outlet ([PEC 2017 Art. 2.10](https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits)).
Wire sizes: 2.0 mm² lighting, 3.5 mm² outlets, 5.5 mm² aircon
([Phelps Dodge](https://phelpsdodge.com.ph/frequently-asked-questions/)).
Light levels: [Engineering ToolBox](https://www.engineeringtoolbox.com/light-level-rooms-d_708.html).

## Plumbing

| Material | Formula |
| --- | --- |
| PVC pipe | ⌈run × 1.10 ÷ pipe length⌉, 3 m pipes (4 m PPR) |
| Sinks, toilets, faucets, showers | count × price, plus the fittings each one needs |

Sources: [Neltex](https://www.neltex.com/products.do?item_id=51663),
[Moldex](https://mpi.moldex.com.ph/mb-pipes-and-fittings).

## Changes from the previous version

| Material | Before | Now |
| --- | --- | --- |
| CHB | Gross wall area, waste optional (0% default), 5" size | Openings deducted, 5% waste by default, 4"/6"/8"; mortar, plaster and rebar listed |
| Plywood | 1.2192 × 2.4384 m, no waste by default | 1.22 × 2.44 m, 10% waste by default |
| Foam insulation | Plan area ÷ 50 m² | Strips on the slope with taped laps; foil tape |
| Paint | 3.785 L gallons, coverage typed in | 4 L gallons, coverage by paint type, +10%, primer |
| Tiles | Area ÷ tile area | Rows × columns, layout waste, boxes, adhesive, grout |
| Roofing | Plan area ÷ sheet area, 0.9–1.2 m "corrugated" widths | Rows × columns on the slope, real cover widths, end laps, long-span by the metre |
| Carpet | Room area ÷ rug size | Broadloom drops or carpet tiles |
| Wallpaper | Area ÷ 1.22 × 2.44 m "roll" | Strip method on real roll sizes |
| Light bulbs | Count only | Lumen method from the room size (count still available) |
| Outlets | Count only | Code spacing from the room size (count still available) |
| Wire | Metres × price, "twisted pair" option | Circuit × wires + 10%, 150 m boxes, THHN sizes |
| PVC pipe | Count, 5/10 ft lengths | Run + 10% in 3 m or 4 m pipes, metric diameters |

## Limits

The Fajardo factors and the PEC wording were checked against secondary copies
(student uploads and transcriptions), and AEDO is a contractor's blog. Light
loss (0.5) and fitting allowances (10%) are typical planning values, not code
requirements.
