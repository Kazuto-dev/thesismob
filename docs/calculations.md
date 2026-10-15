# How BuildQuantify calculates

BuildQuantify has 29 calculators in four groups. Each one follows common
Philippine estimating practice and the sizes sold in Philippine hardware
stores. Quantities are planning estimates: confirm them with your supplier
and engineer before buying.

The formulas live in [`lib/materials/`](../lib/materials). Each calculator's
**Definitions** and **Solution** sheets in the app show the same formulas;
where a sheet and the code differ, this page follows the code.

## How a result is built

**Main material.** Each calculator works out one main material, such as
blocks, bags of cement or gallons of paint. Its cost is quantity × the price
in the price field. The price field is filled from the price book (see
[Prices and costing](prices-and-costing.md)); type your supplier's price to
use it instead.

**Rounding.** Counts always round **up**, because you cannot buy 0.3 of a
block. Rounding ignores floating-point noise, so an exact 375.0000001 stays
375. A waste allowance is rounded up on its own and added:
total = count + ⌈count × waste⌉. Costs are quantity × unit price, rounded to
the centavo.

**Companion materials.** Most calculators also list the other materials the
job needs: cement and sand for blocks, bars and tie wire for concrete,
primer for paint, fittings for pipe. Each companion is rounded up to an
amount you can buy:

| Sold by | Rounded to |
| --- | --- |
| Bags, pieces, sheets, rolls, boxes, packs, tubes, cans | Whole units |
| Kilograms (tie wire, nails), litres, board feet, metres of gutter or wire | Whole kg, L, bd ft or m |
| Sand and gravel | 0.5 m³ |
| Carpet underlay | 0.1 m² |

Companions are priced from the price book when the estimate is saved, and
they **are part of the cost**. An estimate's materials total is the main
material plus all its companions (`Estimate.grandTotal` in
[`lib/data/estimate.dart`](../lib/data/estimate.dart)). One companion is an
allowance rather than a count: PVC fittings at 40% of the pipe cost, bought
as one lot.

**Labour and markups.** Calculators price materials only. Labour, minor
tools, hauling, contingency, overhead, profit and VAT are added at project
level. See [Prices and costing](prices-and-costing.md).

Symbols: ⌈x⌉ rounds up, ⌊x⌋ rounds down. "d" is the bar diameter. Defaults
are in brackets.

## Shared factors

Several calculators share these factors, kept in
[`lib/materials/factors.dart`](../lib/materials/factors.dart).

| Factor | Value | Source and status |
| --- | --- | --- |
| Concrete per m³ (40 kg bags, sand, gravel) | Class AA 1:1.5:3 = 12 bags; A 1:2:4 = 9; B 1:2.5:5 = 7.5; C 1:3:6 = 6; all with 0.5 m³ sand and 1.0 m³ gravel | Fajardo, *Simplified Construction Estimate*, Table 1-2, seen in student copies. AEDO gives the same figures. The table has no waste. |
| Class B mortar (1:3) | 12 bags and 1.0 m³ sand per m³ | Fajardo. Matches the plaster factor (0.192 ÷ 0.016 = 12). |
| Mortar to lay CHB, per m² of wall | 4": 0.522 bags + 0.0435 m³; 6": 1.018 + 0.0844; 8": 1.500 + 0.125 | Fajardo Table 2-2 |
| Plaster 16 mm, per m² of each face | 0.192 bags + 0.016 m³ | Fajardo |
| Blocks per m² | 12.5 (0.40 × 0.20 m with its joint) | AEDO CHB sizes |
| Reinforcing bars | 6 m stock length | What retail hardware stocks (AEDO 2026 price list). 7.5–12 m bars exist but are not offered. |
| Tie wire, #16 GI | 0.30 m per crossing for bars up to 12 mm, 0.40 m for larger; 53 m per kg | 20–40 cm per tie is from PH course notes in Fajardo's wording. 53 m/kg is widely quoted as Fajardo but not confirmed. A #16 wire weighs about 60 m/kg, so 53 includes some waste. |
| 4' × 8' sheet | 2.977 m² (1.22 × 2.44 m) for plywood and ceiling boards; 2.88 m² for forms | Fajardo counts form plywood at 1.20 × 2.40 m |
| Concrete cover | 75 mm against earth (footings); 40 mm in columns, beams and slabs on fill; 20 mm in suspended slabs | NSCP 2015 Table 420.6.1.3.1 gives 75, 40 and 20 mm. 40 mm for a slab on fill is the app's simplification. |
| Tie and stirrup hook | 135°, max(6d, 75 mm) + 3d for the bend: 0.105 m for a 10 mm tie | NSCP 2015 Sec. 425.3, which follows ACI 318-14. Recalled, not checked against the code text. The 3d bend allowance is derived. |
| Lap splice | 40, 50 or 60 d [40 d] | A rule of thumb. ACI 318-14 Class B laps work out to about 37 d for Grade 275 (Grade 40) bars in 21 MPa concrete, and about 57 d for Grade 420 (Grade 60). |

**Cutting bars from 6 m stock.** Offcuts are not reused.

| Bar length | Stock bars |
| --- | --- |
| Up to 6 m | ⌈pieces ÷ ⌊6 ÷ length⌋⌉ |
| Over 6 m | splices = ⌈length ÷ 6⌉ − 1; bars = ⌈pieces × (length + splices × lap) ÷ 6⌉ |

