# Prices and costing

This page covers the price book that fills every calculator, how a project
turns material costs into a budget or a bid, and the files a project
exports. For how quantities are worked out, see
[How BuildQuantify calculates](calculations.md).

> **Planning figures only.** The default prices are a snapshot of Metro
> Manila retail prices from August to October 2026. They drift every month,
> differ between suppliers and towns, and seven in ten of them are our own
> estimates. Every total in BuildQuantify is a planning figure for budgeting.
> It is not a quotation, a bid price or an approved budget for a contract.
> Check prices with your suppliers before you buy or bid.

## The price book

### How a price is chosen

- Every item has a default price in pesos: a Metro Manila retail price,
  VAT included, as the sources list it.
- The **suggested price** is the default price × the region factor, rounded
  to the centavo
  ([`PriceBookController`](../lib/state/price_book_controller.dart)).
- **Your own price** replaces the suggested one. It is used as you typed it,
  in every region.
- Each calculator fills its price field from the price book entry that
  matches the options you chose, such as a 6" block, an 8 ft corrugated
  sheet or a box of 3.5 mm² wire (`priceRef` in each spec). Typing a
  different price in the field uses it for that estimate only.
- Companion materials are priced from the same book when the estimate is
  made. Changing a companion's price from a calculator result saves it to
  your price book for later estimates.
- An estimate keeps the prices it was made with. Changing the price book
  later does not change saved estimates. To re-price a project, change a
  line's price in the project's **To buy** list: that updates every line of
  that material in the project, main materials and companions alike, and
  saves the price to your price book.
- Allowance lots are not in the price book. The PVC fittings allowance is
  40% of the pipe price you enter.
- Items marked **Estimate, check locally** in the app are our own estimates
  (`estimate: true` in the item files).

### Sources and dates

The default prices were gathered for **Metro Manila, August to October
2026** (`priceListLabel` in [`items.dart`](../lib/materials/items.dart)). Of
the 166 items listed, 27 come from DTI's monitored prices, 21 from retailer
listings and cost blogs, and 118 are our own estimates.

| Group | Where the defaults come from |
| --- | --- |
| Cement and aggregates | Cement: DTI e-Presyo, NCR, August 2026 (₱208–280; brands prevail at ₱230–265) and AEDO 2026 (₱240–300). Sand and gravel: constructioncost.ph, PHILCON PRICES Q1 2026 (pick-up, VAT excluded) and totalcalchub 2026; delivered prices run about 30% above pick-up. Gravel bedding: estimate. |
| Masonry | 4" and 6" blocks: DTI, NCR, August 2026 prevailing prices. 8" blocks: estimate. |
| Reinforcing steel | 10 and 12 mm: DTI, August 2026, CALABARZON and Central Luzon, because DTI has no NCR rebar entries for June to August 2026. 16 and 20 mm: AEDO (August 2026) and Cebu Steel (March 2026), about ₱40/kg. 25 mm: not in the research notes; ₱940 matches about ₱40/kg (3.85 kg/m × 6 m) and is flagged as an estimate. Tie wire: DTI, NCR. |
| Lumber and boards | Plywood: DTI, August 2026, CALABARZON, Central Luzon and Cebu (DTI has no recent NCR plywood data), and a 2026 plywood price list; 9 mm is an estimate. Coco lumber: retailer listings, partly dated (₱27–48 per bd ft). Good lumber: estimate based on a 2019–2021 list. Nails: DTI, NCR. Fiber cement and gypsum boards: Citizen Flanges, Cebu Home Builders and Wilcon (₱495 for 9 mm gypsum). |
| Ceiling framing | Furring, carrying channel and wall angle: hardware listings (Topmost, Citizen Flanges, Hardware Zone); the channel's gauge was not stated. Board screws and hanger wire: estimates. |
| Roofing and insulation | Corrugated GI: DTI, NCR, June–August 2026 (8 ft gauge 26 at ₱450–820), set at ₱78 per foot of length. Long-span: Citizen Flanges and Ranflex (September 2026); sources disagree by about 2×. Tek screws, C-purlins, ridge roll, gutter and 50 m foam: retailer listings, 2025–2026. Downspout, 25 m foam, foil tape and umbrella nails: estimates. |
| Paint and finishes | Boysen as the reference brand, from Wilcon and DIY Hardware listings (latex ₱688–740, enamel ₱896, primer ₱829–960). Putty: a Tacloban dealer (₱282). Neutralizer: a 1 L Lazada listing (₱318–446). Semi-gloss (only a 1 L price was found), skim coat, thinner, sandpaper, wallpaper and paste: estimates. |
| Tiles and floor finishes | All estimates. |
| Doors and windows | All estimates. The window rate is ₱450 per ft² supplied and installed, about ₱4,850 per m². |
| Electrical | LED bulbs: DTI, NCR, August 2026 (9 W prevails at ₱90–159). Switch: DTI, NCR (snap switches ₱45–50, tumbler switches ₱120–150). Wire, conduit, boxes, devices, breakers and panels: estimates; wire cut by the metre is the box price ÷ 150 + 15%. Check wire first, because it follows copper prices. |
| Plumbing and plumbing fixtures | All estimates. |

Main sources:

