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
the 166 items listed, 27 come from DTI's monitored prices, 22 from retailer
listings and cost blogs, and 117 are our own estimates.

| Group | Where the defaults come from |
| --- | --- |
| Cement and aggregates | Cement: DTI e-Presyo, NCR, August 2026 (₱208–280; brands prevail at ₱230–265) and AEDO 2026 (₱240–300). Sand and gravel: constructioncost.ph, PHILCON PRICES Q1 2026 (pick-up, VAT excluded) and totalcalchub 2026; delivered prices run about 30% above pick-up. Gravel bedding: estimate. |
| Masonry | 4" and 6" blocks: DTI, NCR, August 2026 prevailing prices. 8" blocks: estimate. |
| Reinforcing steel | 10 and 12 mm: DTI, August 2026, CALABARZON and Central Luzon, because DTI has no NCR rebar data. 16 and 20 mm: AEDO (August 2026) and Cebu Steel (March 2026), about ₱40/kg. 25 mm: not in the research notes; ₱940 matches about ₱40/kg (3.85 kg/m × 6 m) but is not flagged as an estimate. Tie wire: DTI, NCR. |
| Lumber and boards | Plywood: DTI, August 2026, CALABARZON and Cebu (no NCR data), and a 2026 plywood price list; 9 mm is an estimate. Coco lumber: retailer listings, partly dated (₱27–48 per bd ft). Good lumber: estimate based on a 2019–2021 list. Nails: DTI, NCR. Fiber cement and gypsum boards: Citizen Flanges, Cebu Home Builders and Wilcon (₱495 for 9 mm gypsum). |
| Ceiling framing | Furring, carrying channel and wall angle: hardware listings (Topmost, Citizen Flanges, Hardware Zone); the channel's gauge was not stated. Board screws and hanger wire: estimates. |
| Roofing and insulation | Corrugated GI: DTI, NCR, June–August 2026 (8 ft gauge 26 at ₱450–820), set at ₱78 per foot of length. Long-span: Citizen Flanges and Ranflex (September 2026); sources disagree by about 2×. Tek screws, C-purlins, ridge roll, gutter and 50 m foam: retailer listings, 2025–2026. Downspout, 25 m foam, foil tape and umbrella nails: estimates. |
| Paint and finishes | Boysen as the reference brand, from Wilcon and DIY Hardware listings (latex ₱688–740, enamel ₱896, primer ₱829–960). Putty: a Tacloban dealer (₱282). Neutralizer: a 1 L Lazada listing (₱318–446). Semi-gloss (only a 1 L price was found), skim coat, thinner, sandpaper, wallpaper and paste: estimates. |
| Tiles and floor finishes | All estimates. |
| Doors and windows | All estimates. The window rate is ₱450 per ft² supplied and installed, about ₱4,850 per m². |
| Electrical | LED bulbs: DTI, NCR, August 2026 (9 W prevails at ₱90–159). Switch: DTI, NCR (snap switches ₱45–50, tumbler switches ₱120–150). Wire, conduit, boxes, devices, breakers and panels: estimates. Check wire first, because it follows copper prices. |
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
August 2026, and PSA's construction materials index for NCR rose about 1.2–1.3%
a year in early 2026.

### Regional factors

Pick where the project is in **Price book → Where is the project?**. One
factor scales every default price
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

### Cement and aggregates

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Portland cement, 40 kg | bag | 240 |  |
| Washed sand | m³ | 1,500 |  |
| Gravel, ¾" | m³ | 1,800 |  |
| Gravel bedding | m³ | 1,000 | yes |

### Masonry

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Concrete hollow block 4" | pc | 24 |  |
| Concrete hollow block 6" | pc | 32 |  |
| Concrete hollow block 8" | pc | 45 | yes |

### Reinforcing steel

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Deformed bar 10 mm × 6 m | pc | 150 |  |
| Deformed bar 12 mm × 6 m | pc | 215 |  |
| Deformed bar 16 mm × 6 m | pc | 390 |  |
| Deformed bar 20 mm × 6 m | pc | 600 |  |
| Deformed bar 25 mm × 6 m | pc | 940 |  |
| Tie wire, #16 GI | kg | 85 |  |