**Forms.** Footings, columns, beams and suspended slabs use plywood forms.

| Item | Formula | Source and status |
| --- | --- | --- |
| Marine plywood, 6 or 12 mm [12] | max(1, ⌈contact area ÷ 2.88 ÷ uses⌉) | Fajardo |
| Coco lumber frame | plywood sheets × board feet per sheet: columns and footings 29.67 (6 mm) or 20.33 (12 mm); beams 25.06 or 18.66; suspended slabs 28.8 | Fajardo's "board foot of wood frame per plywood form" table, from course copies. The slab figure (about 10 bd ft per m² for joists, stringers, shores and bracing) is derived, not from a table. |
| Common nails | contact area × 0.20 kg | Two PH bills of quantities (0.20 and 0.25 kg/m²). No Fajardo or DPWH factor was found. |

Because lumber follows the plywood count, it is reused as many times as the
plywood.

## Structural

### Concrete hollow blocks (CHB)

| Step | Formula |
| --- | --- |
| Area | length × height − doors and windows |
| Blocks | ⌈area × 12.5⌉ |
| Waste | + ⌈blocks × waste⌉ [5%; none, 5, 10 or 15%] |
| Cement | area × (mortar + faces × 0.192) bags |
| Sand | area × (mortar sand + faces × 0.016) m³ |
| Bars, 10 or 12 mm [10] | ⌈area × (vertical + horizontal) ÷ 6⌉ |
| Tie wire | area ÷ vertical spacing ÷ (courses × 0.20) crossings × 0.30 m ÷ 53 m per kg |

Block size is 4", 6" or 8" [4"]; it sets the mortar factor and the price.
Plaster is none, one face or both faces [both]. Bar per m² of wall, laps
included: vertical bars every 0.40, 0.60 or 0.80 m [0.60] need 2.93, 2.13 or
1.60 m; horizontal bars every 2nd, 3rd or 4th course [3rd] need 3.30, 2.15
or 1.72 m. Spacing must follow the plans.

