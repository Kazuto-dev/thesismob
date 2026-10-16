# How BuildQuantify calculates

BuildQuantify has 40 calculators in four groups. Each one follows common
Philippine estimating practice and the sizes sold in Philippine hardware
stores. Quantities are planning estimates: confirm them with your supplier
and engineer before buying.

The formulas live in [`lib/materials/`](../lib/materials). Each calculator's
**Definitions** and **Solution** sheets in the app show the same formulas;
where a sheet and the code differ, this page follows the code. Default
prices and their sources are in [Prices and costing](prices-and-costing.md).

## How a result is built

**Main material.** Each calculator works out one main material, such as
blocks, bags of cement or gallons of paint. Its cost is quantity × the price
in the price field. The price field is filled from the price book (see
[Prices and costing](prices-and-costing.md)); type your supplier's price to
use it instead.

**Rounding.** Counts always round **up**, because you cannot buy 0.3 of a
block. Rounding ignores floating-point noise, so 30 ÷ 0.08, which a
computer works out as 375.00000000000006, counts as 375. A waste allowance
is rounded up on its own and added: total = count + ⌈count × waste⌉.
Costs are quantity × unit price, rounded to the centavo.

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
| Tie wire, #16 GI | 0.30 m per crossing for bars up to 12 mm, 0.40 m for larger; 53 m per kg | 20–40 cm per tie is from PH course notes in Fajardo's wording. 53 m/kg is widely quoted as Fajardo but not confirmed. #16 wire runs about 60 m per kg, so 53 includes some waste. |
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

**Uses.** Forms are bought once and shared by the pours they serve, so each
estimate pays 1 ÷ uses of the plywood and lumber (once, 2, 3 or 4 times).
Contractors reuse the same plywood and frame lumber 3 or 4 times on a house:
column forms are reused for the next columns, then cut into beam sides and
slab soffits. The defaults are 3 uses for footings, wall footings, columns,
suspended slabs, slab and pavement edges, and lintels; 2 for beams, whose
soffits stay shored until the slab above has cured, and for stairs, whose
forms are cut to the steps. Nails are bought new for every use.

At the default price book and crew (formwork: 0.1 foreman, 1 skilled worker
and 1 helper at ₱1,400, ₱1,100 and ₱900 a day, 9 m² a day, ₱237.78 per m² of
labour), a suspended slab 10 × 7 m now costs ₱524 per m² of forms (₱1,003 when
it defaulted to a single use), beams ₱571 (2 uses, slab on both sides), stairs
₱664 (₱1,065 when used once), footing sides ₱503 and columns ₱461. Published
Philippine formwork rates for houses run about ₱500–800 per m² with labour;
the reuse factor of 3–4 is the usual rule in Philippine estimating guides
(Fajardo) and in contractors' practice, not a measured figure.

## Structural

### Concrete hollow blocks (CHB)

| Step | Formula |
| --- | --- |
| Area | length × height − doors and windows |
| Blocks | ⌈area × 12.5⌉ |
| Waste | + ⌈blocks × waste⌉ [5%; none, 5, 10 or 15%] |
| Cement for laying | area × mortar bags |
| Sand for laying | area × mortar sand m³ |
| Cement for plaster | area × faces × 0.192 bags |
| Sand for plaster | area × faces × 0.016 m³ |
| Bars, 10 or 12 mm [10] | ⌈area × (vertical + horizontal) ÷ 6⌉ |
| Tie wire | area ÷ vertical spacing ÷ (courses × 0.20) crossings × 0.30 m ÷ 53 m per kg |

Block size is 4", 6" or 8" [4"]; it sets the mortar factor and the price.
Plaster is none, one face or both faces [both]. Laying and plaster are bought
as separate lines, each rounded up on its own (cement to the bag, sand to the
half m³). The laying lines stay with the wall's work item and the plaster
lines go to `plaster`, so the unit price analysis of each carries its own
materials: for a 6" wall 40 × 3 m less 12 m² of openings, the wall's direct
cost went from ₱1,161 to ₱1,019 per m² and the plaster's from ₱164 (labour
only) to ₱235 per m² of face. The septic tank and catch basins keep their
plaster in one line, since each is one composite work item. Bar per m² of wall, laps
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
| Forms (suspended) | soffit = length × width; plywood, lumber at 28.8 bd ft per sheet, nails |
| Edge forms (on fill) | edge × thickness; edge = 2 × (length + width), or the edge entered; lumber at the column factor per sheet; none when "poured against beams or walls" is chosen |
| Uses | shared by 3 uses by default [once, 2, 3 or 4] |

A slab is **on fill** or **suspended**. The usual mix is Class B on fill and
Class A suspended; any class can be picked. The usual bar spacing both ways
is 0.40 m on fill and 0.20 m suspended; 0.15 to 0.40 m or no bars can be
picked. Cover is 40 mm on fill and 20 mm suspended. A slab on fill is formed
along its free edges, as high as it is thick; enter only the free edges where
the slab is poured against a tie beam, a wall footing or a wall, or choose no
edge forms. The price field is the price per bag of cement.

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
| Side under a slab | depth − slab thickness [100 mm; 100, 125 or 150 mm]; slab on both sides by default [none, one side or both sides] |
| Forms | contact area = count × (two sides + width + 0.10) × span; reused twice by default |
| Tie beam forms | count × (2 × depth + 0.10) × span (no bottom) |
| Tie beam excavation | count × span × (width + 2 × working space) × (depth + bed) [space 0.30 m; none, 0.30 or 0.50; bed 0.05 m; none, 0.05, 0.10 or 0.15] |
| Tie beam gravel bed, backfill | count × span × width × bed; excavation − concrete − bed |

Forms cover both sides and the bottom. Where a slab rests on the beam, the
slab's soffit forms close the top of that side, so the side form only reaches
the underside of the slab: outer beams carry the slab on one side, inner beams
on both, roof beams on none. The concrete is still the full depth; measure the
slab between the beams to avoid counting the overlap twice. Extra bars over the
supports and shoring posts are not counted.

A leading choice makes the beam a **tie beam at ground level** (a grade
beam linking footings or column bases). It is cast in a trench as deep as the
beam and its gravel bed, with working space each side, formed on both sides
but not underneath; whatever the beam and bed do not fill is backfilled.
Its concrete is the new `concrete_tie_beam` work item (same crew as beams,
0.5 foreman, 1 skilled, 4 helpers, a mixer and a vibrator; 4 m³ a day like
footings, since it is cast at grade without shoring; DPWH 900), with
excavation, backfill and gravel bedding as works. Leave its trench out of
Earthworks.

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

### Earthworks

| Step | Formula |
| --- | --- |
| Pit | (length + 2 × working space) × (width + 2 × working space) × depth; working space none, 0.30 or 0.50 m each side [0.30] |
| Excavation (in place) | count × pit |
| Gravel bed (optional) | count × length × width × thickness [none; 0.05 or 0.10 m], under the footing only |
| Backfill | excavation − structure below ground − gravel bed; none when "haul all of it away" is chosen |
| Excess in place | excavation − backfill |
| Loose soil to haul (main item) | excess × swell [common soil 1.25; hard soil or soft rock 1.40], rounded up to 0.5 m³ |
| Truckloads (shown only) | ⌈loose soil ÷ 6 m³⌉ for a 6-wheeler |

Length and width are the footing's or wall footing's own size; the working
space is added around it. Depth runs from the ground to the bottom of the pit,
gravel bed included. A leading choice sets what happens to the soil:
**backfill around the structure** (default; then the volume of the structure
below ground, in m³ for all pits, is required: footings, wall footings, tie
beams and column stubs below the ground line) or **haul all of it away** (a
cistern or septic pit). The structure plus the gravel bed must fit in the
excavation. The price field is the price per m³ of loose soil hauled away
(`soil_disposal`). Backfill is counted at the volume it fills; the slight
shrinkage of compacted backfill is not counted, so a little less soil may be
left over than shown.

Works: excavation in m³ (common soil `excavation`, DPWH 103, 3 m³ per
helper-day; hard soil the new `excavation_hard`, 1.5 m³ per day with the same
crew of 0.1 foreman and 1 helper), backfill in m³ when there is any, and
gravel bedding in m³ when chosen.

Sources: DPWH Standard Specifications, Item 103 (Structure Excavation) and
Item 104 (Embankment); swell of about 25% for common earth and 40% for hard
clay from R. L. Peurifoy et al., *Construction Planning, Equipment, and
Methods* (soil load-factor tables). 1.40 is applied to hardpan and soft rock
dug by hand; blasted rock swells more (about 50–65%). The 6 m³ load of a
6-wheeler is a common rule of thumb, not a published figure.

### Concrete stairs

| Step | Formula |
| --- | --- |
| Risers | ⌈height ÷ riser⌉ [riser at most 0.175 m; 0.175, 0.18 or 0.20], all equal: height ÷ risers |
| Treads | risers − 1; risers − 2 with one landing [none], which takes a tread's place |
| Slope length | √((treads × tread)² + height²) [tread 0.25 m; 0.25, 0.275 or 0.30] |
| Volume | slope × width × waist + ½ × riser × tread × width × treads + landing × width × waist [waist 0.15 m; 0.125, 0.15 or 0.20] |
| Cement (main item), sand, gravel | volume × (1 + waste) [5%; 0, 5 or 10%] × mix factors, Class A by default |
| Main bars, 10 or 12 mm [12] | ⌊(width − 2 × 0.02) ÷ spacing⌋ + 1 bars [0.15 m; 0.10, 0.125, 0.15 or 0.20], each slope + landing + 2 × 40d; spliced with a 40d lap over 6 m |
| Distribution bars, 10 mm at 0.25 m | ⌊(slope + landing) ÷ 0.25⌋ + 1 bars, each width − 0.04 m |
| Tie wire | main bars × distribution bars × 0.30 m ÷ 53 |
| Form area | (slope + landing) × width + height × width + 2 × volume ÷ width |
| Forms | marine plywood 6 or 12 mm [12] max(1, ⌈area ÷ 2.88 ÷ uses⌉) [2 uses; once, 2, 3 or 4]; coco lumber 28.8 bd ft per sheet; nails 0.20 kg/m² |

The risers' faces add up to height × width, and each side of the flight has
the profile area volume ÷ width. Main bars run along the slope into the
supports by 40 bar diameters at each end, a development-length rule of thumb
for Grade 33–40 bars. Cover is 20 mm, as for a suspended slab. The soffit
is shored like a suspended slab, so the slab's 28.8 bd ft of lumber per sheet
is used. Extra top bars at the supports, nosing bars and the beam or footing
at the foot of the stair are not counted. The price field is the price per bag
of cement.

Works: the new `stairs_concrete` in m³ (net, before waste; crew 0.5 foreman,
1 skilled, 4 helpers, a mixer and a vibrator; 2 m³ per day; DPWH 900), rebar in
kg (bar metres with laps × d² ÷ 162.2), formwork in m².

Sources: National Building Code (PD 1096), Rule XII Sec. 1207 (risers at most
0.20 m, treads at least 0.25 m); Fajardo Table 1-2 and forms tables; NSCP 2015
Table 420.6.1.3.1 (cover). The 2 m³ daily output is an estimate, below the
2.5 m³ of columns because of the stepped forms.

### Steel railing