### Lumber and boards

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

### Ceiling framing

| Item | Unit | Price (₱) | Estimate |
| --- | --- | ---: | :---: |
| Metal furring, 5 m | pc | 125 |  |
| Carrying channel, 5 m | pc | 140 |  |
| Wall angle, 3 m | pc | 60 |  |
| Board screws, box of 100 | box | 120 | yes |
| Hanger wire, #10 GI | kg | 90 | yes |

### Roofing and insulation

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

### Paint and finishes

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

### Tiles and floor finishes

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

### Doors and windows

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

### Electrical

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

### Plumbing

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

### Plumbing fixtures

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

Calculators price materials only. A project adds labour, tools, hauling,
contingency, markups and VAT in its **Budget** section (a tab on phones). The model is in
[`lib/data/project.dart`](../lib/data/project.dart) (`CostSettings` and
`CostBreakdown.of`).

### Materials by trade

Each estimate belongs to the trade of its calculator: structural,
architectural, electrical or plumbing. Entries from the original app, which
did not record a calculator, go under **Other works**. A trade's materials
are the sum of its estimates' materials totals, companions included.

### The formula

```
materials      = Σ materials of each trade
labour         = Σ (materials of the trade × labour % of the trade)
minor tools    = labour × tools %
direct cost    = materials + labour + minor tools + hauling
contingency    = direct cost × contingency %
overhead (OCM) = direct cost × overhead %
profit         = direct cost × profit %
subtotal       = direct cost + contingency + overhead + profit
VAT            = subtotal × VAT %
total          = subtotal + VAT
```

- Each line is rounded to the centavo.
- Labour is a percentage of material cost. A trade can have its own
  percentage under **Labour by trade**; empty trades use the main one.
- Hauling and delivery is a lump sum in pesos.
- Contingency, overhead and profit are each a percentage of the direct cost.
  They are not compounded on each other.
- VAT is charged on the subtotal. Price book prices already include the VAT
  paid on materials; the VAT line is the tax on the contract price.
- The last line reads **Project budget**, or **Total contract price** when
  overhead, profit or VAT is above zero.

### Presets

| Setting | Owner | Contractor | DPWH |
| --- | ---: | ---: | ---: |
| Labour, % of materials | 40 | 40 | 40 |
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
- Labour starts at 40% in a new project. Switching presets keeps the
  project's own labour percentages and hauling.
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

The DPWH column is the worked example in our DPWH research notes, and
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

- Labour from crews and days. DPWH's detailed unit price analysis (DUPA)
  prices labour as crew-days × daily rates (DO 125 s.2025 sets the rates from
  the regional minimum wage times a labour cost factor; the NCR minimum is
  ₱755 a day since 26 September 2026). The
  app uses a percentage of materials instead.
- Equipment rental other than minor tools.
- Mobilization and demobilization, permits and clearances, and the service
  vehicle. Under DPWH rules these are not marked up with OCM or profit; add
  them to hauling only if you accept that they will be marked up.
- Professional fees, land, utility connections and the electrical service
  entrance.
- DPWH's own engineering and administrative overhead (DO 7 s.2025), which is
  deducted from the appropriation and is not part of a contractor's price.

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
**Copy as text** and **Send to Google Sheet**. Settings makes a backup file. The layouts are in
[`lib/export/project_documents.dart`](../lib/export/project_documents.dart)
and [`lib/export/project_pdf.dart`](../lib/export/project_pdf.dart).

### Bill of quantities

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
- Each estimate is numbered within its section (A.1, A.2…) and followed by
  its companion lines, unnumbered.
- Each section ends with a subtotal of its main materials and companions.
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

When the app is built with a Sheets proxy, a calculator result or a whole
project can be appended to your own spreadsheet. Each estimate adds a row for
the main material and an indented row for each companion: Item, Quantity,
Unit, Unit cost (₱), Amount (₱). The header is written to an empty sheet.
There is no cost summary in this export. See the
[README](../README.md#google-sheets-export) for set-up.

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