Sources: Fajardo Table 2-2;
[AEDO CHB estimator](https://aedoconstruction.com/blog/chb-quantity-estimator-philippines/),
[AEDO CHB sizes](https://aedoconstruction.com/blog/chb-size-dimensions-philippines/),
[AEDO rebar spacing](https://aedoconstruction.com/blog/chb-wall-rebar-spacing-philippines/).

### Concrete slab

| Step | Formula |
| --- | --- |
| Volume | length × width × thickness [0.10 m] × (1 + waste) [5%; 0, 5 or 10%] |
| Cement (main item) | ⌈volume × bags per m³⌉ |
| Sand, gravel | volume × 0.5 m³, volume × 1.0 m³ |
| Bar runs | each way: ⌊(side − 2 × cover) ÷ spacing⌋ + 1 |
| Bars, 10 or 12 mm [10] | stock bars for the runs each way, spliced with the chosen lap |
| Tie wire | runs one way × runs the other way × 0.30 m ÷ 53 |
| Gravel bed (on fill) | area × bed thickness [0.10 m; none, 0.05, 0.10 or 0.15] |
| Forms (suspended) | plywood, lumber at 28.8 bd ft per sheet, nails; forms used once by default |

A slab is **on fill** or **suspended**. The usual mix is Class B on fill and
Class A suspended; any class can be picked. The usual bar spacing both ways
is 0.40 m on fill and 0.20 m suspended; 0.15 to 0.40 m or no bars can be
picked. Cover is 40 mm on fill and 20 mm suspended. The price field is the
price per bag of cement.

Sources: Fajardo Table 1-2;
[AEDO concrete mix](https://aedoconstruction.com/blog/concrete-mix-ratio-philippines/);
NSCP 2015 Table 420.6.1.3.1.

### Footings

| Step | Formula |
| --- | --- |
| Volume | count × length × width × thickness [0.25 m] × (1 + waste) [5%] |
| Cement (main item), sand, gravel | as for slabs, Class A by default |
| Bars per footing | each way: ⌊(side − 0.15) ÷ spacing⌋ + 1, each (other side − 0.15) long |
| Bars, 12, 16 or 20 mm [12] at 0.10–0.25 m [0.15] | stock bars for all pieces |
| Tie wire | count × bars one way × bars the other way × 0.30 m (0.40 m above 12 mm) ÷ 53 |
| Side forms (optional) | contact area = count × 2 × (length + width) × thickness; reused 3 times by default; lumber at the column factor |

Footings are usually cast against the soil, so side forms are off by
default. Column dowels are counted with the columns.

Sources: Fajardo Table 1-2; NSCP 2015 Table 420.6.1.3.1 (75 mm cover against
earth).

### Columns

| Step | Formula |
| --- | --- |
| Volume | count × width × depth × height × (1 + waste) [5%] |
| Cement (main item), sand, gravel | as for slabs, Class A by default |
| Main bars | count × bars per column [4; 4, 6, 8 or 12] pieces, each height + lap long, in 12–25 mm [16] |
| Ties, 10 mm | per column ⌊height ÷ spacing⌋ + 1 [0.15 m; 0.10, 0.15 or 0.20]; each 2 × (width − 0.08) + 2 × (depth − 0.08) + 2 × 0.105 m |
| Tie wire | count × ties × main bars × 0.30 m ÷ 53 |
| Forms | contact area = count × (2 × (width + depth) + 0.20) × height; reused 3 times by default |

The 0.20 m in the form area is Fajardo's lap allowance. Columns with 6 or more
bars also need cross ties, which are not counted.

Sources: Fajardo Table 1-2 and forms tables; NSCP 2015 Sec. 425.3 and Table
420.6.1.3.1.

### Beams

| Step | Formula |
| --- | --- |
| Volume | count × width × depth × clear span × (1 + waste) [5%] |
| Cement (main item), sand, gravel | as for slabs, Class A by default |
| Main bars | count × bars per beam [4; 4, 5, 6 or 8] pieces, each span + 2 × 12d long (a 90° hook into each column), in 12–25 mm [16] |
| Stirrups, 10 mm | per beam ⌊span ÷ spacing⌋ + 1 [0.15 m]; each 2 × (width − 0.08) + 2 × (depth − 0.08) + 2 × 0.105 m |
| Tie wire | count × stirrups × main bars × 0.30 m ÷ 53 |
| Forms | contact area = count × (2 × depth + width + 0.10) × span; reused twice by default |

Forms cover both sides and the bottom. Extra bars over the supports and
shoring posts are not counted.

Sources: Fajardo forms tables; NSCP 2015 Sec. 425.3 and Table 420.6.1.3.1.

### Plywood

| Step | Formula |
| --- | --- |
| Sheets | ⌈length × width ÷ 2.977⌉ |
| Waste | + ⌈sheets × waste⌉ [10%; none, 5, 10 or 15%] |

Thickness (6, 9, 12 or 18 mm [12]) and grade (ordinary or marine) set the
price, not the count.

Source: [Filtra Timber plywood brochure](https://www.filtratimber.com/brochure/pdf/plywood-presentation-2025.pdf).

### Ceiling

| Step | Formula |
| --- | --- |
| Boards | ⌈area ÷ 2.977⌉ + waste [10%] |
| Hangers | ⌈area ÷ 1.44⌉ (one per 1.2 × 1.2 m) |
| Metal furring, 5 m | ⌈area × 2.5 × 1.05 ÷ 5⌉ (furring every 0.40 m, 5% for laps) |
| Carrying channel, 5 m | ⌈area × 0.833 × 1.05 ÷ 5⌉ (every 1.2 m) |
| Wall angle, 3 m | ⌈perimeter ÷ 3⌉ |
| Hanger wire, #10 | hangers × 0.071 kg (about 1 m each) |
| Wood framing instead | 2" × 2" S4S lumber (area × 4.56 + hangers × 1.094) × 1.05 bd ft; nails area × 0.08 kg |
| Board screws | ⌈area × 14 × 1.05 ÷ 100⌉ boxes of 100 |

The board is fiber cement 4.5 mm or gypsum 9 mm [fiber cement]; framing is
metal or wood [metal]. A 0.40 × 0.60 m wood grid takes 4.17 m of 2" × 2" per
m², which is 4.56 board feet. About 14 screws per m² puts one every 20 cm
along each furring.

Sources: James Hardie Philippines HardieFlex ceiling installation guide;
[AEDO ceiling costs](https://aedoconstruction.com/blog/ceiling-installation-repair-cost-philippines/);
CvSU and PCC ceiling bid documents for the 5 m and 3 m lengths; a CatSU scope
of works and a Cebu method statement for the spacing. The screw count and the
wood grid are derived.

### Foam insulation

| Step | Formula |
| --- | --- |
| Slope length | rafter × pitch factor √(1 + (rise ÷ run)²) |
| Strips per side | ⌈roof length ÷ 0.95⌉ (1 m rolls, 50 mm taped lap) |
| Rolls | ⌈strips × (slope + 0.05) × sides × 1.05 ÷ roll length⌉ |
| Foil tape | ⌈(strips − 1) × (slope + 0.05) × sides ÷ 50⌉ rolls |

Rolls are 1 × 50 m or 1 × 25 m [50 m]. Sides are 1 or 2 [2]. The rafter is
measured along the slope [default], or on the plan with a pitch: 3:12
1.031, 4:12 1.054, 6:12 1.118, 8:12 1.202, 12:12 1.414. Thickness and foil
describe the item only.

Sources: [Lazada PE foam listing](https://www.lazada.com.ph/products/pe-foam-insulation-10mm-double-sided-1meter-x-50meter-i276479065.html),
[roofonline pitch factors](https://roofonline.com/roof-pitch-factor/).

## Architectural

### Paint

| Step | Formula |
| --- | --- |
| Area | (length × height − doors and windows) × faces [1] |
| Litres | area × coats [2] ÷ (coverage ÷ 4) × 1.10 |
| Gallons (main item) | ⌈litres ÷ 4⌉ |
| Primer [on] | area ÷ (25 ÷ 4) × 1.10 litres, in 4 L gallons |
| New masonry | neutralizer area ÷ 85 L; spot putty area ÷ 25 gallons |
| Skim coat, new masonry [none; 1 or 2 coats] | area × coats ÷ 18 bags of 20 kg |
| Sandpaper | ⌈area × passes ÷ 8⌉ sheets |
| Thinner (enamel) | (enamel litres + primer litres) ÷ 8 + 0.5 L |

A Philippine paint "gallon" is **4 litres**. Coverage per 4 L per coat is
30 m² for latex flat and semi-gloss and 25 m² for enamel, the low end of
Boysen's ranges, since rough walls take more paint. The surface is a
repaint, new masonry or wood and metal [new masonry]. Sanding passes are one
for the putty plus one per skim coat on masonry, one on bare wood or metal,
and none for a repaint.

Neutralizer coverage is derived from Boysen B-44: 1 L mixed 1:16 makes 17 L
of solution at about 20 m² per 4 L. The 8 m² per sandpaper sheet and the
one-eighth thinner share are planning defaults, not published figures.

Sources: [Boysen Permacoat](https://www.boysen.com.ph/products/boysen-permacoat-latex),
[Boysen Quick Drying Enamel](https://www.boysen.com.ph/products/boysen-quick-drying-enamel),
[Boysen B-44](https://www.boysen.com.ph/products/boysen-masonry-neutralizer-b-44),
[Boysen B-7311](https://www.boysen.com.ph/products/boysen-masonry-putty-b-7311/),
[SikaWall-110 data sheet](https://phl.sika.com/dms/getdocument.get/ba888e31-3994-4be5-a054-99e013c85dff_ph01/pds-sikawall-110superfineskimcoat.pdf).

### Tiles

| Step | Formula |
| --- | --- |
| Tiles in rows | ⌈length ÷ a⌉ × ⌈width ÷ b⌉, trying both orientations and keeping the smaller |
| Skirting tiles | ⌈skirting ÷ metres per tile⌉; metres per tile = a × ⌊b ÷ 0.10⌋ (the better way round) |
| Waste | + ⌈(rows + skirting) × waste⌉ [10% straight, 15% diagonal] |
| Boxes | ⌈total ÷ tiles per box⌉ |
| Bed area | floor area + skirting × 0.10 |
| Adhesive [default] | ⌈bed area × kg per m² ÷ 25⌉ bags; 3 kg/m² if the longest side is up to 30 cm, else 5 kg/m² |
| Or mortar bed | cement bed area × (0.025 × 12 + 0.025) × 1.05 bags; sand bed area × 0.025 × 1.05 m³ |
| Grout | bed area × (a + b) ÷ (a × b) × 3 × depth × 1.6 kg, in 2 kg packs (sides and depth in mm) |
| Spacers | ⌈total × 1.5 ÷ 100⌉ packs |

Sizes: 20 × 20, 20 × 30, 30 × 30, 30 × 60, 40 × 40 and 60 × 60 cm. There is no
default size; you must pick one. Tiles per box default to 25, 17, 16, 8, 6
and 4, or you can type the number on your box. Tiles are bought by the piece
[default] or by the box; the main item and price follow that choice. Grout
fills 3 mm joints as deep as the tile: 8 mm up to 30 cm, 10 mm above. The
mortar bed is 25 mm of Class B mortar plus 0.025 bags per m² of neat cement
for the slurry, with 5% waste.

Bostik's data sheet gives about 3 kg/m² with a 6 mm trowel and 6 kg/m² with
12 mm; 5 kg/m² for large tiles is a default between them. The 10 cm skirting
height and 1.5 spacers per tile are common practice, not standards.

Sources: [Wilcon tiles](https://shop.wilcon.com.ph/tiles),
[Bostik Fixall data sheet](https://www.bostik.com/files/live/sites/shared_bostik/files/import-philippines/bostik-fixall-excel-tds-fa-rev1.pdf),
[Philconprices tiling factors](https://philconprices.com/tag/tiling-work-per-square-meter/)
(0.325 bags and 0.026 m³ per m², which agrees with the mortar bed),
[Walls and Floors spacers](https://wallsandfloors.co.uk/blog/how-to-use-tile-spacers).

### Roofing sheets

| Step | Formula |
| --- | --- |
| Slope | rafter × pitch factor (gable or shed); width ÷ 2 × √(1 + p²) (hip) |
| Corrugated GI | ⌈roof length ÷ cover⌉ × rows × sides; rows = 1 if the slope fits one sheet, else ⌈(slope − 0.25) ÷ (sheet length − 0.25)⌉ |
| Long-span, by the metre | ⌈roof length ÷ cover⌉ × sides sheets, each slope + 0.05 m |
| Hip roof | area = length × width × √(1 + p²); ridge = length − width; hips = 4 × width ÷ 2 × √(2 + p²); counted as a gable, + 10% |
| Purlins (optional) | lines = ⌈slope ÷ spacing⌉ + 1 [0.60 m]; purlins = lines × ⌈roof length ÷ 5.8⌉ × sides |
| Tek screws | roof area × 8 (corrugated) or × 7 (long-span) |
| Ridge and hip roll, 2.4 m | ⌈(ridge + hips) ÷ 2.25⌉ |
| Gutter (optional) | metres of eaves; downspouts ⌈eaves ÷ 10⌉ × height [3 m], in metres |

Corrugated sheets are 0.80 m wide and cover 0.70 m with a 1½ corrugation side
lap [default] or 0.60 m with 2½. They come 5 to 12 ft long [8 ft], with a
0.25 m end lap. Long-span sheets cover 1.00 m [default], 1.07 m or 0.98 m and
are sold per metre. The roof shape is gable [default], shed or hip; for a hip
roof enter the plan length and width with the overhangs and the pitch [4:12].
C-purlins are 2" × 4", 6 m long, and cover 5.8 m once joined over a truss.

The four faces of a hip roof add up to a gable of the same plan and pitch,
so sheets and purlins are counted that way; the 10% covers the diagonal cuts.
Screws per m², the ridge roll length and lap, and one downspout per 10 m are
derived or general rules of thumb, not PH manufacturer data.

Sources: [Union Galvasteel Durarib](https://www.ugc.ph/product/durarib/),
[Multi-rib8](https://www.ugc.ph/product/multi-rib8/),
[roofonline pitch factors](https://roofonline.com/roof-pitch-factor/),
[AEDO gutters](https://aedoconstruction.com/blog/roof-gutter-downspout-cost-philippines/),
a DPWH Iloilo plan for 0.60 m purlins.

### Doors

| Door [interior] | Set | Hinges per door | Lockset per door |
| --- | --- | --- | --- |
| Interior flush, 0.80 × 2.10 m | door with jamb | 3 × 3½" | 1 privacy lockset |
| Main entrance panel, 0.90 × 2.10 m | door with jamb | 4 × 4" heavy | 1 entrance lockset |
| Bathroom PVC, 0.70 × 2.10 m | door with jamb | come with the set | 1 privacy lockset |

Sets = number of doors. Paint or varnish is not included. The sizes and
hardware counts are common practice; no source was checked for them.

Sources: [BP 344](https://www.officialgazette.gov.ph/1983/02/25/batas-pambansa-blg-344/)
(accessible doors).

### Windows

| Step | Formula |
| --- | --- |
| Area (main item) | width × height × windows, rounded up to 0.01 m² |
| Sealant | ⌈2 × (width + height) × windows × 2 ÷ 7⌉ tubes of 300 ml |

The window type describes the item only. Fabricators quote per square foot;
multiply a price per ft² by 10.764 for the price per m². Sealant goes on both
sides of the frame, about 7 m per tube. The National Building Code asks for
window openings of at least 10% of the floor area in rooms without air
conditioning.

Sources: [PD 1096](https://www.officialgazette.gov.ph/1977/02/19/presidential-decree-no-1096/).
The sealant rate and window sizes are common practice, not checked against a
source.

### Carpet

| Step | Formula |
| --- | --- |
| Drops | ⌈room width ÷ roll width⌉, each room length + 0.10 m, trying both directions and keeping the one that needs less |
| Carpet (main item) | drops × drop length × roll width m², to 0.1 m² |
| Underlay | area × 1.05 m² |
| Gripper | 2 × (length + width) m |
| Seam tape | (drops − 1) × drop length m |
| Carpet tiles instead | ⌈area × 1.05 ÷ 0.25⌉ tiles, in boxes of 20 |

Broadloom comes off 4 m [default] or 3.66 m rolls and is sold per m². Carpet
tiles are 50 × 50 cm and have no companions. Gripper is not reduced for
doorways.

Sources: [JS Wallmatrix carpet prices](https://jswallmatrix.com/products/carpets/carpet-roll/price-list-philippines).

### Wallpaper

| Step | Formula |
| --- | --- |
| Width to cover | wall width − doors to skip |
| Strip | height + 0.10 m, rounded up to whole pattern repeats |
| Strips per roll | ⌊roll length ÷ strip⌋ |
| Rolls | ⌈⌈width ÷ roll width⌉ ÷ strips per roll⌉ |
| Waste | + ⌈rolls × waste⌉ [none; 10 or 15%] |
| Paste | ⌈rolls × roll area ÷ 5.33 ÷ 5⌉ packs of 200 g |

Rolls: 0.53 × 10.05 m standard [default], 1.06 × 15.6 m jumbo, 0.45 × 10 m.
Pattern repeat: none [default], 32, 53 or 64 cm. One pack of paste hangs
about 5 standard rolls; a jumbo roll counts as about 3. Self-adhesive rolls
need no paste.

Source: [Screwfix wallpaper guide](https://www.screwfix.com/guides/painting-decorating/wallpaper/how-much-wallpaper-do-i-need).

## Electrical

### Light bulbs

| Step | Formula |
| --- | --- |
| Light needed | lux × room length × width |
| Bulbs | ⌈light needed ÷ (bulb lumens × 0.5)⌉ |
| Lamp holders | bulbs |
| Junction boxes | bulbs (room size only) |

Room: bedroom 100 lx, living room 150 [default], bathroom 200, kitchen 300,
study 500. LED bulbs, E27: 5 W 480 lm, 7 W 650, 9 W 880 [default], 12 W
1,200, 15 W 1,500, 18 W 1,800. You can also enter a number of bulbs, which
adds lamp holders only. The 0.5 light-loss factor (utilisation × maintenance)
is a planning value.

Sources: [Engineering ToolBox light levels](https://www.engineeringtoolbox.com/light-level-rooms-d_708.html),
[LRC LED lighting guide](https://www.lrc.rpi.edu/programs/solidstate/assist/pdf/led-lighting-apps-guide-2002.pdf).

### Switches

Switches = the number entered. Each takes one 2" × 4" utility box and one
switch plate. The type (1, 2 or 3 gang, 3-way) describes the item only. A
stair or long hall needs a pair of 3-way switches.

Source: [PEC 2017 Art. 2.10](https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits)
(secondary transcription).

### Junction boxes

Boxes = the number entered: one per ceiling light and one at every splice.
Octagonal or square 4" × 4" describes the item only. No companions.

### Outlets

| Step | Formula |
| --- | --- |
| Wall | 2 × (length + width) − doorway widths |
| Outlets | ⌈wall ÷ 3.6⌉ |
| Utility boxes | outlets |

No point along a wall may be more than 1.8 m from an outlet, so one outlet
serves 3.6 m of wall (PEC 2.10.3.3, which follows NEC 210.52). Kitchen
counters need one outlet per 1.2 m, which this rule does not count. You can
also enter a number of outlets.

Source: [PEC 2017 Art. 2.10](https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits)
(secondary transcription).

### Electrical wire

| Step | Formula |
| --- | --- |
| Wire | circuit length × wires × 1.10 |
| Boxes (main item) | ⌈wire ÷ 150⌉ boxes of 150 m, or ⌈wire⌉ m cut from the reel |
| Conduit, ½" | ⌈circuit length × 1.10 ÷ 3⌉ lengths of 3 m |

THHN sizes: 2.0 mm² for 15 A lights, 3.5 mm² [default] for 20 A outlets,
5.5 mm² for 30 A aircon, 8.0 mm² for feeders. Wires per circuit: 2, or 3
with a ground [3]. The 10% covers bends and slack at every box.

Sources: [Phelps Dodge FAQ](https://phelpsdodge.com.ph/frequently-asked-questions/),
[PEC 2.40.1.4(D) summary](https://open-exam-prep.com/study-guides/ph-prc-electrical-engineering/pec1-safety-sizing-protection/overcurrent-protection-branch-feeder-design).

### Utility boxes

Boxes = the number entered: one per switch and outlet location. Flush or
surface mounting describes the item only. No companions.

### Electrical rough-in

The whole-house calculator. The main item is the panel board; everything
else is a companion.

| Step | Formula |
| --- | --- |
| Switches | as entered, or ⌈lights ÷ 2⌉ |
| Lighting circuits, 15 A, 2.0 mm² | ⌈lights ÷ 8⌉ |
| Outlet circuits, 20 A, 3.5 mm² | max(⌈outlets ÷ 6⌉, 2), plus 1 laundry circuit |
| Aircon circuits | one per unit: 20 A on 3.5 mm² up to 1 HP [default], 30 A on 5.5 mm² for 1.5–2.5 HP |
| Other appliance circuits | one 20 A, 3.5 mm² circuit each |
| Panel | spaces = ⌈circuits × 1.25⌉, rounded up to 4, 6, 8, 12, 16, 20, 24 or 30 branches |
| Conduit per point | 5 m + 1.5 m per storey above the first [1 storey] |
| Conduit run | points × conduit per point + circuits × home run [10 m] |
| Conduit, ½" | ⌈run × 1.10 ÷ 3⌉ lengths |
| Wire, each size | that size's conduit run × 3 wires × 1.10; whole 150 m boxes, plus 1 box if 100 m or more is left, else the rest by the metre |
| Utility boxes | switches + outlets + aircons + appliances |
| Junction boxes | lights |
| Devices | switches and plates; outlets + appliances; one aircon outlet per aircon |
| Breakers | one per circuit at its rating |
| Ground rod, tape | 1 rod set; ⌈circuits ÷ 4⌉ rolls of tape |

Points are lights and switches on lighting circuits, outlets on outlet
circuits, and one per aircon or appliance circuit. The laundry circuit has a
home run only, because its outlet is counted with the outlets. A chosen
panel size must hold at least the circuits; Auto picks the smallest panel
with 25% spare.

On Auto, the price field suggests the price of a 12-branch panel whatever
size is picked; pick the size to get its own price.

PEC 2.40.1.4(D) caps 2.0 mm² at 15 A, 3.5 mm² at 20 A and 5.5 mm² at 30 A.
The rest is practice, not code: the PEC sets no outlet count per circuit (it
counts load, 180 VA per receptacle), and 8 lights and 6 outlets per circuit,
5 m of conduit per point and 25% spare are planning defaults. Two
small-appliance circuits and a laundry circuit follow NEC 210.11(C), which
the PEC mirrors. The service entrance, meter base, main feeder and load
calculation are not included. A licensed electrical engineer must design and
sign the plans.

Sources: [PEC 2017 Art. 2.10](https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits),
[PEC 2.40.1.4(D) summary](https://open-exam-prep.com/study-guides/ph-prc-electrical-engineering/pec1-safety-sizing-protection/overcurrent-protection-branch-feeder-design),
[residential design lecture](https://pdfcoffee.com/lecture-11-electrical-system-design-residential-pdf-free.html),
[Phelps Dodge FAQ](https://phelpsdodge.com.ph/frequently-asked-questions/),
[AEDO rewiring costs](https://aedoconstruction.com/blog/house-rewiring-cost-philippines/).

## Plumbing

### PVC pipe

| Step | Formula |
| --- | --- |
| Pipes (main item) | ⌈run × 1.10 ÷ pipe length⌉ |
| Fittings | 0.40 × pipes × price per pipe, as one lot |
| Solvent cement (PVC only) | ⌈run × 1 joint per m ÷ joints per can⌉ cans of 100 cc |
| Teflon tape (½"–1" only) | ⌈pipes ÷ 10⌉ rolls |

Diameters: ½" [default], ¾" and 1" for water; 2", 3" and 4" for drains.
Water sizes come as 3 m PVC [default] or 4 m PPR, which is heat-fused and
needs no solvent cement. A 100 cc can makes 32 joints at ½", 21 at ¾", 13 at
1", 6 at 2", 4 at 3" and 3 at 4": Oatey's joints per quart, scaled to 100 cc.

The 40% fittings allowance comes from a single US contractor guide; count
fittings from your plan for a closer figure. One joint per metre and ten
pipes per teflon roll are planning defaults.

Sources: [Neltex](https://www.neltex.com/products.do?item_id=51663),
[Moldex](https://mpi.moldex.com.ph/mb-pipes-and-fittings),
[PVC glue guide](https://www.commercial-industrial-supply.com/resource-center/how-much-pvc-glue-to-use/),
[SimplyWise plumbing estimates](https://www.simplywise.com/blog/how-to-estimate-plumbing-job/).

### Sinks

| Per sink | Quantity |
| --- | --- |
| Lavatory set or kitchen sink (main item) | 1 |
| Angle valve, flexible hose | 1 each for cold only [default], 2 each for hot and cold |
| P-trap | 1 |

Lavatories are priced per set and kitchen sinks per piece. The type describes
the item only. Faucets are counted with the Faucet calculator. Some lavatory
sets come with a P-trap.

Source: [AEDO NPC drain sizing](https://aedoconstruction.com/blog/npc-drain-pipe-sizing-calculator-philippines/).

### Toilets

| Per toilet | Quantity |
| --- | --- |
| Toilet set, or squat bowl per piece (main item) | 1 |
| Angle valve, flexible hose | 1 each |
| Wax ring, closet bolt set | 1 each, not for squat bowls |

A squat bowl is set in mortar, so it needs no wax ring or bolts.

Source: [AEDO NPC drain sizing](https://aedoconstruction.com/blog/npc-drain-pipe-sizing-calculator-philippines/).

### Faucets

Faucets = the number entered. Teflon tape = ⌈faucets × 2 ÷ 40⌉ rolls: about
2 threaded joints per faucet and 40 per 10 m roll. The joints per roll are
derived, not published.

### Showers

Shower sets = the number entered. Each takes a shower valve and a floor
drain. Teflon tape = ⌈showers × 4 ÷ 40⌉ rolls, for about 4 threaded joints
each.

### Water tank

| Step | Formula |
| --- | --- |
| Storage | people × litres per day [150; 100 or 200] × days [1; 2 or 3] |
| Tanks (main item) | ⌈storage ÷ tank size⌉ [1,000 L; 500, 1,500 or 2,000] |
| Float valves | tanks |

150 L per person a day is AEDO's planning figure; LWUA uses about 140 L for a
household of 6. At least a day of storage is advised where supply is often
cut; AEDO cites NPC Chapter 6, which was not checked. The tank sizes are
assumed stock sizes.

Source: [AEDO water tank sizing](https://aedoconstruction.com/blog/npc-water-tank-cistern-sizing-calculator-philippines/).

### Septic tank

| Step | Formula |
| --- | --- |
| Capacity | max(table by bedrooms, people × 0.15 m³) |
| Polyethylene tanks | ⌈capacity ÷ 2⌉ tanks of 2,000 L |
| Block tank width | max(0.9, √(capacity ÷ 2.4)), rounded up to 5 cm |
| Block tank length | max(1.5, capacity ÷ (1.2 × width)), rounded up to 5 cm |
| Height | 1.2 m liquid + 0.3 m air = 1.5 m |
| Walls | (2 × (length + width) + 4 × 0.15) × 1.5 + width × 1.5 (baffle) |
| Blocks, 6" (main item) | ⌈walls × 12.5⌉ + 5% |
| Floor and cover slabs | 2 × (length + 0.30) × (width + 0.30) × 0.10 m³, Class A |
| Plaster, inside | 2 × (length + width) × 1.5 + 2 × width × 1.5 |
| Cement | slabs × 9 + walls × 1.018 + plaster × 0.192 bags |
| Sand, gravel | slabs × 0.5 + walls × 0.0844 + plaster × 0.016 m³; slabs × 1.0 m³ |
| Bars, 10 mm | each slab: ⌈side ÷ 0.20⌉ + 1 bars each way, the full slab length; walls: ⌈walls × 4.28 ÷ 6⌉ |
| Tie wire | slab crossings × 0.30 m ÷ 53 |

Capacity by bedrooms: 2.838 m³ for 1 or 2, 3.785 for 3, 4.542 for 4, 5.678
for 5 or 6, and 0.568 more per extra bedroom. Only the 1–2 bedroom figure was
confirmed as NPC Table B-2 (via AEDO). The larger figures follow the UPC
table the NPC is based on and are not confirmed in the NPC. 0.15 m³ per
person comes from a secondary source that gives 0.14–0.17. The baffle sits
two thirds of the length from the inlet, and the NPC minimum inside size is
1.5 × 0.9 m (from course slides on the 1959 code). The 2,000 L polyethylene
tank is an assumed size; check it with the supplier. Keep the tank at least
15 m from any well.

Sources: [AEDO septic sizing](https://aedoconstruction.com/blog/septic-tank-sizing-philippines-npc/),
[Ventura County septic criteria](https://www2.vcrma.org/wp-content/uploads/2024/02/septic-tank-criteria-single-family-dwellings.pdf),
[per-person sizing](https://www.scribd.com/document/542099418/std),
[plumbing slides](https://www.slideshare.net/slideshow/plumbing-1ppt/262234425).

## Accuracy and validation

### How the tests check the formulas

Each calculator is tested with hand-worked examples: the expected numbers are
worked out by hand in the test comments, then compared with what the app's
own `calculate` function returns.

- [`test/materials/structure_test.dart`](../test/materials/structure_test.dart):
  blocks, plywood, insulation, ceiling, bar cutting, slabs, footings, columns
  and beams.
- [`test/materials/architectural_test.dart`](../test/materials/architectural_test.dart):
  paint, tiles, roofing, carpet, wallpaper, doors and windows. It also runs
  every option of every architectural calculator and checks that each one
  calculates and is priced from its own price book item.
- [`test/materials/mep_test.dart`](../test/materials/mep_test.dart): bulbs,
  switches, boxes, outlets, wire, rough-in, pipe, fixtures, water and septic
  tanks. It also checks that no definition or solution text says companions
  are left out of the cost.
- [`test/materials/calculators_test.dart`](../test/materials/calculators_test.dart):
  the catalog of 29, one price field for every option, plain inputs for every
  calculator, rounding noise (a 6 m² wall needs 75 blocks, not 76) and totals
  to the centavo.

Some of the hand-worked cases:

| Case | Expected |
| --- | --- |
| 10 × 3 m wall of 4" CHB, defaults | 394 blocks, 28 bags, 2.5 m³ sand, 22 bars of 10 mm, 1 kg tie wire |
| Slab on fill 10 × 5 × 0.10 m | 40 bags (Class B), 3 m³ sand, 5.5 m³ gravel, 5 m³ bedding, 48 bars, 2 kg tie wire |
| 4 columns 0.30 × 0.30 × 3 m | 11 bags, 16 bars of 16 mm, 17 bars of 10 mm, 2 plywood sheets, 41 bd ft, 4 kg nails |
| Latex on 10 × 3 m new masonry | 3 gallons, 2 gallons primer, 1 L neutralizer, 2 gallons putty, 4 sheets sandpaper |
| 5 × 4 m floor, 60 × 60 cm tiles | 70 tiles (18 boxes), 4 bags adhesive, 2 packs grout, 2 packs spacers |
| Gable roof 10 m × 4 m rafter, 8 ft corrugated | 60 sheets, 640 tek screws, 5 ridge rolls |
| Two-storey rough-in: 12 lights, 14 outlets, 2 aircons, 1 heater | 9 circuits, 12-branch panel, 117 conduit lengths, 3 boxes + 3 m of 2.0 mm², 4 boxes of 3.5 mm² |
| Block septic tank, 3 bedrooms | 2.45 × 1.30 × 1.50 m inside, 186 blocks, 26 bags, 2 m³ sand, 1 m³ gravel, 30 bars, 2 kg tie wire |

The tests show that the code does what these formulas say. They do not show
that a factor is right for your site.

### Known limitations

- **Plans come first.** Bar sizes, spacing, laps, concrete classes, member
  sizes, tank sizes and circuits are defaults. They must follow the signed
  structural, electrical and plumbing plans. BuildQuantify is not a design
  tool.
- **Not counted:** cross ties in columns with 6 or more bars; extra bars over
  beam supports; shoring posts; scaffolding; hooks or anchorage of slab bars
  into beams; kitchen-counter outlets; the electrical service entrance; pipe
  fittings by count (an allowance is used instead); paint or varnish on doors.
- **Bars.** Offcuts are not reused, which slightly overstates short bars. The
  40 d lap suits Grade 33–40 bars; Grade 60 bars need about 57 d in tension.
  Column and beam tie wire uses 0.30 m per crossing, sized on the 10 mm tie,
  although footings use 0.40 m for bars over 12 mm. 10 mm bars at 0.40 m on a
  slab on fill pass the minimum steel ratio but exceed the 0.30 m maximum
  spacing for a structural 100 mm slab, so they suit only a non-structural
  slab on grade.
- **Concrete classes** are Fajardo's site-mix classes by volume, not the DPWH
  classes, which are set by strength.
- **Hip roofs** are counted as a gable plus 10%. Purlins on the triangular
  ends are overstated.
- **PEC caveats.** The PEC wording was read through secondary transcriptions
  (the filipinoengineer.com wiki and exam-prep notes), not the official text.
  Circuit counts per breaker are practice; the PEC sets limits by load.
- **NPC caveats.** Only the 1–2 bedroom septic size was confirmed as NPC
  Table B-2; larger sizes follow the UPC. The minimum tank size and chamber
  split come from course slides on the 1959 code. Water use per person and
  days of storage are planning figures.
- **Doors and windows.** Sizes, hinge counts and the sealant rate are common
  practice that no source was found for.
- **Shopping list.** Each estimate rounds its companions up on its own, so a
  project's merged list can hold a little more than one combined purchase
  would (two 0.4 kg tie-wire needs become 2 kg).
- **Source quality.** The Fajardo factors were checked against student
  uploads, not the book. AEDO is a contractor's blog. The research was done
  in October 2026 from search excerpts, because most source sites could not
  be opened directly. Light loss (0.5), allowances (5–10%) and reuse counts
  are typical planning values, not code requirements.