| Step | Formula |
| --- | --- |
| Posts, 1½" × 1½" tube | bays = ⌈length ÷ spacing⌉ [1.2 m; 1.0, 1.2 or 1.5]; posts = bays + 1, each the railing height [1.00 m; 0.90, 1.00 or 1.10] |
| Top and bottom rails | 2 × length; the bottom rail sits 0.10 m above the floor |
| Infill height | height − 0.15 m |
| Balusters [default] | per bay ⌈(bay − 0.038 − gap) ÷ (gap + tube side)⌉ [gap 0.10 m; 0.10 or 0.12], each the infill height |
| Horizontal rails | ⌈(infill height − gap) ÷ (gap + tube side)⌉ middle rails, each the full length |
| Rail tube (main item), 1" or 1½" × 1.2 mm [1"] | ⌈metres × 1.05 ÷ 6⌉ lengths; posts are included when the tube is 1½" |
| Post tube | ⌈post metres × 1.05 ÷ 6⌉ lengths of 1½" tube, when the rail tube is 1" |
| Base plates, anchors | 1 plate 100 × 100 × 6 mm and 4 expansion anchors ⅜" × 3" per post |
| Welding rod | joints × 0.02 kg; joints = posts × (3 + middle rails) + 2 × balusters |
| Paint | area = rail and infill metres × 4 × tube side + post metres × 4 × 0.0381; red oxide primer 1 coat and enamel 2 coats at 25 m² per 4 L per coat, + 10%; thinner (primer + enamel) ÷ 8 + 0.5 L |

Infill can also be **none** (top and bottom rails only). The clear gap keeps
openings to about 10 cm so a child cannot slip through; this follows the
common 4-inch-sphere rule of building codes and good practice rather than a
specific NBCP clause. Each post counts one joint to its base plate and one to
every rail; each baluster two. 0.02 kg is about one 2.5 mm E6013 rod, enough
to weld round a 1" tube. The price field is the price per 6 m length of the
rail tube.

Works: the new `steel_railing` in m of railing (1 skilled welder, 1 helper and
a welding machine; 6 m per day; no DPWH item given) and painting in m² with
effort 3 (primer and two coats), which the paint companions go to.

Sources: tube dimensions as in ASTM A500 / PNS; mass worked out from the
section (1" × 1.2 mm ≈ 0.91 kg/m, 1½" × 1.2 mm ≈ 1.39 kg/m); paint coverage as
in the Paint calculator (Boysen data sheets).

### Steel roof trusses

| Step | Formula |
| --- | --- |
| Trusses | ⌊building length ÷ spacing⌋ + 1 [1.2 m; 1.0, 1.2 or 1.5] |
| Top chords | 2 × (span ÷ 2 + overhang) × √(1 + pitch²) [pitch 4:12; 3, 4, 5 or 6:12; overhang 0.60 m, measured level; none, 0.60, 0.80 or 1.00] |
| Bottom chord | span |
| Panels (Howe) | 2 × ⌈span ÷ 2 ÷ 1.2⌉; panel = span ÷ panels |
| Verticals | at panel point i (1 to panels ÷ 2): pitch × i × panel, twice except the king post |
| Diagonals | in panels 2 to panels ÷ 2 on each side: √(panel² + (pitch × i × panel)²) |
| Angle bar (main item), 1½" or 2" × 3/16" [1½"] | ⌈trusses × (top chords + bottom chord + webs) × 1.05 ÷ 6⌉ lengths |
| Gusset plates, 150 × 150 × 6 mm | 2 × panels per truss (one per joint) |
| Steel | angle metres × kg/m (2.68 or 3.63) + gussets × 1.06 kg |
| Welding rod | steel × 0.02 |
| Anchor bolts, 16 mm × 300 mm | 4 per truss (2 at each bearing) |
| Paint | area = angle metres × 4 × leg + gussets × 0.045 m²; red oxide primer 1 coat and enamel 1 coat at 25 m² per 4 L, + 10%; thinner as for the railing |

**Web basis.** Webs are worked out for a Howe truss with panels no wider than
1.2 m, a vertical at every panel point and a diagonal in every panel except
the two end panels, rather than as a fixed fraction of the chords. For an 8 m
span at 4:12 this gives 13.9 m of webs per truss, about 0.85 × the chords
between supports (16.4 m); at 3:12 the share is lower and at 6:12 higher. A
four-web Fink (W) truss of the same span uses about 40% as much web. All members are
counted in the chosen angle size; smaller web angles in the plans use a little
less steel. Angle weights are AISC nominal: L1½ × 1½ × 3/16 = 1.80 lb/ft
(2.68 kg/m; the 2.71 sometimes quoted is slightly high) and L2 × 2 × 3/16 =
2.44 lb/ft (3.63 kg/m). Welding rod at 2% of the steel weight is a rule of
thumb for light welded trusses with gussets, about 0.08 kg per joint at the
default. Purlins (in the Roofing calculator) and cross bracing are not counted.
**This is not a structural design:** member sizes, the web pattern,
connections and bracing must follow the engineer's plans. The price field is
the price per 6 m length of angle bar.

Works: the new `steel_truss` in kg of steel including gussets (0.2 foreman,
1 skilled welder, 2 helpers and a welding machine; 150 kg per day to fabricate
and erect; DPWH 1047) and painting in m² with effort 2.

Sources: AISC *Steel Construction Manual*, angle dimensions and weights; NSCP
2015 Chapter 5; DPWH Standard Specifications Item 1047 (structural steel; the
item number is recalled from program-of-works line items, not checked against
the specification text); paint coverage as in the Paint calculator.

#### New price book items: earthworks, stairs and steel

All prices are Metro Manila retail, VAT included, for late 2026. None could be
confirmed from a published source, so all are flagged as estimates.

| Item | Unit | Group | Price (₱) | Source |
| --- | --- | --- | ---: | --- |
| Hauling of excess soil, 6-wheeler truck (`soil_disposal`) | m³ | Other | 650 | Estimate: about ₱3,500–5,000 per 6 m³ trip in Metro Manila |
| Square steel tube 1" × 1" × 1.2 mm, 6 m (`square_tube_1`) | length | Steel | 400 | Estimate: 5.5 kg at about ₱70/kg for light tube |
| Square steel tube 1½" × 1½" × 1.2 mm, 6 m (`square_tube_1_5`) | length | Steel | 600 | Estimate: 8.3 kg at about ₱70/kg |
| Angle bar 1½" × 1½" × 3/16", 6 m (`angle_bar_1_5`) | length | Steel | 950 | Estimate: 16.1 kg at about ₱60/kg |
| Angle bar 2" × 2" × 3/16", 6 m (`angle_bar_2`) | length | Steel | 1,300 | Estimate: 21.8 kg at about ₱60/kg |
| Gusset plate 150 × 150 × 6 mm, cut (`gusset_plate`) | pc | Steel | 90 | Estimate: 1.06 kg of plate plus cutting |
| Base plate 100 × 100 × 6 mm, drilled (`base_plate`) | pc | Steel | 60 | Estimate: 0.47 kg of plate plus cutting and drilling |
| Expansion anchor ⅜" × 3" (`anchor_bolt_10`) | pc | Steel | 30 | Estimate (hardware listings ₱20–40) |
| Anchor bolt 16 mm × 300 mm, nut and washer (`anchor_bolt_16`) | pc | Steel | 90 | Estimate |
| Welding rod E6013, 2.5–3.2 mm (`welding_rod`) | kg | Steel | 200 | Estimate (5 kg boxes about ₱150–180/kg; loose by the kg more) |
| Red oxide metal primer, 4 L (`red_oxide_primer`) | gallon | Paint | 780 | Estimate (Boysen-class alkyd red oxide, ₱700–850) |

Reused items: cement, sand, gravel, gravel bedding, 10 and 12 mm bars, tie
wire, marine plywood, coco lumber, nails, quick-drying enamel and paint
thinner.

### Wall footings

| Step | Formula |
| --- | --- |
| Volume | length × width × thickness [0.20 m] × (1 + waste) [5%] |
| Cement (main item), sand, gravel | as for slabs, Class A by default |
| Cross bars, 10, 12 or 16 mm [12] at 0.15–0.30 m [0.20] | ⌊(length − 0.15) ÷ spacing⌋ + 1 bars, each width − 0.15 m |
| Lengthwise bars, 10, 12 or 16 mm [10] | 3, 4, 5 or 6 bars [4], each length − 0.15 m, spliced with the chosen lap [40d] over 6 m |
| Tie wire | cross bars × lengthwise bars × 0.30 m (0.40 m above 12 mm) ÷ 53 |
| Side forms (optional) | 2 × length × thickness; reused 3 times by default; lumber at the column factor |
| Excavation | length × (width + 2 × working space) × depth [space 0.30 m; none, 0.30 or 0.50] |
| Gravel bed | length × width × bed [0.10 m; none, 0.05, 0.10 or 0.15] |
| Wall below the ground | length × wall width × (depth − bed − thickness) [6" CHB, 0.15 m; 4" 0.10 or 8" 0.20] |
| Backfill | excavation − gravel bed − footing below the ground − wall below the ground |

A continuous strip under a wall; enter the runs of one size added up. Cover is
75 mm against the soil, as for isolated footings. The wall on the footing is
counted in the CHB calculator; here its part below the ground is only left out
of the backfill. Cross and lengthwise bars of one size are bought as one line.
Usual sizes (0.45–0.80 × 0.20–0.25 m, 12 mm cross bars at 0.20 m with 3–4
lengthwise 10 mm bars) are typical of Philippine house plans, not a code
requirement. The price field is the price per bag of cement.

Works: footing concrete (`concrete_footing`, as isolated footings), rebar,
formwork when chosen, gravel bedding, excavation and backfill. Leave the
trench out of Earthworks.

Sources: Fajardo Table 1-2; NSCP 2015 Table 420.6.1.3.1 (75 mm cover against
earth); DPWH Items 103 and 104.

### Lintels and stiffeners

| Step | Formula |
| --- | --- |
| Lintels | one per door and window, each opening width [door 0.9 m, window 1.2 m] + 2 × bearing [0.20 m; 0.15 or 0.20] |
| Sills | one per window [concrete sill, or none], as long as its lintel |
| Stiffener columns | ⌊wall length ÷ spacing⌋ [3.0 m; none, 2.4, 3.0 or 3.6], each the wall height |
| Volume | lintels × t × 0.20 + sills × t × 0.10 + stiffeners × t × 0.20 × height, t = 0.10, 0.15 or 0.20 m for 4", 6" or 8" blocks [4"]; × (1 + waste) [5%] |
| Cement (main item), sand, gravel | as for slabs, Class A by default |
| Bars, 10 or 12 mm [10] | 2 per lintel and stiffener in a 4" wall, 4 in 6" and 8" [usual; or 2 or 4]; lintels and sills their length, stiffeners height + lap; sills always 2 |
| Ties, 10 mm | per lintel and stiffener ⌊length ÷ spacing⌋ + 1 [0.20 m; 0.15, 0.20 or 0.25]; each 2 × (t − 0.05) + 2 × (0.20 − 0.05) + 2 × 0.105 m |
| Tie wire | ties × bars × 0.30 m ÷ 53 |
| Forms | 2 × lintel metres × 0.20 + openings × t (soffits) + 2 × sill metres × 0.10 + 2 × stiffeners × 0.20 × height; reused 3 times by default; lumber at the column factor |