- DTI Consumer Protection and Advocacy Bureau, *Monthly Price Monitoring for
  Construction Materials*, August 2026, all regions (consolidated 7 September
  2026, posted 4 October 2026), on the
  [e-Presyo file index](https://dtiwebfiles.s3.ap-southeast-1.amazonaws.com/e-Presyo/Monthly%20Monitored%20Prevailing%20Price/Construction%20Materials%20/index.html).
  Prices are the most common retail price per product and region. DTI
  notes that the data are subject to verification and correction.
- [Wilcon online shop](https://shop.wilcon.com.ph/products/paints-sundries/paints.html)
  and other retailer listings, read in October 2026.
- AEDO Construction 2026 price guides for
  [cement](https://aedoconstruction.com/blog/cement-price-per-bag-philippines-2026/)
  and [rebar](https://aedoconstruction.com/blog/steel-rebar-price-philippines-2026/).
- [constructioncost.ph](https://constructioncost.ph/blog/construction-material-prices-philippines),
  [PHILCON PRICES](https://philconprices.com/construction-material-prices/),
  [Citizen Flanges long-span](https://www.citizenflanges.com/long-span-roof-price-philippines.html),
  [Ranflex roof sheets](https://www.ranflexmetals.com/ph/roof-sheet-price-list.html)
  and [C-purlins](https://www.ranflexmetals.com/ph/c-purlins-price-list.html).

Prices were read from search-result excerpts in October 2026, because most
retailer sites could not be opened directly. Prices drift: DTI's prevailing
cement price in NCR rose from about ₱180–245 in 2025 to ₱210–265 in June to
August 2026, and PSA's construction materials retail price index for NCR was up
1.2–1.3% year on year in early 2026.

### Regional factors

Choose the project's region at the top of the price book (**Where is the
project?**). One factor scales every default price
([`PriceRegion`](../lib/materials/items.dart)).

| Region | Factor |
| --- | --- |
| Metro Manila and nearby | 1.00 |
| Rest of Luzon | 1.08 |
| Visayas | 1.08 |
| Mindanao | 1.08 |
| Island provinces and remote sites | 1.20 |

The factors are rounded from DTI's August 2026 regional prices. Medians of
the prevailing prices, with the Luzon core (NCR, Central Luzon and
CALABARZON) as 100%:

| Item | Other Luzon | Visayas | Mindanao |
| --- | ---: | ---: | ---: |
| Cement, 40 kg | 119% | 107% | 110% |
| Rebar 10 mm × 6 m | 121% | 117% | 112% |
| Rebar 12 mm × 6 m | 109% | 117% | 116% |
| Tie wire, per kg | 106% | 101% | 106% |
| Common nails, per kg | 100% | 88% | 100% |
| Marine plywood 18 mm | 106% | 101% | 86% |
| LED bulb 9 W | 125% | 99% | 112% |

Steel is the most consistent, at about 10–20% more outside the Luzon core.
Cement can be cheaper near a plant (Cebu, Davao) and dearer on islands
(MIMAROPA and Bicol medians are ₱262). The +20% for remote sites follows
AEDO's rule of thumb of +15–25% for island provinces and places far from a
plant. The factor is applied to every item, including ones DTI does not
track, so treat regional prices as rougher than Metro Manila ones.

### Default price list

Generated from
[`items_structure.dart`](../lib/materials/items_structure.dart),
[`items_finishes.dart`](../lib/materials/items_finishes.dart) and
[`items_mep.dart`](../lib/materials/items_mep.dart), in the order the price
book shows them. Prices are Metro Manila; multiply by the region factor.
**Estimate: yes** marks our own estimates. **†** marks items no calculator
uses yet; they are there for your own pricing.

#### Cement and aggregates

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Portland cement, 40 kg | bag | 240 |  |
| Washed sand | m³ | 1,500 |  |
| Gravel, ¾" | m³ | 1,800 |  |
| Gravel bedding | m³ | 1,000 | yes |

#### Masonry

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Concrete hollow block 4" | pc | 24 |  |
| Concrete hollow block 6" | pc | 32 |  |
| Concrete hollow block 8" | pc | 45 | yes |

#### Reinforcing steel

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Deformed bar 10 mm × 6 m | pc | 150 |  |
| Deformed bar 12 mm × 6 m | pc | 215 |  |
| Deformed bar 16 mm × 6 m | pc | 390 |  |
| Deformed bar 20 mm × 6 m | pc | 600 |  |
| Deformed bar 25 mm × 6 m | pc | 940 | yes |
| Tie wire, #16 GI | kg | 85 |  |

#### Lumber and boards

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Plywood 6 mm (¼") 4×8 | sheet | 400 |  |
| Plywood 9 mm (⅜") 4×8 | sheet | 550 | yes |
| Plywood 12 mm (½") 4×8 | sheet | 700 |  |
| Plywood 18 mm (¾") 4×8 | sheet | 1,150 |  |
| Marine plywood 6 mm (¼") 4×8 | sheet | 500 |  |
| Marine plywood 9 mm (⅜") 4×8 | sheet | 750 | yes |
| Marine plywood 12 mm (½") 4×8 | sheet | 1,000 |  |
| Marine plywood 18 mm (¾") 4×8 | sheet | 1,400 |  |
| Coco lumber, rough | bd ft | 38 |  |
| Good lumber, S4S | bd ft | 70 | yes |
| Common wire nails | kg | 85 |  |
| Fiber cement board 4.5 mm 4×8 | sheet | 560 |  |
| Gypsum board 9 mm 4×8 | sheet | 500 |  |

#### Ceiling framing

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Metal furring, 5 m | pc | 125 |  |
| Carrying channel, 5 m | pc | 140 |  |
| Wall angle, 3 m | pc | 60 |  |
| Board screws, box of 100 | box | 120 | yes |
| Hanger wire, #10 GI | kg | 90 | yes |

#### Roofing and insulation

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Corrugated GI sheet, gauge 26, 5 ft | sheet | 390 |  |
| Corrugated GI sheet, gauge 26, 6 ft | sheet | 468 |  |
| Corrugated GI sheet, gauge 26, 7 ft | sheet | 546 |  |
| Corrugated GI sheet, gauge 26, 8 ft | sheet | 624 |  |
| Corrugated GI sheet, gauge 26, 9 ft | sheet | 702 |  |
| Corrugated GI sheet, gauge 26, 10 ft | sheet | 780 |  |
| Corrugated GI sheet, gauge 26, 12 ft | sheet | 936 |  |
| Long-span rib-type roofing, 0.4 mm | m | 380 |  |
| Tek screw 2½" with washer | pc | 1.50 |  |
| Umbrella nail with washer † | kg | 120 | yes |
| C-purlin 2"×4" × 1.5 mm, 6 m | pc | 780 |  |
| Ridge or hip roll, 2.4 m | pc | 600 |  |
| Gutter, pre-painted | m | 300 |  |
| Downspout, PVC 3" | m | 120 | yes |
| PE foam insulation 1 × 50 m | roll | 1,800 |  |
| PE foam insulation 1 × 25 m | roll | 1,000 | yes |
| Aluminium foil tape, 50 m | roll | 250 | yes |

#### Paint and finishes

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Acrylic latex paint, flat, 4 L | gallon | 720 |  |
| Acrylic latex paint, semi-gloss, 4 L | gallon | 800 | yes |
| Quick-drying enamel, 4 L | gallon | 950 |  |
| Primer, 4 L | gallon | 850 |  |
| Masonry neutralizer, 1 L | L | 330 |  |
| Skim coat, 20 kg | bag | 500 | yes |
| Masonry putty, 4 L | gallon | 300 |  |
| Paint thinner, 1 L | L | 150 | yes |
| Sandpaper sheet, 9" × 11" | pc | 25 | yes |
| Wallpaper 0.53 × 10.05 m | roll | 800 | yes |
| Wallpaper 1.06 × 15.6 m | roll | 2,400 | yes |
| Wallpaper 0.45 × 10 m | roll | 700 | yes |
| Wallpaper paste, 200 g | pack | 150 | yes |

#### Tiles and floor finishes

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Tile 20 × 20 cm | pc | 15 | yes |
| Tile 20 × 20 cm, box of 25 | box | 375 | yes |
| Tile 20 × 30 cm | pc | 22 | yes |
| Tile 20 × 30 cm, box of 17 | box | 374 | yes |
| Tile 30 × 30 cm | pc | 35 | yes |
| Tile 30 × 30 cm, box of 16 | box | 560 | yes |
| Tile 30 × 60 cm | pc | 110 | yes |
| Tile 30 × 60 cm, box of 8 | box | 880 | yes |
| Tile 40 × 40 cm | pc | 70 | yes |
| Tile 40 × 40 cm, box of 6 | box | 420 | yes |
| Tile 60 × 60 cm | pc | 170 | yes |
| Tile 60 × 60 cm, box of 4 | box | 680 | yes |
| Tile adhesive, 25 kg | bag | 350 | yes |
| Tile grout, 2 kg | pack | 110 | yes |
| Tile spacers, pack of 100 | pack | 60 | yes |
| Broadloom carpet | m² | 800 | yes |
| Carpet tiles 50 × 50 cm, box of 20 | box | 4,000 | yes |
| Carpet underlay | m² | 200 | yes |
| Carpet gripper strip | m | 60 | yes |
| Carpet seam tape | m | 50 | yes |

#### Doors and windows

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Flush door 0.80 × 2.10 m with jamb | set | 3,800 | yes |
| Panel door 0.90 × 2.10 m with jamb | set | 9,500 | yes |
| PVC bathroom door 0.70 × 2.10 m with jamb | set | 2,800 | yes |
| Butt hinge 3½" × 3½" | pc | 90 | yes |
| Butt hinge 4" × 4", heavy duty | pc | 150 | yes |
| Door lockset, knob or lever | pc | 800 | yes |
| Entrance lockset, heavy duty | pc | 1,500 | yes |
| Aluminium sliding window, 6 mm glass, installed | m² | 4,850 | yes |
| Silicone sealant, 300 ml | tube | 180 | yes |

#### Electrical

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| THHN wire 2.0 mm², box of 150 m | box | 3,300 | yes |
| THHN wire 2.0 mm², cut | m | 25 | yes |
| THHN wire 3.5 mm², box of 150 m | box | 5,200 | yes |
| THHN wire 3.5 mm², cut | m | 40 | yes |
| THHN wire 5.5 mm², box of 150 m | box | 8,000 | yes |
| THHN wire 5.5 mm², cut | m | 61 | yes |
| THHN wire 8.0 mm², box of 150 m | box | 12,500 | yes |
| THHN wire 8.0 mm², cut | m | 96 | yes |
| THHN wire 14 mm², box of 150 m † | box | 21,000 | yes |
| THHN wire 14 mm², cut † | m | 161 | yes |
| THHN wire 22 mm², box of 150 m † | box | 32,000 | yes |
| THHN wire 22 mm², cut † | m | 245 | yes |
| THHN wire 30 mm², box of 150 m † | box | 43,000 | yes |
| THHN wire 30 mm², cut † | m | 330 | yes |
| PVC conduit ½" (20 mm), 3 m | length | 65 | yes |
| PVC conduit ¾" (25 mm), 3 m † | length | 90 | yes |
| Utility box 2"×4" | pc | 25 | yes |
| Junction box 4"×4" | pc | 30 | yes |
| Wall switch, 1-gang | pc | 60 |  |
| Switch plate | pc | 30 | yes |
| Convenience outlet, duplex, with plate | pc | 150 | yes |
| Aircon outlet, 250 V, with plate | pc | 220 | yes |
| LED bulb 5 W | pc | 80 |  |
| LED bulb 7 W | pc | 95 |  |
| LED bulb 9 W | pc | 115 |  |
| LED bulb 12 W | pc | 150 |  |
| LED bulb 15 W | pc | 190 |  |
| LED bulb 18 W | pc | 230 |  |
| Lamp holder, E27 | pc | 40 | yes |
| Circuit breaker 15 A, plug-in | pc | 350 | yes |
| Circuit breaker 20 A, plug-in | pc | 350 | yes |
| Circuit breaker 30 A, plug-in | pc | 380 | yes |
| Circuit breaker 40 A, plug-in † | pc | 450 | yes |
| Circuit breaker 60 A, plug-in † | pc | 650 | yes |
| Circuit breaker 100 A, plug-in † | pc | 1,800 | yes |
| Panel board, 4 branches, with main | pc | 1,500 | yes |
| Panel board, 6 branches, with main | pc | 2,000 | yes |
| Panel board, 8 branches, with main | pc | 2,500 | yes |
| Panel board, 12 branches, with main | pc | 3,500 | yes |
| Panel board, 16 branches, with main | pc | 4,800 | yes |
| Panel board, 20 branches, with main | pc | 6,000 | yes |
| Panel board, 24 branches, with main | pc | 7,500 | yes |
| Panel board, 30 branches, with main | pc | 9,000 | yes |
| Ground rod 16 mm × 2.4 m with clamp | set | 650 | yes |
| Electrical tape | roll | 35 | yes |

#### Plumbing

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| PVC pressure pipe (blue) ½" (20 mm), 3 m | pc | 90 | yes |
| PVC pressure pipe (blue) ¾" (25 mm), 3 m | pc | 120 | yes |
| PVC pressure pipe (blue) 1" (32 mm), 3 m | pc | 190 | yes |
| PVC sanitary pipe (orange) 2" (57 mm), 3 m | pc | 220 | yes |
| PVC sanitary pipe (orange) 3" (82 mm), 3 m | pc | 340 | yes |
| PVC sanitary pipe (orange) 4" (107 mm), 3 m | pc | 460 | yes |
| PPR pipe PN20 ½" (20 mm), 4 m | pc | 250 | yes |
| PPR pipe PN20 ¾" (25 mm), 4 m | pc | 380 | yes |
| PPR pipe PN20 1" (32 mm), 4 m | pc | 600 | yes |
| Solvent cement, 100 cc | can | 75 | yes |
| Teflon tape | roll | 20 | yes |
| Cleanout plug, 4" † | pc | 150 | yes |
| Float valve, ¾" | pc | 450 | yes |

#### Plumbing fixtures

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Water closet with tank | set | 5,500 | yes |
| Squat toilet bowl | pc | 1,200 | yes |
| Lavatory (bathroom basin) | set | 2,500 | yes |
| Kitchen sink, stainless | pc | 2,500 | yes |
| Faucet, chrome | pc | 700 | yes |
| Shower set (head with arm or hose) | set | 1,500 | yes |
| Angle valve ½" | pc | 250 | yes |
| Flexible hose ½" | pc | 150 | yes |
| P-trap | pc | 250 | yes |
| Wax ring | pc | 120 | yes |
| Closet bolt set | set | 80 | yes |
| Floor drain 4" × 4", stainless | pc | 250 | yes |
| Shower valve | pc | 600 | yes |
| Water tank, polyethylene, 500 L | pc | 5,000 | yes |
| Water tank, polyethylene, 1,000 L | pc | 8,000 | yes |
| Water tank, polyethylene, 1,500 L | pc | 11,000 | yes |
| Water tank, polyethylene, 2,000 L | pc | 14,000 | yes |
| Septic tank, polyethylene, 2,000 L, 2-chamber | pc | 25,000 | yes |

Not listed: the allowance lots for PVC fittings and conduit fittings, which
have no unit price of their own.

## Project cost build-up

Calculators price materials and measure the work. A project adds labour,
tools, equipment, hauling, general requirements, contingency, markups and
VAT in its **Budget** section (a tab on phones). The model is in
[`lib/data/project.dart`](../lib/data/project.dart) (`CostSettings` and
`CostBreakdown.of`) and
[`lib/data/unit_prices.dart`](../lib/data/unit_prices.dart) (crews and unit
price analyses).

### Materials by trade

Each estimate belongs to the trade of its calculator: structural,
architectural, electrical or plumbing. Entries from the original app, which
did not record a calculator, go under **Other works**. A trade's materials
are the sum of its estimates' materials totals, companions included.

### The formula

```
materials      = Σ materials of each trade
labour         = Σ crew-days × crew's daily labour     (by crew output)
               or Σ (materials of the trade × labour %) (% of materials)
equipment      = Σ crew-days × crew's daily equipment rental
minor tools    = labour × tools %
general        = Σ general requirement lump sums
direct cost    = materials + labour + minor tools + equipment + hauling
                 + general requirements
escalation     = direct cost × price escalation %
contingency    = direct cost × contingency %
overhead (OCM) = direct cost × overhead %
profit         = direct cost × profit %
subtotal       = direct cost + escalation + contingency + overhead + profit
VAT            = subtotal × VAT %
total          = subtotal + VAT
```

- Each line is rounded to the centavo.
- Labour is priced **by crew output** (the default for new projects; see
  below) or as **% of materials**, chosen under Budget → Labour. With a
  percentage, a trade can have its own under **Labour by trade**; empty
  trades use the main one. Projects saved before crews existed keep the
  percentage.
- Hauling and delivery is a lump sum in pesos.
- Contingency, overhead and profit are each a percentage of the direct cost.
  They are not compounded on each other.
- VAT is charged on the subtotal. Price book prices already include the VAT
  paid on materials; the VAT line is the tax on the contract price.
- The last line reads **Project budget**, or **Total contract price** when
  overhead, profit or VAT is above zero.

### Labour by crews

Every calculator reports the work it measures, in the units of a bill of
quantities: concrete in m³, reinforcing steel in kg (the net weight of the
bars as placed, laps included), formwork, walls, plaster, tiles and paint in
m², pipes and wire in metres, fixtures by the set. Each work item has a
crew and the output that crew usually achieves in an eight-hour day:

```
crew-days        = quantity × effort ÷ (output × productivity)
labour           = crew-days × (foremen × foreman rate
                                + skilled × skilled rate
                                + helpers × helper rate)
equipment        = crew-days × Σ (units × daily rental)
```

- **Effort** multiplies the time for work done in passes: painting is
  measured once by area and its effort is the number of coats, plus one for
  primer and one and a half for each skim coat.
- **Crew productivity** (100% by default) scales every output: 80% means
  slower crews and 25% more crew-days.
- Fractions of a foreman or helper are shared between crews.
- Estimates saved before work items existed are measured again from their
  saved inputs; an estimate that cannot be (one from the original app) is
  priced as a share of its materials.

| Work item | Unit | Crew per day | Output a day | Labour and equipment per unit | DPWH item |
| --- | --- | --- | ---: | ---: | --- |
| Structure excavation, common soil, by hand | m³ | 0.1 foreman, 1 helper | 3 | ₱346.67 | 103 |
| Backfill and compaction, by hand | m³ | 0.1 foreman, 1 helper | 5 | ₱208.00 | 104 |
| Gravel bedding, compacted | m³ | 0.1 foreman, 2 helpers | 5 | ₱388.00 | 200 |
| Structural concrete, footings | m³ | 0.5 foreman, 1 skilled, 4 helpers, 1 one-bagger mixer, 1 concrete vibrator | 4 | ₱2050.00 | 900 |
| Structural concrete, slab on fill | m³ | 0.5 foreman, 1 skilled, 4 helpers, 1 one-bagger mixer, 1 concrete vibrator | 6 | ₱1366.67 | 900 |
| Structural concrete, suspended slab | m³ | 0.5 foreman, 1 skilled, 6 helpers, 1 one-bagger mixer, 1 concrete vibrator | 5 | ₱2000.00 | 900 |
| Structural concrete, columns | m³ | 0.5 foreman, 1 skilled, 4 helpers, 1 one-bagger mixer, 1 concrete vibrator | 2.5 | ₱3280.00 | 900 |
| Structural concrete, beams | m³ | 0.5 foreman, 1 skilled, 4 helpers, 1 one-bagger mixer, 1 concrete vibrator | 3 | ₱2733.33 | 900 |
| Reinforcing steel, cut, bent and tied in place | kg | 0.1 foreman, 1 skilled, 1 helper | 175 | ₱12.23 | 902 |
| Formwork and falsework, made, set and stripped | m² | 0.1 foreman, 1 skilled, 1 helper | 9 | ₱237.78 | 903 |
| CHB wall, 4" | m² | 1 skilled, 1 helper | 11 | ₱181.82 | 1046 |
| CHB wall, 6" | m² | 1 skilled, 1 helper | 9 | ₱222.22 | 1046 |
| CHB wall, 8" | m² | 1 skilled, 1 helper | 7 | ₱285.71 | 1046 |
| Cement plaster finish, 16 mm | m² | 1 skilled, 1 helper, 0.5 scaffolding set | 14 | ₱164.29 | 1027 |
| Plywood sheathing, installed | m² | 1 skilled, 1 helper | 15 | ₱133.33 | – |
| Ceiling, boards on framing | m² | 1 skilled, 1 helper, 1 scaffolding set | 10 | ₱260.00 | 1013 |
| Roof insulation, foil-faced foam | m² | 1 skilled, 1 helper | 60 | ₱33.33 | – |
| Painting, per coat | m² | 1 skilled, 0.5 helper, 0.5 scaffolding set | 40 | ₱46.25 | 1032 |
| Tiles, set and grouted | m² | 1 skilled, 1 helper | 7 | ₱285.71 | 1018 |
| Tile skirting | m | 1 skilled, 0.5 helper | 25 | ₱62.00 | – |
| Roofing sheets, installed | m² | 2 skilled, 1 helper | 35 | ₱88.57 | 1014 |
| Steel purlins, installed | m | 1 skilled, 1 helper | 60 | ₱33.33 | – |
| Gutters and downspouts | m | 1 skilled, 1 helper | 20 | ₱100.00 | – |
| Doors with jambs and hardware, installed | set | 1 skilled, 1 helper | 1.5 | ₱1333.33 | 1006 |
| Aluminium windows, installed | m² | 1 skilled, 1 helper | 6 | ₱333.33 | 1010 |
| Carpet, laid | m² | 1 skilled, 1 helper | 30 | ₱66.67 | – |
| Wallpaper, hung | m² | 1 skilled, 0.5 helper | 20 | ₱77.50 | – |
| Electrical rough-in: conduit, boxes and wiring, per outlet | pt | 1 skilled, 1 helper | 6 | ₱333.33 | 1100 |
| Panel board with breakers, installed | set | 1 skilled, 0.5 helper | 1 | ₱1550.00 | 1102 |
| Building wire, pulled in conduit | m | 1 skilled, 1 helper | 300 | ₱6.67 | – |
| Lighting fixtures, installed | pc | 1 skilled, 0.5 helper | 12 | ₱129.17 | – |
| Switches and outlets, installed | pc | 1 skilled, 0.5 helper | 15 | ₱103.33 | – |
| Junction and utility boxes, installed | pc | 1 skilled | 20 | ₱55.00 | – |
| Water and drainage pipes with fittings, installed | m | 1 skilled, 1 helper | 20 | ₱100.00 | 1200 |
| Water closets, installed | set | 1 skilled, 0.5 helper | 1.5 | ₱1033.33 | – |
| Lavatories and sinks, installed | set | 1 skilled, 0.5 helper | 3 | ₱516.67 | – |
| Faucets, installed | pc | 1 skilled, 0.5 helper | 10 | ₱155.00 | – |
| Shower sets, installed | set | 1 skilled, 0.5 helper | 3 | ₱516.67 | – |
| Water or septic tanks, set in place | set | 1 skilled, 2 helpers | 1 | ₱2900.00 | – |
| Septic tank, CHB with concrete slabs, built on site | m³ | 0.2 foreman, 1 skilled, 2 helpers | 0.5 | ₱6360.00 | 1203 |

Outputs are planning norms in line with Fajardo's *Simplified Construction
Estimate* and DPWH detailed unit price analyses for small buildings. Real
outputs vary with the site, access, weather and the crew; adjust **Crew
productivity**, or the rates, to match yours. The per-unit column uses the
default rates below.

#### Daily rates

| Rate | Default, a day |
| --- | ---: |
| Foreman | ₱1,400 |
| Skilled worker (mason, carpenter, steelman, electrician, plumber, painter) | ₱1,100 |
| Helper | ₱900 |
| One-bagger concrete mixer | ₱1,800 |
| Concrete vibrator | ₱1,000 |
| Plate compactor | ₱2,000 |
| Scaffolding set | ₱600 |

Labour rates are for Metro Manila in late 2026: the minimum wage is ₱755 a
day from 26 September 2026, and the rates add the employer's share of
13th-month pay and SSS, PhilHealth and Pag-IBIG contributions, as DPWH's
labour cost factor does. Provincial minimum wages are lower; enter what you
pay under Budget → Daily rates. Equipment rates are typical day rentals.

### Unit price analysis

Each project item's details show a **unit price analysis** per work item,
like a DPWH DUPA:

```
materials        the estimate's materials that go into this work item
labour           crew-days × daily rates, by trade level
minor tools      labour × tools %
equipment        crew-days × daily rentals
direct cost      the sum of the above
unit cost        direct cost ÷ quantity
markups          direct cost × (contingency + overhead + profit) %
VAT              (direct cost + markups) × VAT %
unit price       (direct cost + markups + VAT) ÷ quantity
```

Materials are split between an estimate's work items: bars and tie wire go
to the reinforcing steel, plywood, lumber and nails to the formwork, gravel
bedding to the bedding, materials a calculator names to their work (purlins,
gutters, breakers), and the rest to the main work. A CHB wall's cement and
sand for laying and plaster are one line, so they stay with the wall.

### General requirements

Lump sums for running the site, in pesos (DPWH Part A and B items):
mobilization and demobilization; temporary facilities (bodega, toilet,
power and water); permits, clearances and fees; occupational safety and
health; the project signboard; and clean-up and disposal of debris.
**Suggest amounts** fills in about 5% of the direct cost in all (1%, 1.5%,
1%, 1% and 0.5%, rounded up to ₱500) plus ₱5,000 for a signboard; change
them to your own. They are part of the direct cost, so contingency,
overhead and profit apply to them as to hauling.

### Price escalation

Prices rise between the estimate and the purchase. **Price escalation**
under Budget adds a percentage of the direct cost, shown as its own line
before contingency. As a guide, construction prices in the Philippines have
risen about 3–6% a year: for work bought eight months from now, 3% is a
reasonable allowance. Leave it at 0 when the prices are current.

### Checks

Under the budget, **Checks** compares the project with what is usual for
houses, to catch a wrong input before the estimate goes out
([`lib/data/checks.dart`](../lib/data/checks.dart)):

| Check | Warns when | Usual |
| --- | --- | --- |
| Cost per m² of floor area (when the project has a floor area) | Below half the economy rate or above 1.5 × the premium rate | ₱36,000–50,000 a m² for a standard house |
| Reinforcing steel per m³ of concrete (CHB wall bars left out) | Below 40 or above 250 kg/m³ | 80–150 kg/m³ in houses |
| Formwork per m³ of concrete | Above 15 m²/m³ | 4–12 m²/m³ |
| Labour as a share of materials | Below 15% or above 90% | 30–60% |
| Materials without a price | Any | – |
| Age of the prices | Six months or more since the oldest item was priced | – |
| Scope that usually goes together | Concrete but no walls; walls but no paint; no electrical work | – |

The last group are notes, not warnings: a job may rightly leave them out.

### Quick budget by floor area

Home → **Quick budget by floor area** gives a range before anything is
measured: floor area × a rate per m² for the finish level, times 1.05 for
two storeys and 1.10 for three (stairs and suspended slabs).

| Finishes | Per m², contractor's price with VAT |
| --- | ---: |
| Economy: plain finishes, local fixtures | ₱28,000–36,000 |
| Standard: tiles throughout, mid-range fixtures | ₱36,000–50,000 |
| Premium: stone, engineered wood, imported fixtures | ₱50,000–75,000 |

It splits the midpoint as houses usually do: structural 45%, architectural
33%, electrical 8%, plumbing 9% and general requirements 5%. The rates are
our own reading of published 2024–2025 Philippine cost-per-m² guides,
raised for 2026; they are for a first conversation, never for a contract.
**Estimate this house item by item** starts a project with the house
checklist and the floor area filled in.

### Presets

| Setting | Owner | Contractor | DPWH |
| --- | ---: | ---: | ---: |
| Minor tools, % of labour | 0 | 10 | 10 |
| Contingency, % of direct cost | 10 | 5 | 0 |
| Overhead (OCM), % of direct cost | 0 | 10 | 15, 12, 10 or 8 |
| Profit, % of direct cost | 0 | 10 | 10 or 8 |
| VAT, % of subtotal | 0 | 12 | 5 |

- **Owner** is for an owner hiring workers directly: labour and a margin for
  surprises, with no contractor markups.
- **Contractor** is for a private contractor's quotation.
- **DPWH** follows DPWH practice for government estimates
  (`CostSettings.dpwh` and `dpwhMarkups`). The contingency is inside the OCM.
- A new project starts as **Owner budget** or **Contractor bid**, chosen when
  it is created.
- Presets do not set labour, rates, hauling or general requirements.
  Switching presets keeps the project's own.
- Any setting can be changed; the preset then shows as none.

The DPWH preset sets OCM and profit by the size of the direct cost:

| Direct cost | OCM | Profit | Total markup |
| --- | ---: | ---: | ---: |
| Up to ₱5 million | 15% | 10% | 25% |
| Over ₱5M, up to ₱50M | 12% | 8% | 20% |
| Over ₱50M, up to ₱150M | 10% | 8% | 18% |
| Over ₱150M | 8% | 8% | 16% |

The bracket is picked from materials + labour + hauling when you choose the
preset; minor tools are left out because the preset sets them. If the
project later crosses a bracket, the preset shows as none: choose DPWH again
to re-size it.

### Worked example

₱1,000,000 of materials, 40% labour, no hauling:

| Line | Owner | Contractor | DPWH |
| --- | ---: | ---: | ---: |
| Materials | ₱1,000,000 | ₱1,000,000 | ₱1,000,000 |
| Labour, 40% | ₱400,000 | ₱400,000 | ₱400,000 |
| Minor tools, 10% of labour | – | ₱40,000 | ₱40,000 |
| **Direct cost** | **₱1,400,000** | **₱1,440,000** | **₱1,440,000** |
| Contingency | ₱140,000 (10%) | ₱72,000 (5%) | – |
| Overhead (OCM) | – | ₱144,000 (10%) | ₱216,000 (15%) |
| Profit | – | ₱144,000 (10%) | ₱144,000 (10%) |
| Subtotal before VAT | – | ₱1,800,000 | ₱1,800,000 |
| VAT | – | ₱216,000 (12%) | ₱90,000 (5%) |
| **Total** | **₱1,540,000** | **₱2,016,000** | **₱1,890,000** |

The DPWH column follows the DO 197 s.2016 build-up, and
[`test/data/project_test.dart`](../test/data/project_test.dart) checks it to
the peso: a direct cost of ₱1,440,000 falls in the "up to ₱5M" bracket, so
OCM is 15% and profit 10%; VAT at 5% gives ₱1,890,000. At 12% VAT the same
job would be ₱2,016,000.

### Where the percentages come from

| Setting | Basis | Status |
| --- | --- | --- |
| OCM and profit brackets | [DPWH DO 197 s.2016](https://www.dpwh.gov.ph/DPWH/sites/default/files/issuances/DO_197_s2016.pdf), which superseded DO 22 s.2015 | DPWH text |
| The same brackets for 2026 | [DPWH DO 30 s.2025](https://dpwh.gov.ph/DPWH/sites/default/files/issuances/do_030_s2025.pdf), for estimates from CY 2026: profit 10% up to ₱5M and 8% above; overhead 7–11%, contingencies 0.5–3% and miscellaneous 0.5–1% of the direct cost | Profit and the OCM parts from the DPWH text. That the 25/20/18/16% totals carry over comes from a secondary source (AEDO). The exact OCM table was not read. |
| VAT 5% | DO 197 s.2016 B.5: 5% of direct cost + OCM + profit | DPWH text. DO 30 s.2025 no longer fixes the rate and defers to the DPWH Finance Service (secondary source). Since 2021, VAT withheld on government payments is creditable, and 12% is the statutory rate. Some agencies use 12%; change it if yours does. |
| Minor tools, 10% of labour | DUPA forms from DPWH-style samples, WVSU and CAAP | Standard practice. Not found in the department order text; some samples use 5%. |
| Labour, 40% of materials | PH course rule of a 70/30 materials-to-labour split (about 43%); AEDO gives labour as 30–45% of residential cost | Rule of thumb |
| Contingency 10% (owner), 5% (contractor) | 10% suits a preliminary estimate and 5% a detailed bill of quantities | Rule of thumb |
| Contractor overhead and profit 10% + 10% | Private quotes are negotiated; DPWH's ₱5M bracket is 25% in total | Rule of thumb |
| VAT 12% (contractor) | The statutory VAT rate for a VAT-registered contractor | Set 0% for a non-VAT contractor |

### What the model leaves out

- Regional labour cost factors. DO 125 s.2025 sets DPWH labour rates from
  the regional minimum wage times a labour cost factor; the app uses one
  set of rates per project, which you can change.
- Heavy equipment such as backhoes and cranes, and equipment for work the
  calculators don't measure.
- Under DPWH rules, general requirements are not marked up with OCM or
  profit; the app marks them up with the rest of the direct cost.
- Professional fees, land, utility connections and the electrical service
  entrance.
- DPWH's own engineering and administrative overhead (DO 7 s.2025), which is
  deducted from the appropriation and is not part of a contractor's price.

## Contract

The project's **Contract** tab carries the job past the estimate. Its
model is in [`lib/data/contract.dart`](../lib/data/contract.dart) and
[`lib/data/contract_math.dart`](../lib/data/contract_math.dart).

### Contract lines

Every line of the bill of quantities (each estimate's work items, then
the general requirements and hauling as section F) gets its share of the
contract price: its direct cost × total ÷ direct cost, so markups and VAT
are spread in proportion and the lines add up to the total exactly (the
centavo left over from rounding goes to the largest line). Variation orders
follow as VO-1, VO-2…

### Quotation

**Download quotation** makes an A4 PDF for the client:

- the business profile from Settings (name, address, phone, email, TIN)
  and a quotation number and date, valid for the days set;
- the scope and price by section (A–F), the total contract price and the
  amount in words ("One Million … Pesos Only");
- the payment terms: downpayment (30% by default, recouped from billings),
  progress billings, retention (10% by default, released on acceptance or
  at the end of the warranty), the warranty (12 months by default), the
  days the client takes to pay (30 by default) and, for a company or
  government client, the taxes it withholds (see below);
- the schedule by phase, and the inclusions and exclusions as typed
  (**Use common exclusions** fills in permits and fees, utility
  connections, furniture and unlisted work);
- signature blocks for the contractor and the client (conforme);
- the bill of quantities with unit prices that include markups and VAT.

### Schedule

The schedule ([`lib/data/schedule.dart`](../lib/data/schedule.dart)) is
worked out from the crew-days of each work item, the crews working at once
and how the phases of building a house follow each other:

```
lane          = one trade's work in one phase, e.g. structural work in Foundations
lane days     = Σ crew-days of the lane ÷ crews in the lane (rounded up to half days)
                + 7 days of curing when it holds a suspended slab
phase days    = the longest lane in the phase
phase start   = the latest of its links (table below)
working days  = the last phase's finish × (1 + rain allowance %)
months        = (working days + regular holidays on the way) ÷ 26
```

Bars and forms go with their element (a beam's rebar is with the beams).
Trades in the same phase work side by side, so electrical and plumbing
rough-ins run alongside the walls. Items priced as a share of materials
take their labour ÷ (skilled + helper rate) as crew-days.

**Phases and links.** Each phase may start once an earlier one is part or
all of the way through, plus a lag in working days for curing or setting.
When it overlaps the earlier phase it also finishes no sooner than a set
number of days after it, since its last piece of work follows the earlier
phase's last (start-to-start and finish-to-finish links).

| Phase | Waits for |
| --- | --- |
| Mobilization and layout | Nothing; 5 days for clearing, staking, batter boards and the bodega |
| Site preparation and earthworks | Mobilization |
| Foundations | Earthworks half done; finishes 1 day after the last pit |
| Columns and ground slab (with backfill and gravel bedding) | Foundations + 3 days of curing |
| Beams, upper slabs and stairs | Columns + 3 days: the frame goes up floor by floor; a suspended slab adds 7 days of curing before the floor above |
| Walls and rough-ins | Ground slab + 2 days; the upper walls finish 3 days after the upper slab |
| Roof framing and roofing | Beams and upper slabs + 7 days of curing, and half the walls |
| Plastering and waterproofing | A third of the walls + 2 days; finishes 3 days after the last wall |
| Ceilings | The roof, and half the plaster |
| Finishes and openings | Half the plaster + 14 days, so it can be painted; finishes 14 days after the last plaster and 2 days after the ceilings |
| Fixtures | Three quarters of the finishes; finishes 2 days after them |
| Testing, punch list and turnover | Everything; 6 days |

A phase with no work in the project is skipped, and phases after it wait
for what it waited for. The **critical phases** are the chain of links
that sets the finish date: a day's delay in one of them delays the job.
The Gantt chart outlines their bars and the quotation prints them in bold.

**Crews.** A trade left on **Auto** gets its crews phase by phase: enough
for about three weeks of work (`autoLaneDays`, 18 working days), at least
one, and no more than a small site run by one foreman holds:

| Trade | Most workers at once |
| --- | ---: |
| Structural (diggers, masons, carpenters, steelmen, concrete gang) | 8 |
| Architectural (roofing, tiles, paint, doors and windows) | 4 |
| Electrical | 2 |
| Plumbing | 2 |
| Other works | 3 |

Crews in a lane = ⌈lane crew-days ÷ 18⌉, capped at ⌊workers ÷ workers in
one crew⌋, where the crew is the work item's (a digger is one helper, a
mason one mason and a helper, a concrete gang about five and a half people
with a mixer). So excavation gets several diggers while the concrete of
the footings gets one gang. Typing a number for a trade fixes its crews in
every phase; clearing it goes back to Auto, shown as "Auto · up to n".

**Finish-by target.** Enter the working weeks the job should take, or a
date to finish by (with a start date, counted in working days). The app
then shortens the three-week aim half a day at a time, so trades on Auto
get more crews, until the schedule fits. When even the site's limits are
not enough it shows the fastest schedule it can make and says so; add
crews by hand or move the date. A target longer than the usual schedule
changes nothing.

**Rain and unworkable days.** The working days are stretched by an
allowance, 10% by default, spread over every phase so the S-curve and cash
flow stay even. Philippine public works contracts include a number of
"predetermined unworkable days" in the contract time and grant extensions
only for rain beyond it: ordinary bad weather is not grounds for an
extension (IRR of RA 9184, Annex E, sec. 10; DPWH DO 39 s. 2024 and DO 42
s. 2020 on monthly time suspension reports). For example, a DPWH
flood-control contract in Cebu gave 330 calendar days including 35
predetermined unworkable days and 35 Sundays, about 12% of its working
days. Use 10–15% for a job mostly in the dry season and 15–25% for one
through the rainy months (June to November on the western side of the
country, November to February on the eastern side).

**Holidays.** Finish dates skip Sundays and the regular holidays (Labor
Code art. 94, as amended by EO 203 and RA 9492): New Year's Day, Araw ng
Kagitingan (9 April), Labor Day, Independence Day (12 June), Bonifacio Day
(30 November), Christmas and Rizal Day (30 December) on their fixed dates;
Maundy Thursday and Good Friday from Easter; and National Heroes Day on the
last Monday of August. They match Proclamation No. 1006 s. 2025 for 2026.
Eid'l Fitr and Eid'l Adha are not skipped because their dates are
proclaimed each year, nor are special non-working days such as 1 November
and 24 and 31 December, when sites may work at premium pay; the rain
allowance covers them. Without a start date, 9 holidays a year are
assumed. The job's months, which price the time-related general
requirements, include them.

**Example.** The two-storey house of about 140 m² in the tests
([`test/data/sample_house.dart`](../test/data/sample_house.dart)): with
one crew per trade and phases strictly one after another it took 355
working days (13.7 months), excavation alone 47 days with one helper. Now
it takes about 145 working days, 5.7 months with the rain allowance and
holidays: four to five diggers for two and a half weeks of earthworks,
two to four structural crews on the frame, and the frame, roof, ceilings,
finishes and fixtures on the critical path.

The **S-curve** is the planned cumulative value of the work week by week:
each lane's direct cost spread evenly over its days, with general
requirements and hauling spread over the whole job.

The schedule is still a planning guide: it does not know which storey
each column is on, it spreads rain evenly instead of by season, and it
assumes materials arrive on time (see the purchase schedule below).

### Cash flow

The **Cash flow** card ([`lib/data/job_plan.dart`](../lib/data/job_plan.dart))
plans the money out and in month by month, a month being 26 working days of
the schedule. Amounts are **before VAT**, which the contractor collects
for the BIR and passes on.

```
money out (month)  = materials of the tasks that start this month
                   + labour, tools and equipment of the work done this month
                   + general requirements and hauling ÷ the job's months
                   all × (direct + escalation + contingency) ÷ direct
billed (month)     = price before VAT × S-curve progress gained this month
money in (signing) = price before VAT × downpayment %
money in (month)   = billed × (1 − downpayment % − retention % − income tax withheld %),
                     paid ⌈payment days ÷ 30.44⌉ months after it is billed
retention          = price before VAT × retention %, paid as long after the finish
running total      = Σ (money in − money out)
peak cash need     = the lowest running total, as a positive amount
```

The **peak cash need** is the working capital the contractor must have
ready, its own money or a credit line, at the worst point of the job. A
larger downpayment, shorter payment days or smaller retention lower it.
The days the client takes to pay are a quotation term (30 by default).
The income tax a company or government withholds is a credit against the
contractor's income tax, recovered only when it files, so the cash flow
counts it as not received; the VAT or percentage tax government withholds
is credited against the tax the contractor remits and does not change a
cash flow before VAT.

For the sample house (₱3.40 million before VAT, ₱2.85 million of cost,
30% down, 10% retention, paid in 30 days) the running total is lowest in
month 3, at about −₱347,000: that is its peak cash need. **Download cash
flow** makes a PDF with the summary, the table and these assumptions.

### Progress billing

Each billing records how far each contract line is done, as a cumulative
percentage. A billing's statement:

```
accomplished to date = Σ line amount × percent done
this billing         = accomplished to date − accomplished at the last billing
downpayment recouped = this billing × downpayment %
retention            = this billing × retention %
amount due           = this billing − recouped − retention
```

The downpayment is billed on signing as contract price × downpayment %, so
by 100% complete it has all been recouped. **Download billing** makes a PDF
with the statement, the amount due in words and each line's previous and
current percent. New billings start from the last one's percentages; the
"All 25/50/75/100%" buttons raise every line to at least that.

**Taxes withheld.** Clients in business and government withhold taxes
from what they pay a contractor and give a BIR Form 2307 so the contractor
can credit them against its own taxes. The quotation terms set the
**client**:

| Client | Withheld from each billing, on the amount before VAT |
| --- | --- |
| Individual or household | Nothing: a person not in business is not a withholding agent |
| Private company | 2% creditable income tax (expanded withholding tax on contractors) |
| Government | 2% creditable income tax, plus 5% VAT from a VAT-registered contractor or 3% percentage tax from one that is not |

```
before VAT   = this billing ÷ (1 + VAT %)
income tax   = before VAT × 2%
business tax = before VAT × 5% VAT, or × 3% percentage tax (government only)
received     = amount due − income tax − business tax
```

Sources: RR 2-98 sec. 2.57.2(E), as amended by RR 11-2018, for the 2% on
payments to general engineering, building and specialty contractors; NIRC
sec. 114(C), as amended by the TRAIN law (RA 10963, sec. 37), for the 5%
VAT withheld by government, which since 1 January 2021 is **creditable**
rather than final (RMC 36-2021); and NIRC sec. 116 for the 3% percentage
tax, back at 3%
since 1 July 2023 after CREATE's temporary 1%. The Ease of Paying Taxes
Act (RA 11976, RR 3-2024 and RR 4-2024) changed when VAT on services is
due, to the invoice rather than the collection, but not these rates.
Taxes are withheld on the work billed, so the downpayment is paid in full
and the recouped part is taxed when billed; a client that withholds on
the downpayment instead takes the same total earlier. The billing PDF
lists each tax and the **net amount received**, and the billing list in
the app shows it.

### Variation orders

Changes after the contract: a description and an amount with markups and
VAT, added or taken out. They change the contract price and become their
own billable lines.

### Actual costs

Expenses are recorded by kind (materials, labour, equipment,
subcontract, other) and compared with the budget: materials with
materials, labour with labour and minor tools, equipment with equipment,
other with hauling and general requirements. The card also shows the
share of the direct cost spent against the percent complete of the last
billing, the first sign of a job running over.

## Shopping list

The project's **To buy** tab merges every main material and companion of
the same price book item into one line (`consolidate`), so cement from walls,
plaster and a slab appears once.

- Quantities and amounts are added up. The unit price shown is amount ÷
  quantity, an average when estimates used different prices.
- Lines are grouped like a hardware's price list (cement and aggregates
  first, then masonry, steel, lumber and so on), then sorted by name.
- Entries from the original app have no price book item. They stay as
  their own lines, one per description and unit, under Other materials.
- Each estimate rounds its companions up on its own, so merged quantities can
  be a little more than one combined purchase would need.
- The list adds up to the materials total of the cost build-up.

## Exports

The project menu has **Download PDF**, **Download for Excel (CSV)**,
**Copy as text** and **Send to Google Sheet**. Settings makes a backup
file. The layouts are in
[`lib/export/project_documents.dart`](../lib/export/project_documents.dart)
and [`lib/export/project_pdf.dart`](../lib/export/project_pdf.dart).

### Bill of quantities

The exported bill of quantities lists **work items**, each estimate's work
in its own line: description (with the estimate's name), quantity, unit,
direct unit cost and amount. General requirements and hauling follow in
section F, one lot each. The lines add up to the direct cost; markups and
VAT are in the cost summary. A **Unit price analysis** section (a tab in
Google Sheets) follows with every line's analysis, numbered the same way.

Estimates are grouped by trade into lettered sections:

| Section | Trade |
| --- | --- |
| A | Structural works |
| B | Architectural works |
| C | Electrical works |
| D | Plumbing works |
| E | Other works |

- A section appears only when the project has items in that trade. Letters
  stay fixed, so a project with only electrical items has section C alone.
- Each work item is numbered within its section (A.1, A.2…).
- Each section ends with a subtotal of its direct cost.
- The app's Items tab, and its table on wide screens, still list each
  estimate's materials, where unit prices can be changed.
- Columns: Item, Description, Quantity, Unit, Unit cost, Amount.
- These letters are the app's own. They are not DPWH pay item numbers or
  part letters, which vary from contract to contract.

The **cost summary** lists Materials, Labour, Minor tools, Hauling and
delivery, Direct cost, Contingency, Overhead, Profit, Subtotal before VAT,
VAT and the total. Minor tools, hauling, contingency, overhead, profit and
VAT appear only when they are above zero, and the subtotal before VAT only
with VAT.

### PDF

An A4 document (`<project>-boq.pdf`), set in Plus Jakarta Sans:

1. A header with "Bill of quantities", the project name, client, location
   and date.
2. **Cost summary**, with ₱ amounts.
3. **Bill of quantities**, as above. Companion lines are indented in grey;
   subtotal rows are shaded.
4. **Materials to buy**: the numbered shopping list with quantity, unit,
   unit cost and amount.

Table amounts are printed without the ₱ sign. Every page has the footer
"Planning estimate made with BuildQuantify. Confirm quantities and prices
before buying." and a page number. The ⅜ sign is printed as 3/8, because the
font has no glyph for it.

### CSV

A comma-separated file (`<project>-boq.csv`) for Excel or Google Sheets:

- UTF-8 with a byte-order mark, so Excel reads the peso sign, and Windows
  line endings.
- Project, Client, Location and Date (YYYY-MM-DD) lines first.
- A `BILL OF QUANTITIES` block: Item, Description, Quantity, Unit, Unit cost
  (PHP), Amount (PHP).
- A `MATERIALS LIST` block: Group, Material, Quantity, Unit, Unit cost (PHP),
  Amount (PHP).
- A `COST SUMMARY` block: label and amount.
- Numbers are plain: whole numbers without decimals, others with two. Cells
  with commas, quotes or line breaks are quoted, with quotes doubled.

### Plain text

**Copy as text** puts the project on the clipboard for a message: items by
trade with their companions, the shopping list and the cost summary, ending
with "Planning estimate made with BuildQuantify."

### Google Sheets

After signing in with Google, a project is saved as a spreadsheet in your
own Google Drive, "BuildQuantify – project name", with three formatted tabs:
the bill of quantities, the materials list and the budget, the same content
as the PDF. Saving again updates the same spreadsheet. See
[Saving to Google Sheets](google-sheets.md) for how it works and how to set
up the Google client ID.

### Backup file

**Settings → Backup and restore** saves `buildquantify-backup-<date>.json`:

```json
{
 "app": "BuildQuantify",
 "version": 1,
 "exportedAt": "2026-10-15T09:30:00.000",
 "projects": [ … ],
 "prices": { "cement_40kg": 255 },
 "history": [ … ]
}
```

- `projects` holds each project with its estimates, companions (with the
  prices they were made with) and cost settings.
- `prices` holds only the prices you set yourself, by item key. The region
  is not saved.
- `history` holds the calculator history.

Restoring adds projects and history entries that are not already there,
matched by id, and keeps the ones you have. Prices in the backup replace
yours where both have one. Files from other apps are refused; damaged
projects or entries, unknown item keys and negative prices are skipped.

## Disclaimer

BuildQuantify's prices and totals are planning figures. Prices drift with
cement duties, steel and copper markets, fuel and the season, and they
differ by supplier, town, delivery distance and order size. Seven in ten
default prices are our own estimates. The regional factors are averages
of a few monitored items. The cost presets simplify private and DPWH
practice; the DPWH preset is not an approved budget for the contract, a
program of works or a DUPA.

Use these figures to plan and compare. Before you buy, bid or sign, get
current quotes from your suppliers and have the quantities checked by your
engineer, architect or quantity surveyor.