A lintel is one block course (0.20 m) deep and rests 15–20 cm on the wall past
each side of the opening; a stiffener column is block-wide and half a block
(0.20 m) along the wall; a sill is 0.10 m thick. Cover is 25 mm, inside a
plastered wall (the NSCP gives 20 mm for walls not exposed to weather; 25 mm
leaves room for the 10 mm ties of a 4" wall). The stiffener count, one for
every spacing of wall, suits walls added up from several panels between
columns; enter each wall alone for an exact count. Blocks are counted over the
whole wall by the CHB calculator; the few these members replace are left as an
allowance for breakage. The section sizes, 2–4 × 10 mm bars with 10 mm ties at
0.20 m and the 3 m stiffener spacing are common Philippine practice for house
walls (AEDO, PH house plans), not NSCP requirements. The price field is the
price per bag of cement.

Works: the new `concrete_lintel` in m³ (0.1 foreman, 1 skilled, 2 helpers,
hand-mixed small pours; 1 m³ a day, an estimate; DPWH 900), rebar and
formwork.

Sources: Fajardo Table 1-2; NSCP 2015 Sec. 425.3 (hooks) and Table
420.6.1.3.1 (cover);
[AEDO CHB rebar spacing](https://aedoconstruction.com/blog/chb-wall-rebar-spacing-philippines/).

### Concrete pavement

| Step | Formula |
| --- | --- |
| Area, volume | length × width; × thickness [100 mm; 100, 125 or 150] × (1 + waste) [5%] |
| Cement (main item), sand, gravel | as for slabs, Class A by default |
| Bars both ways [default], 10 or 12 mm [10] | runs each way ⌊(side − 0.08) ÷ spacing⌋ + 1 [0.30 m; 0.20, 0.25, 0.30 or 0.40], cut and spliced as in a slab on fill (40 mm cover) |
| Welded wire mesh (instead) | ⌈area ÷ 7.90⌉ sheets of 1.5 × 6 m lapped 0.15 m each way: (1.5 − 0.15) × (6 − 0.15) = 7.90 m² |
| Control joints | spacing s = 30 × thickness up to 4.5 m [usual; or 1.5, 2 or 3 m]; (⌈length ÷ s⌉ − 1) × width + (⌈width ÷ s⌉ − 1) × length metres |
| Joint sealant [polyurethane; or none, tooled joints] | ⌈joints × 0.0792 L ÷ 0.6 L⌉ sausages (a 6 × 12 mm bead, + 10%) |
| Curing [compound; or kept wet with water] | ⌈area × 0.20 L ÷ 4 L⌉ gallons |
| Gravel base | area × base [0.10 m; none, 0.05, 0.10 or 0.15] |
| Edge forms | edge × thickness; edge = 2 × (length + width) or the edge entered; none when poured against curbs or walls; reused 3 times by default |

For a driveway, carport, sidewalk or yard; enter each rectangle of one
thickness on its own. The joint rule follows ACI 330R (24–36 times the
thickness, at most 4.5 m), which gives 3 m for 100 mm. The sealant bead and the
0.20 L/m² of curing compound are typical product-sheet figures (Sika Antisol E
gives 0.15–0.20 L/m²), not measured. Expansion joints against the house and
curbs, and dowels across joints, are not counted. The price field is the price
per bag of cement.

Works: the new `pcc_pavement` in m² with effort thickness ÷ 0.10 (0.5
foreman, 1 skilled, 4 helpers, a mixer and a vibrator; 40 m² a day at 100 mm,
an estimate that adds jointing and finishing to the 60 m² a day of a slab on
fill; DPWH 311, Portland Cement Concrete Pavement), rebar when bars are
chosen, formwork for the edges and gravel bedding (DPWH 200) for the base.
Mesh, sealant and curing compound go to the pavement itself.

Sources: DPWH Standard Specifications, Item 311 (Portland Cement Concrete
Pavement) and Item 200 (Aggregate Subbase Course); ACI 330R-08 (joint
spacing); Fajardo Table 1-2.

#### New price book items: pavement

All prices are Metro Manila retail, VAT included, for late 2026, and none
could be confirmed from a published source, so all are flagged as estimates.

| Item | Unit | Group | Price (₱) | Source |
| --- | --- | --- | ---: | --- |
| Welded wire mesh 6" × 6", 4 mm, 1.5 × 6 m sheet (`wire_mesh`) | sheet | Steel | 750 | Estimate: about 12.4 kg of 4 mm wire at about ₱60/kg |
| Polyurethane joint sealant, 600 mL sausage (`joint_sealant`) | pc | Other | 650 | Estimate (Sikaflex-class sausages, ₱550–750) |
| Concrete curing compound, 4 L (`curing_compound`) | gallon | Other | 700 | Estimate (wax or resin curing compounds by the 4 L) |

Reused items: cement, sand, gravel, gravel bedding, 10 to 16 mm bars, tie
wire, marine plywood, coco lumber and nails.

#### New work items: tie beams, lintels and pavements

| Key | Description | Unit | Crew per day | Output per day | DPWH |
| --- | --- | --- | --- | ---: | --- |
| `concrete_tie_beam` | Structural concrete, tie beams | m³ | 0.5 foreman, 1 skilled, 4 helpers, mixer, vibrator | 4 | 900 |
| `concrete_lintel` | Structural concrete, lintels, stiffener columns and sills | m³ | 0.1 foreman, 1 skilled, 2 helpers | 1 | 900 |
| `pcc_pavement` | Concrete pavement, 100 mm, placed, jointed and cured | m² | 0.5 foreman, 1 skilled, 4 helpers, mixer, vibrator | 40 (× thickness ÷ 0.10) | 311 |

The outputs are estimates in line with the other concrete work items; the
project's productivity setting scales them.

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
30 m² for latex flat and semi-gloss, the low end of Boysen's 30–35 m², and
25 m² for enamel, below Boysen's theoretical 30–35 m² and within a
retailer's 20–25 m². Rough walls take more paint than the theoretical
figure. The surface is a
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

### Waterproofing

| Step | Formula |
| --- | --- |
| Perimeter | 2 × (length + width) |
| Area to waterproof | length × width + perimeter × upturn [0.30 m; none, 0.15, 0.30 or 0.60 m] |
| Corners and joints | perimeter + joints and cracks (optional) |
| Cementitious coating, 2-component [default] | kg = area × 2 × coats [2; 2 or 3] × (1 + waste); ⌈kg ÷ 25⌉ sets (main item) |
| Elastomeric liquid membrane | litres = area × 0.5 × coats × (1 + waste); ⌈litres ÷ 4⌉ gallons [default] or ⌈litres ÷ 16⌉ pails (main item) |
| Acrylic primer (liquid only) | ⌈area × 0.2 × (1 + waste) ÷ 4⌉ gallons |
| Fiberglass mesh (coatings) | ⌈(perimeter + joints) × 0.20 × (1 + waste)⌉ m of 1 m wide mesh |
| Torch-on membrane | membrane = (area + (perimeter + joints) × 0.25) × (1 + waste); ⌈membrane ÷ 8.91⌉ rolls (main item) |
| Bituminous primer (torch-on) | ⌈area × 0.3 × (1 + waste) ÷ 4⌉ gallons |
| LPG (torch-on) | ⌈rolls × 2 ÷ 11⌉ tanks of 11 kg |

Waste is none, 5, 10 or 15% [10%]. The system picks the price field: price
per 25 kg set, per 4 L gallon, per 16 L pail or per roll. There is no pail
unit, so a pail is counted as a piece.

Torch-on rolls are 1 × 10 m. With 10 cm laps at the sides and ends, each
covers 0.9 × 9.9 = 8.91 m². A 0.25 m strip goes over the corners and joints
before the main sheets. Coatings get 0.20 m strips of fiberglass mesh in the
first coat over the same lengths. The mesh is bought by the metre of 1 m
wide roll and cut into 5 strips. Cementitious coatings go on damp concrete
and need no primer.

**Works.** Coatings: `waterproofing`, m² of the area to waterproof (upturns
included, waste and strips left out). The crew is 1 skilled worker and 1
helper, with an output of 25 m² a day for the full 2-coat system with the
mesh. Effort is coats ÷ 2, so 3 coats count 1.5. Torch-on: a separate
`waterproofing_torch` item in m², with the same crew at 30 m² a day,
primer and laps included. Two items were used instead of an effort factor
because torch-on is laid at a different pace and needs a trained
applicator. No DPWH item number was confirmed, so none is given.

The rates are planning defaults from typical data-sheet ranges. They are
recalled, not checked against current sheets:

- About 2 kg/m² per coat for cementitious coatings (SikaTop Seal-107 is
  about 2 kg/m² per mm).
- 0.5 L/m² per coat for elastomeric membranes (Sikalastic-560 lists about
  1.4–2.1 kg/m² in 2–3 coats).
- 0.2 L/m² for acrylic primer and 0.3 L/m² for bituminous primer.
- About 2 kg of LPG per roll. This is a conservative rule of thumb.
- 0.15 m minimum upstand, from BS 6229. The 0.30 m default is common
  practice for toilets, baths and parapets.

Sources: SikaTop Seal-107 and Sikalastic-560 product data sheets; BS
6229:2018; installation guides from APP membrane makers.

### Floor finishes

| Step | Formula |
| --- | --- |
| Floor area | length × width |
| SPC or vinyl planks [default] | ⌈area × (1 + waste) ÷ coverage⌉ boxes; coverage 2.2 m² unless entered (main item) |
| Laminated wood planks | the same with 2.0 m² per box (main item) |
| Foam underlay [rolls; or pad attached] | ⌈area × 1.05 ÷ 20⌉ rolls of 1 × 20 m |
| Skirting (optional length) | ⌈skirting × (1 + waste) ÷ 2.4⌉ pieces |
| Transition trims (optional doorways) | ⌈doorways × 0.90 ÷ 2.4⌉ pieces |
| Cement topping or screed: mortar | area × thickness [25 mm; or 50 mm] × (1 + waste) |
| Cement (main item) | ⌈mortar × 18 (1:2, Class A) [default] or 12 (1:3, Class B) + area × 0.025⌉ bags of 40 kg |
| Sand | mortar × 1.0 m³, by the half m³ |
| Dry-shake hardener [none] | ⌈area × 3 ÷ 25⌉ bags of 25 kg |

Waste is 5, 7, 10 or 15% [10%]. It covers plank offcuts, or spillage and
low spots under a topping. The price field follows the finish: price per box
of SPC, per box of laminate, or per bag of cement. The 0.025 bags per m² is
a neat cement slurry bond coat, the same allowance used under a tile bed.
Leave a 10 mm expansion gap at the walls; the skirting hides it.

**Works.** `floor_topping` in m²: 1 skilled worker and 1 helper at 25 m² a
day for 25 mm, with effort = thickness ÷ 25 mm, so a 50 mm screed counts
twice. `plank_flooring` in m²: 1 skilled worker and 0.5 helper at 20 m² a
day. Underlay, skirting and trims go into that work and its output.

Mortar per m³ comes from Fajardo: Class A 1:2 is 18 bags and 1.0 m³ of
sand, Class B 1:3 is 12 bags. The 3 kg/m² for hardener is the light-traffic
end of dry-shake hardener data sheets such as Sikafloor Chapdur, recalled.
Box coverage, the underlay roll size, 2.4 m trim lengths and 0.90 m per
doorway are typical retail figures, not checked against a source.

Sources: Fajardo, *Simplified Construction Estimate* (mortar table);
Sikafloor Chapdur data sheet; SPC and laminate installation guides.

### Cabinets and countertops

| Step | Formula |
| --- | --- |
| Countertop [granite; quartz, solid surface, laminated plywood, none] | base × (depth [0.60 m kitchen; 0.50 m vanity] + backsplash [0.10 m; none, 0.60 m]) m² |
| **Made to order** [default] | base cabinet metres (main item); wall cabinets per metre; countertop per m² |
| **Built on site**: 18 mm marine plywood (main item) | ⌈(base × 3.5 + wall × 2.2 + laminated top) × 1.15 ÷ 2.977⌉ sheets |
| 6 mm marine plywood backs | ⌈(base + wall) × 0.75 × 1.15 ÷ 2.977⌉ sheets |
| High-pressure laminate 4×8 | ⌈((base + wall) × 1.0 + laminated top) × 1.15 ÷ 2.977⌉ sheets |
| Contact cement | ⌈laminate m² × 0.4⌉ L |
| PVC edge band | ⌈((base + wall) × 9 + laminated top length) × 1.10 ÷ 50⌉ rolls |
| Doors | ⌈base ÷ 0.50⌉ + ⌈wall ÷ 0.50⌉ |
| Concealed hinges | doors × 2 |
| Drawer slides | ⌈base ÷ 1.0⌉ pairs (one drawer per metre of base) |
| Handles | doors + drawers |
| Nails | ⌈(base + wall) × 0.2⌉ kg |

Price fields: price per metre of base cabinet (made to order) or price per
sheet of 18 mm marine plywood (built on site). Fabricated countertops are
bought per m² in both cases. When a carpenter builds the cabinets with a
laminated plywood top, the top's area is added to the 18 mm plywood and the
laminate instead.

Per-metre assumptions for built on site, with 15% cutting waste:

- **Base cabinet**, 0.60 m deep and 0.75 m high on a 0.10 m toe kick: 3.5 m²
  of 18 mm panels per metre. That covers the bottom 0.56, sides and
  partitions 0.84, shelf 0.53, doors 0.75, rails 0.20, toe kick 0.10 and one
  drawer box 0.50.
- **Wall cabinet**, 0.35 m deep and 0.70 m high: 2.2 m² per metre. That
  covers the top and bottom 0.66, sides 0.46, shelf 0.32 and doors 0.70.
- **Backs and faces**: 0.75 m² of 6 mm back per metre, and about 1 m² of
  laminate on the exposed faces.
- **Other**: 9 m of edge band per metre, 0.4 L of contact cement per m² of
  laminate (both faces coated), doors about 0.50 m wide and 0.2 kg of nails
  per metre.

These are our own take-offs, not published factors. An L-shaped counter
measured along both legs counts the corner square twice in the countertop.
Sink and cooktop cut-outs, wood glue and screws are not counted.

**Works.** Made to order: `cabinets` in metres of base plus wall cabinet,
installation only. The crew is 1 skilled worker and 1 helper at 3 m a day.
Built on site: `cabinets_built` in the same metres, for carpentry,
laminating and hardware, with the same crew at 0.6 m a day.
`countertop` in metres of base cabinet: 1 skilled worker and 1 helper at
4 m a day, measured only when there is a countertop. Fabricated countertops
go to that work. Upper cabinets, plywood, laminate and hardware go to the
cabinet work. If the fabricator's price includes installation, the cabinet
labour is counted twice; the result's note says to check.

Sources: *Architectural Graphic Standards* for counter and cabinet sizes;
NKBA Kitchen Planning Guidelines; Blum hinge planning (2 hinges for doors up
to about 0.90 m).

#### New price book items: waterproofing, floors and cabinets (Metro Manila, late 2026)

All prices are our own estimates (`estimate: true`), from recalled 2024–25
retail levels at Wilcon, AllHome and fabricator quotes, raised for late
2026. None was checked against a published 2026 listing.

| Key | Item | Unit | Price (₱) | Group | Source |
| --- | --- | --- | ---: | --- | --- |
| wp_cementitious_set | Cementitious waterproofing, 2-component, 25 kg set | set | 3,200 | paint | estimate |
| wp_liquid_gallon | Elastomeric liquid waterproofing, 4 L | gallon | 1,400 | paint | estimate |
| wp_liquid_pail | Elastomeric liquid waterproofing, 16 L | pail | 5,200 | paint | estimate |
| wp_torch_roll | Torch-on APP membrane 4 mm, 1 × 10 m | roll | 3,600 | paint | estimate |
| wp_primer | Waterproofing primer, acrylic, 4 L | gallon | 950 | paint | estimate |
| wp_bitumen_primer | Bituminous primer, 4 L | gallon | 850 | paint | estimate |
| wp_mesh | Fiberglass reinforcing mesh, 1 m wide | m | 45 | paint | estimate |
| wp_lpg_11kg | LPG, 11 kg tank refill | tank | 1,050 | other | estimate; check DOE weekly LPG prices |
| floor_spc_box | SPC plank flooring, box of 2.2 m² | box | 1,700 | tiles | estimate (about ₱770/m²) |
| floor_laminate_box | Laminated wood flooring 8 mm, box of 2 m² | box | 1,300 | tiles | estimate (about ₱650/m²) |
| floor_underlay_roll | Foam underlay 2 mm, 1 × 20 m | roll | 900 | tiles | estimate |
| floor_skirting | Floor skirting, PVC 80 mm × 2.4 m | pc | 280 | tiles | estimate |
| floor_trim | Floor transition trim, 2.4 m | pc | 450 | tiles | estimate |
| floor_hardener | Floor hardener, dry-shake, 25 kg | bag | 1,400 | tiles | estimate |
| cabinet_base_lm | Base cabinet, made to order | m | 14,000 | other | estimate (fabricator range ₱12,000–18,000/m) |
| cabinet_upper_lm | Wall cabinet, made to order | m | 10,000 | other | estimate |
| counter_granite_m2 | Granite countertop, fabricated | m² | 6,500 | other | estimate |
| counter_quartz_m2 | Quartz countertop, fabricated | m² | 12,000 | other | estimate |
| counter_solid_m2 | Solid surface countertop, fabricated | m² | 9,000 | other | estimate |
| counter_laminate_m2 | Laminated plywood countertop, fabricated | m² | 3,500 | other | estimate |
| hpl_laminate | High-pressure laminate 0.8 mm 4×8 | sheet | 1,800 | lumber | estimate |
| edge_band | PVC edge band 22 mm × 50 m | roll | 450 | lumber | estimate |
| contact_cement | Contact cement, 1 L | L | 300 | lumber | estimate |
| cabinet_hinge | Concealed cabinet hinge 35 mm, soft-close | pc | 150 | other | estimate |
| drawer_slide | Drawer slide 18", full extension | pair | 350 | other | estimate |
| cabinet_handle | Cabinet handle | pc | 80 | other | estimate |

Reused items: `cement_40kg`, `sand`, `marine_plywood_18`, `marine_plywood_6`
and `nails`.

#### New work items: waterproofing, floors and cabinets

| Key | Description | Unit | Crew | Output per day |
| --- | --- | --- | --- | ---: |
| waterproofing | Waterproofing coating, 2 coats with reinforcing mesh | m² | 1 skilled, 1 helper | 25 (effort = coats ÷ 2) |
| waterproofing_torch | Torch-on bituminous membrane, primed and lapped | m² | 1 skilled, 1 helper | 30 |
| floor_topping | Cement floor topping, troweled finish | m² | 1 skilled, 1 helper | 25 at 25 mm (effort = thickness ÷ 25 mm) |
| plank_flooring | SPC or laminate plank flooring with underlay and skirting | m² | 1 skilled, 0.5 helper | 20 |
| cabinets | Cabinets made to order, installed | m | 1 skilled, 1 helper | 3 |
| cabinets_built | Cabinets built on site, laminated, with hardware | m | 1 skilled, 1 helper | 0.6 |
| countertop | Countertop with backsplash, installed | m | 1 skilled, 1 helper | 4 |

No DPWH item numbers are given, since none could be confirmed.

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
home run only, because its outlet is counted with the outlets. The
breakdown recommends the smallest panel with 25% spare spaces. The form
starts at 12 branches; pick the recommended size to book and price that
panel. A panel smaller than the circuit count is refused.

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

### Data, TV and CCTV

| Step | Formula |
| --- | --- |
| CAT6 (main item) | (data outlets + IP cameras) × run × 1.10; by the metre ⌈m⌉ [default], or ⌈m ÷ 305⌉ boxes |
| Data outlets | 1 CAT6 keystone, 1 faceplate, 1 utility box and 1 RJ45 plug each |
| Network switch, 8-port | ⌈data ÷ 7⌉ when data > 4 (the router's LAN ports) |
| RG6 coax | TV × run × 1.10 |
| TV outlets | 1 F keystone, 1 faceplate, 1 utility box each; F connectors 2 × TV + splitters |
| 4-way splitters | ⌈TV ÷ 4⌉ when TV > 1 |
| Doorbell | 1 chime with push button, a utility box, 2.0 mm² wire run × 2 × 1.10 |
| Conduit ½" | ⌈(data + TV + doorbell) × run × 1.10 ÷ 3⌉, and ⌈cameras × run × 1.10 ÷ 3⌉ |
| Recorder | smallest of 4, 8 or 16 channels ≥ cameras, or ⌈cameras ÷ 16⌉ 16-channel |
| Hard disk | 1 TB (4 ch), 2 TB (8 ch), 4 TB (16 ch) per recorder |
| HD analog | DVR; RG59 + power cable cameras × run × 1.10; BNC and DC plugs per camera; ⌈cameras ÷ 4⌉ 12 V 5 A supplies |
| IP | NVR; PoE switch with the recorder's port count; 2 RJ45 plugs per camera |
| Every camera | 1 junction box |

Cable bought as companions (RG6, RG59) is whole 305 m boxes, plus the rest
by the metre unless 200 m or more is left, when another box is bought.
Inputs: data outlets (required, at least 1: count one for the CCTV
recorder's link to the router), TV outlets, cameras and the average run per
point [15 m]. CCTV system: HD analog with DVR [default] or IP with NVR and
PoE switch. Doorbell: no [default] or yes.

**Main item.** CAT6 cable is the main item, priced per metre or per 305 m
box. It is the one material every job here needs (data outlets are
required) and the one people price by length; cameras and recorders are
companions priced from the price book. IP camera runs are part of the main
CAT6.

Work: data, TV and doorbell points as the new **aux_point** work (1 skilled
+ 0.5 helper, 8 points a day) and cameras as the new **cctv_camera** work
(1 skilled + 1 helper, 4 cameras a day). Cameras, recorders, disks, PoE
switches, RG59, camera plugs, power supplies, camera junction boxes and
camera conduit go to the CCTV work; the rest to the points. No DPWH items.

The 10% cable allowance (slack and termination) and the 200 m box threshold
are planning values. Disk sizes give about two weeks of continuous recording
at 2 MP, 15 fps, H.265 (about 1.7 Mbps or 18 GB per camera a day, from the
storage calculators below); 4 MP IP cameras fill them in about a week.
CAT6 runs must stay under 90 m (TIA-568 permanent link), which the 80 m top
of the typical run range respects. The internet provider's modem-router is
not priced.

Sources: [CCTV storage calculator](https://cctvdesigntool.com/calculators/storage),
[CCTV Camera Pros storage calculator](https://videos.cctvcamerapros.com/video-storage-calculator.md),
[Villman Hikvision kits](https://villman.com/Product-Detail/hikvidion_tvi-8ch4d4b-2mp).

### Lighting fixtures

| Step | Formula |
| --- | --- |
| Light needed | lux × room length × width |
| Fixtures (main item) | ⌈light needed ÷ (fixture lumens × 0.6 × 0.8)⌉ |
| Flexible conduit ½" | ⌈fixtures × 1.5⌉ m |
| Fixture wire, 2.0 mm² | ⌈fixtures × 1.5 × 2⌉ m, cut |

Room: bedroom 100 lx, living room 150 [default], bathroom 200, kitchen 300,
study or office 500 (as for light bulbs). Fixtures: 4" downlight 9 W 750 lm
[default], 6" downlight 12 W 1,000 lm, pin light 5 W 400 lm, surface ceiling
lamp 24 W 2,000 lm, T8 batten 18 W 1,800 lm. You can also enter a number of
fixtures. The breakdown shows the lighting load (fixtures × watts). Work:
Work.lightFixture, one per fixture.

The lumen method with a utilisation factor of 0.6 and a maintenance factor
of 0.8 (0.48 together, against 0.5 for bulbs) is the textbook method; 0.6
suits a small room with light walls and 0.8 is the usual maintenance value.
Lumens are typical catalogue values for each wattage, about 80–100 lm/W.
The 1.5 m whip of flexible conduit with two wires per fixture is a planning
allowance; junction boxes and circuits come with the Electrical Rough-in
calculator, and ceiling cut-outs need no material.

Sources: [Engineering ToolBox light levels](https://www.engineeringtoolbox.com/light-level-rooms-d_708.html),
[VIOX lumen method calculator](https://tools.viox.com/lighting-calculator/),
[LRC LED lighting guide](https://www.lrc.rpi.edu/programs/solidstate/assist/pdf/led-lighting-apps-guide-2002.pdf).

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

### Drainage and catch basins

| Step | Formula |
| --- | --- |
| Pipes (main item) | ⌈run × 1.05 ÷ 3⌉ lengths of 3 m |
| Fittings | 0.30 × pipes × price per pipe, as one lot |
| Solvent cement | ⌈run × 1 joint per m ÷ joints per can⌉ cans of 100 cc |
| Cleanouts, floor drains | as entered (optional) |
| Block basin walls, 4" CHB | basins × 4 × (0.45 + 0.10) × 0.60 = 1.32 m² each, on the centre line |
| Blocks | ⌈walls × 12.5⌉ + ⌈5%⌉ |
| Plaster, inside | basins × 4 × 0.45 × 0.60 = 1.08 m² each |
| Floor slab, Class A | basins × 0.65 × 0.65 × 0.10 = 0.04225 m³ each |
| Cement | slab × 9 + walls × 0.522 + plaster × 0.192 bags |
| Sand, gravel | slab × 0.5 + walls × 0.0435 + plaster × 0.016 m³; slab × 1.0 m³ |
| Gratings | basins (cast iron [default] or steel), block basins only |
| Precast or PVC boxes | basins, instead of all the block basin materials |

Diameters: 2", 3", 4" [default] and 6". Pipe: orange sanitary pipe
[default] or Series 1000 (thicker wall, for driveways and deep fill), both in
3 m lengths. Catch basins are optional, so a sanitary line under the house
can be priced with none. A 100 cc can makes 6 joints at 2", 4 at 3", 3 at
4" and 1 at 6" (Oatey's joints per quart scaled to 100 cc; the 6" figure,
about 10 per quart, gives 1.06 per can). Cleanout plugs are priced at the
4" plug's price whatever the diameter.

Work: the run in m of Work.piping (main) and the basins as sets of the new
**catch_basin** work (1 skilled + 1 helper, 1 set a day, DPWH Item 502,
Manholes, Inlets and Catch Basins). Basin blocks, cement, sand, gravel,
gratings and boxes go to the catch basin work; fittings, cement cans,
cleanouts and floor drains to the piping.

The 5% pipe allowance (less than the 10% of the PVC pipe calculator, which
covers water lines with many short pieces) and the 30% fittings allowance
are planning values for long, mostly straight drain runs. Neither comes from
a published table. The 0.45 × 0.45 × 0.60 m basin is a common size on house
plans, not a code minimum. Mortar, plaster and concrete factors are
Fajardo's (see Shared factors). Basins have no bars. Trench digging,
backfill and bedding are not included. Falls of at least 2% for 3" and
smaller and 1% for 4" and larger follow the National Plumbing Code (UPC
basis), as quoted by AEDO.

Sources: [AEDO NPC drain sizing](https://aedoconstruction.com/blog/npc-drain-pipe-sizing-calculator-philippines/),
[Neltex](https://www.neltex.com/products.do?item_id=51663),
[Moldex](https://mpi.moldex.com.ph/mb-pipes-and-fittings),
[PVC glue guide](https://www.commercial-industrial-supply.com/resource-center/how-much-pvc-glue-to-use/),
[DPWH D.O. 028 s. 2025, Item 502](https://dpwh.gov.ph/DPWH/sites/default/files/issuances/do_028_s2025.pdf),
Fajardo, *Simplified Construction Estimate*, Tables 1-2 and 2-2.

### Water pump

| Step | Formula |
| --- | --- |
| Size step | up to 2 bathrooms: 0; 3 or 4: 1; 5 or 6: 2; +1 for 3 storeys; at most 2 |
| Pump (main item) | 1 set: ½ HP, 1 HP or 1½ HP |
| Pressure tank (jet pump only) | 24 L, 60 L or 100 L, by the same step |
| Jet pump extras | 1 five-way tank connector, 1 pressure switch, 1 gauge |
| Valves and fittings | 1 check valve, 2 gate valves, 2 unions, 2 braided hoses, all 1"; 1 pump base |
| Teflon tape | ⌈joints ÷ 40⌉; 16 threaded joints, 21 with a tank |
| Pump circuit wire, 3.5 mm² | distance × 3 wires × 1.10, cut by the metre |
| Conduit ½" | ⌈distance × 1.10 ÷ 3⌉ |
| Breaker | 15 A for ½ HP, 20 A for 1 to 1½ HP |

Pump: jet pump with pressure tank [default] or booster pump with a built-in
controller (no tank, switch, gauge or connector). Bathrooms: up to 2
[default], 3 or 4, 5 or 6. Storeys: 1, 2 [default] or 3. Distance from the
panel board [10 m]. Bathrooms are a choice rather than a number so that the
suggested price can follow the pump size: a price reference can only read
choices.

Work: 1 set of the new **pump_install** work (1 skilled plumber + 1 helper,
1 set a day, no DPWH item) as the main work, and the wire metres of
Work.wiring. The wire, conduit and breaker go to the wiring.

The size rule is a planning rule, not a code table. ½ HP with 24 L is the
set Philippine retailers sell most (1 HP jet pumps with 24 L tanks are listed
at ₱4,990–9,030 at Buildmate and KHM Tools). Each storey adds about 3 m of
head, so a 3-storey house moves up one size. US practice sizes a diaphragm
tank at 3 × the drawdown, with about a minute of pump flow as drawdown
(Alberta worksheet), which gives larger tanks than these; a larger tank
starts the pump less often. Breakers: single-phase 230 V motors draw about
4.9 A (½ HP), 8 A (1 HP) and 10 A (1½ HP) at full load (NEC Table 430.248,
which the PEC follows); 250% of that is 12.3, 20 and 25 A, so ½ HP takes a
15 A breaker and the others 20 A, all on 3.5 mm² wire. Recalled from the
NEC, not checked against the PEC text. The 1" fittings suit ½–1 HP; some
1½ HP pumps take 1¼". The suction and delivery pipes are not included.

Sources: [Alberta water system sizing worksheet](https://www1.agric.gov.ab.ca/$Department/deptdocs.nsf/all/agdex15866/$FILE/716_B01_ws2.pdf),
[KHM Tools pressure tanks](https://khmtools.com.ph/collections/pressure-tank),
[KHM Tools booster pumps](https://khmtools.com.ph/collections/booster-pump),
[Buildmate jet pump set](https://www.shopbuildmate.com/products/powerhouse-water-jet-pump-1hp-with-24l-pressure-tank-set-for-water-transfer-supply-phco-jet24l-tnk),
[PEC Article 2.10](https://filipinoengineer.com/wiki/Philippine_Electrical_Code_2017_Part_1/Chapter_2._Wiring_and_Protection/Article_2.10_-_Branch_Circuits).

#### New work items: drainage, pumps, auxiliary and lighting

| Key | Description | Unit | Crew | Output a day | DPWH |
| --- | --- | --- | --- | ---: | --- |
| catch_basin | Catch basin with grating, built or set in place | set | 1 skilled, 1 helper | 1 | 502 |
| pump_install | Water pump set with valves, installed and tested | set | 1 skilled, 1 helper | 1 | — |
| aux_point | Data, TV or doorbell point, cabled and terminated | pt | 1 skilled, 0.5 helper | 8 | — |
| cctv_camera | CCTV camera, mounted, cabled and set up | set | 1 skilled, 1 helper | 4 | — |

#### New price book items: drainage, pumps, auxiliary and lighting

Metro Manila retail, VAT included, late 2026. **Every price is our
estimate** (`estimate: true`). Most retailer pages could not be opened, so
they rest on search-result excerpts read in October 2026, noted where they
helped, and on our own judgement elsewhere. Check them with your supplier.

| Key | Item | Unit | Price (₱) | Basis |
| --- | --- | --- | ---: | --- |
| pvc_6 | PVC sanitary pipe (orange) 6", 3 m | pc | 1,000 | Estimate, scaled from the 4" price |
| pvc_s1000_2 | PVC sanitary pipe Series 1000 2", 3 m | pc | 330 | Estimate |
| pvc_s1000_3 | PVC sanitary pipe Series 1000 3", 3 m | pc | 520 | Estimate |
| pvc_s1000_4 | PVC sanitary pipe Series 1000 4", 3 m | pc | 720 | Estimate |
| pvc_s1000_6 | PVC sanitary pipe Series 1000 6", 3 m | pc | 1,600 | Estimate |
| grating_cast_iron | Catch basin grating, cast iron, with frame, 0.50 × 0.50 m | pc | 3,500 | Estimate |
| grating_steel | Catch basin grating, steel bars on angle frame, 0.50 × 0.50 m | pc | 2,000 | Estimate |
| catch_basin_box | Catch basin box with grating, precast or PVC | pc | 2,500 | Estimate |
| jet_pump_0_5hp | Jet pump, shallow well, ½ HP | set | 4,500 | Estimate |
| jet_pump_1hp | Jet pump, shallow well, 1 HP | set | 7,500 | Estimate; bare 1 HP jet pumps ₱2,950 (Megatools) to ₱14,500 (Grundfos JPC) in KHM Tools excerpts, Oct 2026 |
| jet_pump_1_5hp | Jet pump, shallow well, 1½ HP | set | 11,500 | Estimate |
| booster_pump_0_5hp | Booster pump with built-in pressure controller, ½ HP | set | 12,000 | Estimate |
| booster_pump_1hp | Booster pump with built-in pressure controller, 1 HP | set | 20,000 | Estimate (branded all-in-one boosters such as Grundfos MQ cost more) |
| booster_pump_1_5hp | Booster pump with built-in pressure controller, 1½ HP | set | 28,000 | Estimate |
| pressure_tank_24 | Pressure tank, diaphragm, 24 L | pc | 2,200 | Estimate |
| pressure_tank_60 | Pressure tank, diaphragm, 60 L | pc | 4,800 | Estimate; KHM Tools excerpts show 60 L tanks at ₱3,300–5,150, Oct 2026 |
| pressure_tank_100 | Pressure tank, diaphragm, 100 L | pc | 8,000 | Estimate |
| pressure_switch | Pressure switch, 1.4–2.8 bar | pc | 750 | Estimate (automatic pump controllers with gauge are ₱1,700–1,980) |
| pressure_gauge | Pressure gauge, 0–10 bar | pc | 350 | Estimate |
| tank_connector | Five-way tank connector, 1", brass | pc | 450 | Estimate |
| check_valve_1 | Check valve 1", brass | pc | 600 | Estimate |
| gate_valve_1 | Gate valve 1", brass | pc | 700 | Estimate |
| union_1 | Union 1", PVC, threaded | pc | 95 | Estimate |
| pump_hose_1 | Flexible hose 1", braided, for pumps | pc | 450 | Estimate |
| pump_base | Pump base: concrete pad with anchor bolts | set | 600 | Estimate (about ½ bag of cement, sand, gravel and 4 bolts) |
| cat6_box | CAT6 UTP cable, copper, box of 305 m | box | 7,500 | Estimate; no peso listing found (foreign listings about US$90–150) |
| cat6_m | CAT6 UTP cable, cut | m | 30 | Estimate |
| rg6_box | RG6 coaxial cable, box of 305 m | box | 4,500 | Estimate |
| rg6_m | RG6 coaxial cable, cut | m | 20 | Estimate |
| rg59_box | CCTV cable, RG59 with power wires, box of 305 m | box | 3,800 | Estimate |
| rg59_m | CCTV cable, RG59 with power wires, cut | m | 18 | Estimate |
| keystone_cat6 | Keystone jack, CAT6 | pc | 120 | Estimate |
| keystone_f | Keystone jack, F-type (TV) | pc | 80 | Estimate |
| faceplate_keystone | Faceplate for 1 keystone jack | pc | 80 | Estimate |
| rj45_plug | RJ45 plug, CAT6 | pc | 15 | Estimate |
| f_connector | F connector, RG6 | pc | 20 | Estimate |
| tv_splitter_4 | TV splitter, 4-way | pc | 280 | Estimate |
| network_switch_8 | Network switch, 8-port gigabit | pc | 1,600 | Estimate |
| cctv_camera_hd | CCTV camera, HD analog, 2 MP | pc | 1,500 | Estimate; Villman 8-channel 1080p kits (DVR + 8 cameras) ₱20,480 |
| cctv_camera_ip | IP camera, 4 MP, PoE | pc | 3,200 | Estimate |
| dvr_4 / dvr_8 / dvr_16 | DVR, 4 / 8 / 16-channel | pc | 3,200 / 5,200 / 9,500 | Estimate |
| nvr_4 / nvr_8 / nvr_16 | NVR, 4 / 8 / 16-channel | pc | 3,800 / 5,800 / 10,500 | Estimate |
| hdd_1tb / hdd_2tb / hdd_4tb | Surveillance hard disk, 1 / 2 / 4 TB | pc | 3,300 / 4,800 / 7,800 | Estimate |
| poe_switch_4 / poe_switch_8 / poe_switch_16 | PoE switch, 4 / 8 / 16 ports | pc | 2,500 / 4,500 / 10,000 | Estimate |
| cctv_psu | CCTV power supply 12 V, 5 A, for 4 cameras | pc | 700 | Estimate |
| cctv_connectors | BNC and DC plugs for one camera | set | 80 | Estimate |
| doorbell | Doorbell chime with push button | set | 650 | Estimate |
| led_downlight_4 | LED downlight 4", 9 W | pc | 280 | Estimate |
| led_downlight_6 | LED downlight 6", 12 W | pc | 420 | Estimate |
| led_pin_light | LED pin light, 5 W | pc | 180 | Estimate |
| led_ceiling_lamp | LED ceiling lamp, surface, 24 W | pc | 950 | Estimate |
| led_batten | LED T8 batten, 4 ft, 18 W | pc | 480 | Estimate |
| flex_conduit_m | Flexible conduit ½", cut | m | 22 | Estimate |

Reused items: pvc_2, pvc_3, pvc_4, pvc_fittings, solvent_cement,
cleanout, floor_drain, teflon_tape, chb_4, cement_40kg, sand, gravel,
thhn_2_0_m, thhn_3_5_m, conduit_half, utility_box, junction_box,
breaker_15a and breaker_20a.

Price sources read in October 2026:
[KHM Tools pressure tanks](https://khmtools.com.ph/collections/pressure-tank),
[KHM Tools booster pumps](https://khmtools.com.ph/collections/booster-pump),
[Buildmate jet pump set](https://www.shopbuildmate.com/products/powerhouse-water-jet-pump-1hp-with-24l-pressure-tank-set-for-water-transfer-supply-phco-jet24l-tnk),
[Villman Hikvision kits](https://villman.com/Product-Detail/hikvidion_tvi-8ch4d4b-2mp).

## Fences, roof edges and house services

Eight calculators for scope a house estimate usually needs beyond the
building itself. Their code is in
[`lib/materials/exterior.dart`](../lib/materials/exterior.dart) (fence,
gate, fascia, soffit, flashing) and
[`lib/materials/home_services.dart`](../lib/materials/home_services.dart)
(service entrance, water heater, bathroom accessories); the tests are in
[`test/materials/exterior_test.dart`](../test/materials/exterior_test.dart)
and [`test/materials/home_services_test.dart`](../test/materials/home_services_test.dart).

### Perimeter fence (Structural)

| Step | Formula |
| --- | --- |
| Posts | bays = ⌈length ÷ spacing⌉ [3.0 m; 2.5, 3.0 or 3.5]; posts = bays + 1, each 0.20 × 0.20 or 0.25 × 0.25 m [0.20] |
| Block wall | (length − posts × post) × (height + depth − 0.20) [footing depth 0.80 m; 0.60, 0.80 or 1.00] |
| Blocks (main item), 4", 6" or 8" [6"] | ⌈wall × 12.5⌉ + ⌈5%⌉ [waste 5%; 0, 5, 10 or 15%] |
| Laying mortar | wall × the CHB mortar factor (Fajardo Table 2-2) |
| Plaster, 16 mm, none, one or both faces [both] | length × height × faces, above the ground, posts included: 0.192 bags and 0.016 m³ sand per m² |
| Wall footing | (length − posts × 0.60) × width [0.60 m; 0.40 or 0.60] × 0.20 m |
| Post footings | posts × 0.60 × 0.60 × 0.25 m |
| Posts | posts × post² × (height + depth − 0.25) |
| Concrete, Class A [default] | footings and posts each × 1.05 × the mix factors; cement, sand and gravel bought separately for footings and posts |
| 10 mm bars | wall 4.28 m per m² (vertical every 0.60 m + horizontal every 3rd course, the CHB factors); 3 bars along the whole fence (40 d laps past 6 m); cross bars every 0.40 m of wall footing, each width − 0.15 m; 4 bars each way in each post footing, each 0.45 m; ties every 0.20 m, each 4 × (post − 0.08) + 2 × 0.105 m |
| Post bars, 4 × 10 or 4 × 12 mm [12] | each post height + 0.30 m bent into the footing |
| Tie wire | crossings × 0.30 m ÷ 53: wall area ÷ 0.36, cross bars × 3, 16 per post footing, 4 per tie |
| Forms | 2 exposed faces per post: posts × 2 × post × post height; marine plywood 12 mm max(1, ⌈area ÷ 2.88 ÷ 3⌉), coco lumber 20.33 bd ft per sheet, nails 0.20 kg/m² |
| Paint (none [default] or latex, shown only with plaster) | plaster area: neutralizer ÷ 85 L, primer ÷ 6.25 L × 1.10, latex × 2 coats ÷ 7.5 L × 1.10 |

Works: the CHB wall of the block size (`chb_4`, `chb_6` or `chb_8`) in m²,
plaster in m², `concrete_footing` and `concrete_column` in m³ (net, each with
its own cement, sand and gravel), rebar in kg, formwork in m² and, with
paint, painting in m² with effort 3. Laying and plaster materials stay with
the wall. Digging and backfill are left to the Earthworks calculator.

The post and footing details are a typical Philippine house fence (posts
about every 3 m, 10 mm bars, Class A concrete) rather than a design: the
plans govern. Two post faces are formed because the blocks close the other
two; end posts have a third face, which is not counted. Forms are used three
times along the fence, a planning value. Sources: Fajardo, *Simplified
Construction Estimate* (concrete, mortar, plaster and forms tables); NSCP 2015
Table 420.6.1.3.1 (75 mm cover in footings, 40 mm in posts) and Sec. 425.3
(hooks); AEDO's CHB bar spacing; paint coverage as in the Paint calculator.

### Steel gate (Architectural)

| Step | Formula |
| --- | --- |
| Leaf | swing: the opening width, in 1 or 2 leaves [2]; sliding: width + 2 × 0.10 m overlap |
| Area | gates [1] × leaf × height |
| Gate (main item) | by the m² [default] (`steel_gate_m2`) or by the set (`steel_gate_set`) |
| Swing hardware | hinges: 2 per leaf, 3 when the gate is taller than 1.5 m; a drop bolt per leaf; a latch per gate |
| Sliding hardware | 2 V-groove wheels, 3 for a leaf over 4 m; track = 2 × leaf in 1½" angle bar, ⌈gates × track × 1.05 ÷ 6⌉ lengths; ⅜" expansion anchors ⌈track ÷ 0.60⌉ + 1 per gate; a top guide roller set, 2 stoppers and a latch per gate |
| Steel posts (optional; default: hung on the fence's concrete posts) | 2 per gate, 4" × 4" × 3 mm tube, each height + 0.60 m, ⌈metres × 1.05 ÷ 6⌉ lengths; a 0.40 × 0.40 × 0.80 m Class A footing each, × 1.05 |
| Paint (enamel [default] or by the fabricator) | both faces: 2 × area × 2 coats ÷ 6.25 L × 1.10; thinner ÷ 8 + 0.5 L; no primer, as gates arrive primed |

Work: the new `steel_gate` in m² (1 skilled welder, 1 helper and a welding
machine; 4 m² a day to set posts, hang or track and adjust a fabricated gate;
our estimate) and painting with effort 2. Hardware counts are practice, not
a published table. The per-m² price follows AEDO's ₱115–185 per kg for
fabricated light steel at about 25–30 kg/m² of tubular gate with infill.

### Fascia board (Architectural)

| Step | Formula |
| --- | --- |
| Fascia | length × 1.05 for cuts, mitres and joints |
| Fiber cement 9 mm [default] | strips 2.44 m long: ⌈fascia ÷ 2.44⌉; strips per 4 × 8 sheet ⌊1.22 ÷ width⌋ (8 at 6", 6 at 8" [default], 4 at 10"); sheets = ⌈strips ÷ per sheet⌉ |
| Wood, 1" good lumber | 12 ft boards (3.66 m): ⌈fascia ÷ 3.66⌉; nails 0.05 kg per m |
| Pre-painted metal | metres = fascia, rounded up to the cm; tek screws length × 2 ÷ 0.40 |
| Backing (fiber cement and metal) | 2 rows of 5 m metal furring: ⌈2 × fascia ÷ 5⌉ |
| Board screws (fiber cement) | length × 2 ÷ 0.30, in boxes of 100 |
| Paint | face = length × width; primer + 2 coats of latex (fiber cement) or enamel with thinner (wood), as in the Paint calculator |

Work: the new `fascia_board` in m (1 skilled, 1 helper and half a scaffold
set; 15 m a day, our estimate) and painting with effort 3 for fiber cement
and wood. The wood board prices are the price book's good lumber (₱70 per
bd ft) × 6, 8 or 10 bd ft. The 0.05 kg of nails per metre is our estimate.
**Not double counted:** the Roofing Sheets calculator counts no fascia.

### Eaves soffit (Architectural)

| Step | Formula |
| --- | --- |
| Area | eaves length (along the fascia) × overhang |
| Fiber cement 4.5 mm [default] | ⌈area × 1.10 ÷ 2.977⌉ sheets; board screws area × 14, in boxes of 100; wall angle ⌈length × 1.05 ÷ 3⌉ |
| PVC panels 0.20 × 3.0 m | strips = ⌈length ÷ 0.20⌉; panels = ⌈strips ÷ ⌊3.0 ÷ overhang⌋⌉ (or strips × ⌈overhang ÷ 3⌉ past 3 m) + ⌈5%⌉; J-trim ⌈2 × length × 1.05 ÷ 3⌉; one screw per strip per furring line |
| Furring | lines = ⌈overhang ÷ spacing⌉ + 1 (0.40 m under fiber cement, 0.60 m under PVC); cross pieces ⌈length ÷ 1.2⌉ + 1; ⌈(lines × length + cross × overhang) × 1.05 ÷ 5⌉ pieces |
| Paint (fiber cement) | primer + 2 coats of latex on the area |

Measuring along the fascia counts each outside corner's overhang² twice,
which is a little generous. Work: the new `eaves_soffit` in m² (1 skilled,
1 helper and a scaffold set; 8 m² a day, below the 10 m² of an indoor
ceiling for the narrow strips and work at the edge; our estimate) and
painting with effort 3. The 0.40 m furring spacing and 14 screws per m² are
the Ceiling calculator's; the 0.60 m spacing for PVC is our estimate for
stiff interlocking panels. **Not double counted:** the Roofing Sheets
calculator counts no soffit.

### Roof flashing (Architectural)

| Step | Formula |
| --- | --- |
| Pieces (main item) | ⌈length ÷ 2.25⌉: 2.4 m pieces lapped 0.15 m, as ridge rolls in the Roofing Sheets calculator |
| Sealant, 300 ml | ⌈((pieces − 1) × girth + length for wall flashing) ÷ 6⌉; girth 0.30 m wall, 0.60 valley, 0.40 gable, 0.45 ridge |
| Tek screws | rows × (⌈length ÷ 0.40⌉ + 1); 1 row on wall flashing, 2 on the others |
| Wall plugs with screws (wall flashing) | ⌈length ÷ 0.40⌉ + 1 |

Kinds: wall or apron [default], valley, gable or barge, and ridge or hip roll
(the existing `ridge_roll`). Work: the new `roof_flashing` in m (1 skilled,
0.5 helper; 20 m a day, our estimate). A 300 ml tube runs about 6 m of an
8 mm bead (about 50 mm² of section). **Not double counted:** the Roofing
Sheets calculator already buys ridge and hip rolls for the ridge and hips it
measures, and gutters and downspouts; it counts no valley, wall or gable
flashing. The ridge option is for roofs not estimated there, and the
calculator says so in its help, its choice helper and its note.

### Electrical service entrance (Electrical)

| Step | Formula |
| --- | --- |
| Main breaker → service wire and pipe | 40 A: 2 × 8.0 mm² in ¾"; 60 A [default]: 2 × 14 mm² in ¾"; 100 A: 2 × 30 mm² in 1" |
| Run | riser [3 m] + meter to panel board [5 m] |
| Service wire (main item), THHN/THWN | ⌈2 × (run × 1.10 + 1.5)⌉ m: 1.0 m for the drip loop at the cap and 0.5 m through the meter base |
| RSC [default] or IMC pipe, 3 m | ⌈run × 1.10 ÷ 3⌉; couplings = lengths − 1; 2 elbows; 3 locknut and bushing sets; straps ⌈run ÷ 1.5⌉ + 1; 1 entrance cap |
| Ground wire, 8.0 mm² | ground run [3 m] × 1.10 |
| Also | 1 meter base, 1 roll of electrical tape; a ground rod set only when chosen (the Electrical Rough-in already buys one); the utility lump sum when chosen |

Wire sizes are the PEC 2017 ampacity table (Table 3.10.2.6(B)(16), which
follows NEC Table 310.15(B)(16)) at 75 °C for copper THHN/THWN: 8.0 mm² 50 A,
14 mm² 65 A, 30 mm² 100 A; a Philippine engineering blog gives 100 A for
30 mm² at 75 °C. 22 mm² (85 A) is what some designers use for 100 A under the
NEC's 83% rule for one-family dwellings (NEC 310.15(B)(7)), which the code
writes for 120/240 V three-wire services; Philippine houses are usually fed
at 230 V two-wire, so the app keeps 30 mm². Pipe sizes keep two wires within
the 31% fill of Chapter 9 Table 1, using NEC Chapter 9 Tables 4 and 5
areas (¾" RMC 0.549 in², 1" 0.887 in²; 6 AWG THHN 0.0507 in², 2 AWG
0.1158 in²). The 8.0 mm² ground wire is the minimum of the grounding
electrode conductor table (PEC Table 2.50.3.66, following NEC Table 250.66)
for service wires up to 30 mm². These code values were recalled and checked
against secondary sources, not the PEC text. Straps every 1.5 m are tighter
than the code's 3 m to take the service drop's pull; Meralco's guide for
customer-owned poles asks for a strap every 0.76 m on a pole.

Meralco issues the meter base and asks for a bill deposit of about one
month's estimated bill, set from the applied load and refundable; a cash
advance applies only when new utility facilities are needed. The ₱4,000
lump sum (`utility_connection`) is our estimate for a small house. Voltage
drop on long runs is not checked. Work: the new `service_entrance`, 1 set
(1 skilled electrician and 1 helper; 1 set a day, our estimate).

### Water heater (Plumbing)

| Step | Formula |
| --- | --- |
| Heaters (main item) | single-point instant [default], multi-point instant, or storage tank of 30 [default] or 50 L |
| Connections per heater | 1 angle valve, 1 flexible hose (single-point) or 2 (others), 4 wall plugs; teflon ⌈heaters × joints ÷ 40⌉, 3 joints single-point and 4 others |
| PPR PN20 pipe, ½" [default] or ¾" (optional run) | ⌈run × 1.10 ÷ 4⌉ pipes |
| PPR fittings | ⌈run ÷ 2⌉ + 2 adapters per heater |
| Foam insulation (optional) | ⌈run × 1.05 ÷ 2⌉ sleeves |

Works: the new `water_heater` in sets (1 skilled plumber, 0.5 helper; 2 a
day, our estimate) and piping in m for the run, which the pipe, fittings and
sleeves go to. The dedicated circuit is not bought here: the help and note
point to the Electrical Rough-in's appliance circuits. Its sizing in the
help is current = power ÷ 230 V, × 1.25 for a continuous load (NEC 422.13
treats storage heaters as continuous; the same margin is applied to instant
heaters as common practice), on the PEC small-conductor limits (20 A on
3.5 mm², 30 A on 5.5 mm²): 3.5 kW → 15.2 A → 20 A; 4.5 kW → 19.6 A → 30 A;
6–8 kW → 26–35 A → 40 A on 8.0 mm². One fitting per 2 m and the joint counts
are our estimates.

### Bathroom accessories (Plumbing)

| Step | Formula |
| --- | --- |
| Per bathroom [default] | sets (main item) = bathrooms, each a 4-piece set: towel bar, toilet paper holder, soap dish, robe hook |
| Extras per bathroom | mirror [default], medicine cabinet or none; grab bars 0 [default], 1 or 2; shower curtain rod no [default] or yes |
| By the piece | one accessory × quantity |
| Grade | economy, standard [default] or premium: the price book item for every piece |
| Work | pieces mounted = bathrooms × (4 + mirror + grab bars + rod), or the quantity |

Work: the new `bath_accessory` in pieces (1 skilled worker; 8 a day, drilling
tile and setting plugs; our estimate). Accessories come with their screws
and plugs, so none are added.

#### New work items: fences, roof edges and house services

| Key | Description | Unit | Crew | Output a day | DPWH |
| --- | --- | --- | --- | ---: | --- |
| steel_gate | Steel gate, set on its posts with hinges or track | m² | 1 skilled, 1 helper, welding machine | 4 | — |
| fascia_board | Fascia board, installed | m | 1 skilled, 1 helper, 0.5 scaffold | 15 | — |
| eaves_soffit | Eaves soffit, boards or panels on metal furring | m² | 1 skilled, 1 helper, scaffold | 8 | — |
| roof_flashing | Roof flashing, lapped and sealed | m | 1 skilled, 0.5 helper | 20 | — |
| service_entrance | Service entrance: riser, entrance cap, meter base and service wires | set | 1 skilled, 1 helper | 1 | — |
| water_heater | Water heaters, mounted, connected and tested | set | 1 skilled, 0.5 helper | 2 | — |
| bath_accessory | Bathroom accessories, drilled and mounted | pc | 1 skilled | 8 | — |

All outputs are our estimates for small jobs, set against similar items in
the work list (ceiling 10 m², gutters 20 m, showers 3 sets a day). The fence
uses the existing masonry, plaster, concrete, rebar, formwork and painting
items.

#### New price book items: fences, roof edges and house services

Metro Manila retail, VAT included, late 2026. **Every price is our
estimate** (`estimate: true`): searches in October 2026 found no usable
retailer listing for most of them. Check them with your supplier.

| Key | Item | Unit | Price (₱) | Basis |
| --- | --- | --- | ---: | --- |
| steel_gate_m2 | Steel gate leaf, tubular frame with infill, fabricated and primed | m² | 4,500 | Estimate: 25–30 kg/m² at AEDO's ₱115–185/kg fabricated; fabricators quote "a few thousand pesos per m²" |
| steel_gate_set | Steel gate, fabricated and primed, about 3.0 × 1.8 m | set | 24,000 | 5.4 m² at the m² price |
| gate_hinge | Gate hinge, heavy duty, weld-on | pc | 250 | Estimate |
| drop_bolt | Drop bolt for gates, 12" | pc | 300 | Estimate |
| gate_latch | Gate latch with padlock hasp | set | 450 | Estimate |
| gate_wheel | Sliding gate wheel, V-groove 4", with bracket | pc | 650 | Estimate |
| gate_guide | Sliding gate top guide rollers with bracket | set | 550 | Estimate |
| gate_stopper | Sliding gate end stopper | pc | 150 | Estimate |
| square_tube_4 | Square steel tube 4" × 4" × 3 mm, 6 m | length | 3,600 | Estimate: about 54 kg at ₱65/kg |
| fiber_cement_board_9 | Fiber cement board 9 mm 4×8 | sheet | 950 | Estimate, scaled from the 4.5 mm board (₱560) |
| lumber_1x6_12ft / lumber_1x8_12ft / lumber_1x10_12ft | Good lumber 1" × 6" / 8" / 10" × 12 ft, S4S | pc | 420 / 560 / 700 | 6, 8 and 10 bd ft at the price book's ₱70 |
| fascia_metal_m | Fascia cover, pre-painted GI, roll-formed | m | 280 | Estimate, near the pre-painted gutter (₱300/m) |
| pvc_soffit_panel | PVC soffit panel 200 mm × 3.0 m | pc | 180 | Estimate; AEDO puts PVC ceilings at ₱484–793/m² installed |
| pvc_soffit_trim | PVC soffit trim (J-channel), 3.0 m | pc | 120 | Estimate |
| flashing_wall | Wall or apron flashing, pre-painted GI, 300 mm girth, 2.4 m | pc | 350 | Estimate; one BOQ lists wall flashing at ₱357 a piece |
| flashing_valley | Valley flashing, pre-painted GI, 600 mm girth, 2.4 m | pc | 650 | Estimate, by girth |
| flashing_gable | Gable (barge) flashing, pre-painted GI, 400 mm girth, 2.4 m | pc | 450 | Estimate, by girth |
| wall_plug | Plastic wall plug with screw, 6 mm | pc | 5 | Estimate |
| meter_base | Meter base (socket), 1-phase, from the utility | pc | 1,500 | Estimate |
| rsc_pipe_0_75 / rsc_pipe_1 | RSC pipe ¾" / 1", 3 m | length | 900 / 1,300 | Estimate |
| imc_pipe_0_75 / imc_pipe_1 | IMC pipe ¾" / 1", 3 m | length | 650 / 950 | Estimate, about 70% of RSC |
| entrance_cap_0_75 / entrance_cap_1 | Entrance cap (weatherhead) | pc | 250 / 320 | Estimate |
| rsc_coupling_0_75 / rsc_coupling_1 | RSC coupling | pc | 60 / 85 | Estimate |
| rsc_elbow_0_75 / rsc_elbow_1 | RSC elbow 90° | pc | 250 / 350 | Estimate |
| locknut_bushing_0_75 / locknut_bushing_1 | Locknut and bushing | set | 45 / 60 | Estimate |
| pipe_strap_0_75 / pipe_strap_1 | Two-hole pipe strap | pc | 15 / 20 | Estimate |
| utility_connection | Utility service application and bill deposit | lot | 4,000 | Estimate: about one month's bill for a small house |
| water_heater_single | Water heater, single-point instant, 3.5–4.5 kW | set | 5,500 | Estimate; a review lists the Joven SF7 from ₱4,299 |
| water_heater_multi | Water heater, multi-point instant, 6–8 kW | set | 15,000 | Estimate |
| water_heater_storage_30 / _50 | Water heater, storage tank, 30 / 50 L | set | 11,000 / 14,000 | Estimate |
| ppr_fitting_0_5 / ppr_fitting_0_75 | PPR fitting, average of elbow, tee, coupling or adapter | pc | 45 / 70 | Estimate |
| pipe_insulation_0_5 / pipe_insulation_0_75 | Pipe insulation, closed-cell foam, 2 m | pc | 90 / 110 | Estimate |
| bath_set4_* | Bathroom accessory set: towel bar, paper holder, soap dish, hook | set | 900 / 2,200 / 5,500 | Estimate (economy / standard / premium) |
| bath_towel_bar_* | Towel bar, 60 cm | pc | 350 / 800 / 2,000 | Estimate |
| bath_paper_holder_* | Toilet paper holder | pc | 200 / 450 / 1,200 | Estimate |
| bath_soap_dish_* | Soap dish, wall-mounted | pc | 150 / 400 / 1,000 | Estimate |
| bath_robe_hook_* | Robe hook | pc | 100 / 250 / 700 | Estimate |
| bath_grab_bar_* | Grab bar, stainless, 60 cm | pc | 600 / 1,200 / 3,000 | Estimate |
| bath_mirror_* | Bathroom mirror, about 50 × 70 cm | pc | 700 / 1,500 / 4,000 | Estimate |
| bath_cabinet_* | Medicine cabinet with mirror door | pc | 1,800 / 3,500 / 8,000 | Estimate |
| bath_curtain_rod_* | Shower curtain rod, adjustable | pc | 300 / 700 / 1,800 | Estimate |

`*` is `economy`, `standard` or `premium`. Reused items: blocks, cement,
sand, gravel, 10 and 12 mm bars, tie wire, marine plywood, coco lumber,
nails, neutralizer, primer, latex, enamel, thinner, 1½" angle bar, ⅜"
expansion anchors, 4.5 mm fiber cement board, metal furring, wall angle,
board screws, tek screws, ridge roll, sealant, THHN wire, ground rod,
electrical tape, PPR pipe, angle valves, flexible hoses and teflon tape.

Sources read in October 2026, mostly as search excerpts:
[AEDO steel fabrication cost](https://aedoconstruction.com/blog/structural-steel-fabrication-erection-cost-per-kg-philippines/),
[AEDO ceiling cost](https://aedoconstruction.com/blog/ceiling-installation-repair-cost-philippines/),
[filipinoengineer.com on PEC 2017 ampacity](https://filipinoengineer.com/blog/2026/04/pec-2017-motors-motor-circuits-controllers-for-a-single-motor.html),
[NEC ampacity chart](https://www.lapptannehill.com/resources/technical-information/ampacity-chart),
[EC&M on the 83% dwelling rule](https://www.ecmweb.com/national-electrical-code/qa/article/20902669/stumped-by-the-code-rule-for-sizing-service-conductors-for-dwellings),
[IAEI on grounding conductor sizes](https://iaeimagazine.org/electrical-fundamentals/sizing-of-conductors-related-to-grounding-bonding/),
[Meralco: start or modify service](https://company.meralco.com.ph/faq-about/start-or-modify-service),
[ProductNation water heaters](https://productnation.co/ph/appliances/small/27543/best-water-heater-philippines).

## Room schedule

A project can hold a room schedule (project menu → **Room schedule**). Each
room is entered once: its name and level (floor), its length and width, or
its floor area and wall length when it is not a rectangle, its ceiling
height, its doors and windows, and its finishes: floor, walls (paint, or
tiles to a height with paint above), ceiling boards and ceiling paint, and
optionally its light points and outlets. **Update finishes from rooms**
turns the rooms into ordinary estimates made with the calculators above.
The code is in [`lib/data/rooms.dart`](../lib/data/rooms.dart).

**Room geometry.** For a room with wall length P (2 × (length + width) for
a rectangle; 4 × √area when a room given by its area has no wall length),
ceiling height H, wall tiles to height t (at most H) and openings each
w wide and h high on a sill s (0 for doors):

| Quantity | Formula |
| --- | --- |
| Floor and ceiling | length × width, or the area entered |
| Openings between heights a and b | Σ count × w × max(0, min(s + h, b) − max(s, a)) |
| Wall tiles | P × t − openings between 0 and t |
| Wall paint | P × (H − t) − openings between t and H (t = 0 for painted walls) |
| Skirting | P − Σ door widths, when the floor takes one and the walls are not tiled |

So a window from 0.9 to 2.1 m in a kitchen tiled to 1.2 m takes 0.3 m of its
height out of the tiles and 0.9 m out of the paint.

**One estimate per finish and level.** Rooms on the same level (matched
ignoring case and spaces) that share a finish make one estimate, named
after the level and the part, with the rooms in its note, e.g.
"Ground floor, floors – Tiles 60 × 60 cm. Rooms: Living, Dining, Kitchen."
The finishes and their calculators:

| Finish | Calculator | Grouped by | What the rooms give it |
| --- | --- | --- | --- |
| Floor tiles | Tiles | Tile size | Floor, and the skirting cut from the same tiles |
| SPC, laminate, cement topping | Floor finishes | Finish | Floor; skirting trims and a doorway per door for planks |
| Carpet | Carpet | – | Floor |
| Wall tiles | Tiles | Tile size | Net tiled area as length × the highest tile height |
| Wall paint | Paint | – | Painted band as length × the highest painted height, and the openings in it |
| Ceiling boards | Ceiling | Board | Ceiling |
| Ceiling paint | Paint | – | Ceiling |
| Light points, outlets | Light bulb, Outlet | – | The count, in "Number of" mode |

A single rectangular room gives a floor calculator its own length and
width. Several rooms, or a room given by its area, are measured as one
square of the same total area (side rounded to the millimetre), so tiles
and boards are counted from the area and the calculator's waste allowance
covers the cuts at each room's edges; the ceiling's wall angle is then
measured round that square, which is shorter than round each room. Wall
lengths are exact, since paint and wall tiles take a length and a height.

**Keeping them up to date.** Estimates made from rooms are marked with a
`source` (`rooms:<level>|<part>:<kind>`, saved with the estimate). Updating
the finishes replaces each marked estimate with the one made now for the
same level and finish, in the same place in the project and with the same
id (so progress billings stay attached); finishes no longer in the rooms
are removed and new ones are added at the end. The user's own estimates are
never touched, and a duplicated finish becomes the user's own. Only the
measurements come from the rooms: options (tile layout, buying by the box,
coats, framing…), the main price and the companions' prices set on the
estimate are kept; new estimates are priced from the price book, as when
adding from a calculator. The project's floor area is filled in from the
rooms while it is empty or still the rooms' earlier total. The house
wiring (rough-in) is not made from the rooms, since it also needs the
aircon and appliance circuits.

## Accuracy and validation

### How the tests check the formulas

Each calculator is tested with hand-worked examples: the expected numbers are
worked out by hand in the test comments, then compared with what the app's
own `calculate` function returns.

- [`test/materials/structure_test.dart`](../test/materials/structure_test.dart):
  blocks, plywood, insulation, ceiling, bar cutting, slabs, footings, columns
  and beams.
- [`test/materials/structure_extras_test.dart`](../test/materials/structure_extras_test.dart):
  laying and plaster lines of block walls and their unit price analyses, slab
  edge forms, form reuse, beam sides under a slab, tie beams, wall footings,
  lintels and stiffeners, and pavements.
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
| 10 × 3 m wall of 4" CHB, defaults | 394 blocks; laying 16 bags and 1.5 m³ sand, plaster 12 bags and 1 m³ sand; 22 bars of 10 mm, 1 kg tie wire |
| Slab on fill 10 × 5 × 0.10 m | 40 bags (Class B), 3 m³ sand, 5.5 m³ gravel, 5 m³ bedding, 48 bars, 2 kg tie wire, 3 m² of edge forms (1 sheet) |
| 20 m wall footing 0.60 × 0.20 m, 1.0 m deep | 23 bags, 8 bars of 12 mm, 15 bars of 10 mm, 24 m³ excavation, 18.3 m³ backfill |
| 12 m 4" wall, 2 doors, 3 windows | 0.42 m³, 4 bags, 25 bars of 10 mm, 8.94 m² of forms |
| 8 × 3 m driveway, 100 mm, defaults | 23 bags, 28 bars of 10 mm, 1 sealant, 2 gallons curing compound, 2.5 m³ gravel base |
| 4 columns 0.30 × 0.30 × 3 m | 11 bags, 16 bars of 16 mm, 17 bars of 10 mm, 3 kg tie wire, 2 plywood sheets, 41 bd ft, 4 kg nails |
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
  into beams; kitchen-counter outlets; voltage drop on the service entrance; pipe
  fittings by count (an allowance is used instead); paint or varnish on doors.
- **Bars.** Offcuts are not reused, which slightly overstates short bars. The
  40 d lap suits Grade 33–40 bars; Grade 60 bars need about 57 d in tension.
  Tie wire is 0.30 m per crossing up to 12 mm bars and 0.40 m for larger
  bars, by the main bar size in footings, columns and beams. 10 mm bars at 0.40 m on a
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
