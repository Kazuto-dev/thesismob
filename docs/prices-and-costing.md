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
- Each of your prices can carry the **supplier** and the **date of the
  quote** (see below).
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

### Suppliers and quote dates

The bundled prices carry no dates of their own: the whole list is dated by
its label, *Metro Manila, Aug–Oct 2026* (`priceListLabel`). Your own
prices now carry a date too, and optionally a supplier
([`PriceQuote`](../lib/data/price_quote.dart)):

- In the price book, tapping a material asks for the price, the
  **supplier** (optional) and the day it was **quoted** (today unless you
  pick another day). Under *Your price* the line then reads *Wilcon Depot
  · quoted Oct 3, 2026*.
- A price you set elsewhere (a calculator's companion line, or a line in a
  project's **To buy** list) is dated the day you set it and keeps the
  supplier it had.
- Clearing a price clears its supplier and date. **Clear my prices** can be
  undone with them.
- They are saved apart from the prices (`price_quotes_v1`), so prices
  saved by earlier versions still load, without a date.
- The CSV and Google Sheets materials lists add a **Supplier** column when
  any line's material has one in your price book. The PDF and the plain
  text are unchanged.
- The **age of the prices** check dates a line by its quote when the line
  uses your quoted price for that material, and otherwise by when the
  estimate was made. A fresh estimate priced from a quote you got in
  January therefore shows as nine months old in October, and re-pricing a
  line under To buy makes it current.

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
| Painting, surface preparation and all coats (output per coat) | m² | 1 skilled, 0.5 helper, 0.5 scaffolding set | 40 | ₱46.25 | 1032 |
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
labour cost factor does. Provincial minimum wages are lower: **Rates for
region** under Budget → Daily rates fills in another region's rates (see
below), or enter what you pay. Equipment rates are typical day rentals.

#### Daily rates by region

**Rates for region** lists the 18 wage regions with their minimum wage
and the market rates the app derives from it
([`lib/data/labour_regions.dart`](../lib/data/labour_regions.dart)).
Choosing one sets the foreman, skilled worker and helper rates of the
project; equipment rates stay as they are. The picker starts on the
region whose rates the project already pays; when several regions share
those rates (CAR and Ilocos, for example) it prefers the price book's
region. Only **Metro Manila and nearby** in the price book maps onto a
wage region (NCR); its other regions are island groups, each with several
wage regions.

The method, the same one that gives the Metro Manila defaults:

```
rate = minimum wage × trade premium × labour cost factor, rounded to ₱50

trade premium       helper 1.0, skilled worker 1.2, foreman 1.5
labour cost factor  1.22 = 1 + 13th-month pay 8.3% + SSS employer share
                    10% (plus EC) + PhilHealth 2.5% + Pag-IBIG about 1%
```

The premiums are our estimate of what the market pays above the minimum
wage, set so that NCR's ₱755 gives the existing ₱900, ₱1,100 and ₱1,400.
The contribution rates are the 2026 ones: SSS 15% of the monthly salary
credit (employer 10%), PhilHealth 5% shared equally, Pag-IBIG 2% of up to
₱10,000. Service incentive leave, overtime and meals are left out.

Minimum daily wages for non-agriculture work, as of 16 October 2026: the
highest band in each region, which covers its cities and larger
establishments. Smaller towns, retail and service establishments with few
workers and agriculture can be lower.

| Region | Minimum | Wage order, effective | Next step set by the order | Foreman | Skilled | Helper |
| --- | ---: | --- | --- | ---: | ---: | ---: |
| NCR | ₱755 | NCR-28, 26 Sep 2026 | None. NCR-27's ₱780 from January 2027 is held up in court. | ₱1,400 | ₱1,100 | ₱900 |
| CAR | ₱505 | CAR-24, 30 Dec 2025 | – | ₱900 | ₱750 | ₱600 |
| I, Ilocos | ₱505 | RB I-24, 19 Nov 2025 (10 or more workers) | – | ₱900 | ₱750 | ₱600 |
| II, Cagayan Valley | ₱500 | RTWPB II-24, 5 Nov 2025 | – | ₱900 | ₱750 | ₱600 |
| III, Central Luzon | ₱600 | RBIII-26, 16 Apr 2026 (Aurora ₱560) | – | ₱1,100 | ₱900 | ₱750 |
| IV-A, CALABARZON | ₱600 | IVA-22, component cities and growth areas, 5 Oct 2025 | IVA-23 adds up to ₱45 from 26 Oct 2026; its schedule by area was not yet published, so ₱645 is the top band if it gets the full ₱45 | ₱1,100 | ₱900 | ₱750 |
| IV-B, MIMAROPA | ₱455 | RB-MIMAROPA-13, 1 Jan 2026 | – | ₱850 | ₱650 | ₱550 |
| V, Bicol | ₱455 | RBV-23, 8 Apr 2026 | ₱480 on 1 Dec 2026 | ₱850 | ₱650 | ₱550 |
| VI, Western Visayas | ₱550 | RBVI-29, 19 Nov 2025 (more than 10 workers) | – | ₱1,000 | ₱800 | ₱650 |
| NIR, Negros Island | ₱550 | No wage board yet: Negros Occidental follows Region VI (₱550), Negros Oriental and Siquijor Region VII (Class B, ₱542) | – | ₱1,000 | ₱800 | ₱650 |
| VII, Central Visayas | ₱582 | The ₱42 order affirmed by the NWPC in September 2026 (Class A, Metro Cebu; Class B ₱542), 14 Oct 2026 | – | ₱1,050 | ₱850 | ₱700 |
| VIII, Eastern Visayas | ₱470 | RB VIII-25, 1 Jun 2026 | – | ₱850 | ₱700 | ₱550 |
| IX, Zamboanga Peninsula | ₱464 | RIX-24, 1 Jun 2026 (10 or more workers) | – | ₱850 | ₱700 | ₱550 |
| X, Northern Mindanao | ₱500 | RX-24, 1 May 2026 (Category I cities) | – | ₱900 | ₱750 | ₱600 |
| XI, Davao | ₱540 | RB XI-24, 1 Sep 2026 | – | ₱1,000 | ₱800 | ₱650 |
| XII, SOCCSKSARGEN | ₱460 | RB XII-25, 15 Dec 2025 | – | ₱850 | ₱650 | ₱550 |
| XIII, Caraga | ₱475 | RXIII-20, 1 May 2026 | – | ₱850 | ₱700 | ₱600 |
| BARMM | ₱436 | BARMM-06, July 2026 (Cotabato, Marawi and Lamitan cities; provinces ₱411) | ₱461 on 1 Dec 2026 | ₱800 | ₱650 | ₱550 |

The rates use the minimum in force today, not the next step; raise them
when a scheduled increase takes effect. The NWPC's own tables could not be
opened from here, so the figures come from news reports of DOLE and wage
board announcements and from wage-tracking sites, read in October 2026:
[NCR-28 (Philstar)](https://philstarlife.com/news-and-views/933783-p60-wage-hike-in-ncr-takes-effect),
[NCR-28 (Daily Tribune)](https://tribune.net.ph/2026/09/26/11-million-ncr-workers-to-get-p60-wage-hike),
[CAR-24 (Emerhub)](https://emerhub.com/news/new-daily-minimum-wage-for-cordillera-region/),
[Region I (WageIndicator)](https://wageindicator.org/ai/work/minimum-wage/countries/philippines/2601-i-ilocos/),
[Region II (Manila Bulletin)](https://mb.com.ph/2025/10/21/dole-higher-wages-set-for-cagayan-valley-workers-kasambahay-starting-nov-5),
[Region III (SunStar)](https://www.sunstar.com.ph/pampanga/another-p40-wage-hike-in-cl-starts-on-april-16),
[CALABARZON IVA-23 (GMA)](https://www.gmanetwork.com/news/money/economy/1005445/dole-calabarzon-minimum-wage-up-by-p45-on-oct-26-2026/story/)
and [IVA-22 (WageIndicator)](https://wageindicator.org/work/minimum-wage/countries/philippines/2613-iv-a-calabarzon),
[MIMAROPA (WageIndicator)](https://wageindicator.org/ai/work/minimum-wage/countries/philippines/55357-iv-b-southwestern-tagalog-regionmimaropa/),
[Bicol (WageIndicator)](https://wageindicator.org/work/minimum-wage/updates/2026/minimum-wage-revised-in-v-bicol-region-philippines-from-08-april-2026-april-07-2026),
[Western Visayas (Visayan Daily Star)](https://visayandailystar.com/new-minimum-wage-rates-take-effect-in-western-visayas/),
[Negros Island Region (SunStar)](https://www.sunstar.com.ph/manila/status-quo-remains-for-negros-island-region-wages),
[Central Visayas (Philstar)](https://www.philstar.com/business/2026/09/28/2559493/p42-wage-hike-okd),
[Eastern Visayas (WageIndicator)](https://wageindicator.org/ai/work/minimum-wage/updates/2026/minimum-wage-revised-in-viii-eastern-visayas-philippines-from-01-june-2026/),
[Zamboanga Peninsula (WageIndicator)](https://wageindicator.org/ai/work/minimum-wage/updates/2026/minimum-wage-revised-in-ix-zamboanga-peninsula-philippines-from-01-june-2026-june-04-2026/),
[Northern Mindanao (WageIndicator)](https://wageindicator.org/ai/work/minimum-wage/updates/2026/minimum-wage-revised-in-x-northern-mindanao-philippines-from-01-may-2026-may-01-2026/),
[Davao (People Matters)](https://sea.peoplemattersglobal.com/news/compensation-benefits/davao-region-minimum-wage-workers-receive-second-tranche-of-pay-hike-51884),
[SOCCSKSARGEN (Payroll Solutions)](https://www.payrollsolutions.ph/articles/146),
[Caraga (Payroll Solutions)](https://www.payrollsolutions.ph/articles/170),
[BARMM (Philstar)](https://www.philstar.com/nation/2026/07/17/2542779/barmm-workers-get-p50-daily-wage-increase/amp/),
and for contributions [KAMI Workforce's 2026 tables](https://kamiworkforce.com/ph/blog/sss-philhealth-pagibig-contribution-tables-2026/).
Check the regional wage board's order for your town before you rely on a
figure.

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

Costs of running the site rather than of any one work item (DPWH Part A
and B items), in two kinds.

**One-time lump sums**, in pesos: mobilization and demobilization;
temporary facilities (bodega, toilet, power and water); permits,
clearances and fees; professional fees (plans, design and signing, usually
the owner's); contractor's all-risk insurance and bonds; occupational
safety and health; the project signboard; and clean-up and disposal of
debris.

**Monthly costs**, in pesos a month, for as long as the job runs: the site
engineer and supervision, a watchman or security guard, power and water
bills, and transport, phone and site office supplies. The months come from
the schedule in the Contract tab (its length with the rain allowance and
holidays, in months of 26 working days), so a
longer job costs more and more crews cost less here. In the bill of
quantities each is a line of so many months at the monthly cost.

**Suggest amounts** fills in, for the direct cost of the work so far:

| Item | Suggested |
| --- | --- |
| Mobilization and demobilization | 0.75% |
| Temporary facilities | 1% |
| Permits, clearances and fees | 1% |
| All-risk insurance and bonds | 0.3% |
| Occupational safety and health | 0.5% |
| Signboard | ₱5,000 |
| Clean-up and disposal | 0.5% |
| Site engineer and supervision | ₱8,000 a month (a share of an engineer's time) below ₱3M of work, ₱12,000 to ₱10M, ₱28,000 above |
| Watchman | ₱8,000 a month from ₱1M of work, ₱10,000 from ₱3M, ₱16,000 from ₱10M |
| Power and water; transport and phone | ₱2,000 a month each below ₱3M, ₱3,000 to ₱10M, ₱7,000 above |

Lump sums are rounded up to ₱500. Professional fees are left blank: they
are the owner's cost and depend on the services. These are our estimates
of what small builders spend; change them to your own. General
requirements are part of the direct cost, so contingency, overhead and
profit apply to them as to hauling.

### Custom items, subcontracts and provisional sums

**Add an estimate → Custom item or lump sum** adds a line no calculator
measures, described and priced by hand, in the section of the bill of
quantities you choose:

| Priced as | What it holds | In the budget |
| --- | --- | --- |
| Supply and install | Materials and labour per unit, e.g. a range hood at ₱8,000 a set plus ₱1,500 to install | Materials and labour, with minor tools on the labour; the material is on the shopping list |
| Subcontract | A specialist's all-in price per unit or per lot, e.g. solar panels | Subcontracts and provisional sums; not on the shopping list |
| Provisional sum | An allowance for work not yet designed or chosen, settled at cost later | The same |

Units are lot, set, piece, m², m³, m and kg. Each custom item is one line
of the bill of quantities with its own unit price analysis; contingency,
overhead, profit and VAT apply as to any other line.

### Permit fees

**Work out permit fees**, next to **Suggest amounts**, opens a worksheet
of the building permit and its ancillary fees
([`lib/data/permit_fees.dart`](../lib/data/permit_fees.dart)). **Put … in
permits** writes the total into the general requirement *Permits,
clearances and fees*.

Inputs, with what they start from:

| Input | Starts from |
| --- | --- |
| Use | House for one family (Division A-1), or apartments, shops, offices, factories and warehouses (Groups B, E–I) |
| Total floor area | The project's floor area |
| Storeys | 2 when the floor area is over 100 m², else 1 |
| Project cost | The project total without its permits and professional fees lines |
| Street frontage | 10 m (our guess; enter the lot's) |
| Excavation | The excavation the project's estimates measured, or 0.5 m³ per m² of footprint (floor area ÷ storeys; our guess) |
| Connected load | 24 VA per m² of floor for lighting plus 4.5 kVA for two small-appliance circuits and a laundry circuit, rounded up (Philippine Electrical Code dwelling loads), before air-conditioners |
| Bathrooms | One a storey, or one for every 70 m², whichever is more |
| Air-conditioners, fence, other LGU fees | None |

Until you type them yourself, the connected load, bathrooms and
excavation follow the floor area and storeys. Plumbing fixtures come from
the bathrooms: per bathroom a water closet, lavatory, shower and floor
drain, plus a kitchen sink, a laundry sink, a laundry floor drain and a
faucet per sink and one outside.

The fees:

| Fee | How it is worked out | Source | Status |
| --- | --- | --- | --- |
| Building fee, house (A-1) | Whole floor area × one rate by bracket: up to 20 m² ₱2.00, 20–50 ₱3.40, 50–100 ₱4.80, 100–150 ₱6.00, over 150 ₱7.20 a m² | Revised IRR of PD 1096, reissued as Annex A of NBCDO MC 03 s.2016; DPWH's own sample: 75 m² × ₱4.80 = ₱360 | Rates in DPWH and LGU copies. Some LGUs (San Fernando City's charter) split the area by bracket instead, which gives less. |
| Building fee, Groups B, E–I | Each band of area at its rate: first 500 m² ₱23.00, then ₱22.00, ₱20.50, ₱19.50, ₱18.00 and ₱17.00 for each next 100 m² to 1,000 m², ₱16.00 to 1,500, ₱15.00 to 2,000, ₱14.00 to 3,000, ₱12.00 above | Same schedule, as reproduced by San Antonio (Zambales), Alaminos (Laguna) and TIEZA, which show "first 500 m² @ ₱23 = ₱11,500, next 100 m² @ ₱22 = ₱2,200" | LGU copies. Schools and hospitals (C, D), duplexes (A-2) and accessory structures (J) have other tables, not included. |
| Line and grade | ₱24 for the first 10 m of street frontage, ₱2.40 for each metre or fraction after | Alaminos copy of the schedule | LGU copy |
| Excavation | ₱3 per m³ or fraction | Guiguinto, Bulacan 2026 citizen's charter | LGU copy; basements are ₱4/m³, not modelled |
| Fencing | Per metre or fraction: ₱3 masonry, concrete or metal up to 1.80 m; ₱4 above 1.80 m; ₱2.40 wire or light materials | Fee schedule copies and Guiguinto | LGU copies |
| Electrical | On the total connected load in whole kVA: up to 5 kVA ₱200; to 50 kVA ₱200 + ₱20 per kVA over 5; to 300 kVA ₱1,100 + ₱10 per kVA over 50; to 1,500 kVA ₱3,600 + ₱5; to 6,000 kVA ₱9,600 + ₱2.50; above, ₱20,850 + ₱1.25 | Fee schedule copies; Puerto Princesa's worked example (6 kVA: ₱220) | First three tiers seen in sources; the tiers above 300 kVA are our reading of the IRR table, continuous with them. Meter, pole and wiring-permit charges (tens of pesos) are left out. |
| Mechanical | ₱40 per air-conditioner | The schedule's window-type rate | LGU copies show ₱40 or ₱60; we apply it to split units too. Packaged systems, elevators and pumps are not modelled. |
| Plumbing | ₱24 for the first "unit" (1 water closet, 2 floor drains, 1 lavatory, 1 sink, 3 faucets, 1 shower head; part of a unit counts whole), then ₱7 per water closet, ₱3 per floor drain, ₱7 per lavatory, ₱3 per sink, ₱2 per faucet and ₱2 per shower head | VIZCODE's copy of the schedule (unit, water closet and floor drain rates) | The lavatory, sink, faucet and shower rates are our reading of the IRR table; water meters and septic tanks are left out |
| Zoning (locational) clearance, house only | Up to ₱100,000: ₱288; to ₱200,000: ₱576; above: ₱720 + 0.1% of the cost over ₱200,000 | HLURB Resolution 912 s.2013, as adopted by LGUs (Palanan, San Gabriel) | LGUs set their own; other uses are left to *Other LGU fees* |
| Fire safety evaluation clearance (BFP) | 0.10% of the project cost, at most ₱50,000 | RA 9514 (Fire Code) Sec. 12; BFP citizen's charter for the FSEC | The ₱50,000 cap is from the law as summarised by secondary sources |
| Certificate of occupancy | On a cost of floor area × ₱10,000 (Table II.G.1 of MC 03 s.2016). House: ₱100 to ₱150,000, ₱200 to ₱400,000, ₱400 to ₱850,000, ₱800 to ₱1.2M and ₱800 for each further million or part. Groups B, E–I: ₱200, ₱400, ₱800, ₱1,000 and ₱1,000 a million | Fee schedule copies, TIEZA | House tiers seen in sources. For B, E–I, only ₱800 (₱400,000–850,000) was seen; the other tiers are our reading, and copies disagree between ₱900 and ₱1,000 above ₱850,000. |
| Fire safety inspection for occupancy (BFP) | 15% of the occupancy fee, at least ₱500 | 2019 Revised IRR of RA 9514; BFP MC 2021-020 | The 10% in older guides is the 2009 IRR |
| Other LGU fees | Your own figure | – | Filing and processing fees, barangay clearance, documentary stamps |

A 140 m² two-storey house costing ₱3.7M (10 m frontage, 35 m³ of
excavation, 8 kVA, two bathrooms, no fence or air-conditioners):

| Fee | Amount |
| --- | ---: |
| Building fee, 140 m² × ₱6.00 | ₱840.00 |
| Line and grade | ₱24.00 |
| Excavation, 35 m³ × ₱3 | ₱105.00 |
| Electrical, 8 kVA | ₱260.00 |
| Plumbing, one unit + ₱26 of extra fixtures | ₱50.00 |
| Zoning clearance, ₱720 + 0.1% of ₱3.5M | ₱4,220.00 |
| Fire safety evaluation clearance, 0.1% of ₱3.7M | ₱3,700.00 |
| Certificate of occupancy, on ₱1.4M | ₱1,600.00 |
| Fire safety inspection, at least | ₱500.00 |
| **Permits and fees** | **₱11,299.00** |

[`test/data/permit_fees_test.dart`](../test/data/permit_fees_test.dart)
checks it to the peso. Real assessments run higher: cities add filing
and processing fees, inspection fees and clearances, and some multiply the
national rates under their revenue codes; 2026 guides quote ₱20,000–80,000
for a house's permits depending on the city. Treat the worksheet as the
national floor and ask your building official for the assessment.

Sources (read from search-result excerpts in October 2026, because the
sites could not be opened directly):
[DPWH, NBCDO MC 03 s.2016 Annex A](https://www.dpwh.gov.ph/DPWH/files/nbc/NEW.pdf);
[Alaminos, Laguna fee schedule](https://alaminoslaguna.com/wp-content/uploads/2020/08/NBC_FEES_AND_CHARGES.pdf);
[San Antonio, Zambales](https://www.sanantoniozambales.gov.ph/downloadable%20files/Engineering/Schedule%20of%20Fees%20and%20Other%20Charges.pdf);
[TIEZA consolidated fees](https://tieza.gov.ph/wp-content/uploads/2019/11/TIEZA-fees-fines-and-penalties-consolidated.pdf);
[Puerto Princesa OCBO assessment](https://ocbo.puertoprincesa.ph/wp-content/uploads/2022/08/Assessment-of-Fees.pdf);
[Guiguinto, Bulacan 2026 charter](https://www.guiguinto.gov.ph/wp-content/uploads/2026/03/ENGR-ARTA-CC-LATEST-2026.xlsx-rev.03.17.2026.pdf);
[VIZCODE, PD 1096](https://vizcodeph.com/code-library/pd-1096-national-building-code-of-the-philippines/);
[Respicio, how building permit fees are computed](https://www.respicio.ph/commentaries/how-building-permit-fees-are-computed-in-the-philippines);
[HLURB Resolution 912 s.2013](https://dhsud.gov.ph/wp-content/uploads/Laws_Issuances/00_Archive/HLURB/Board_Resolutions/R-912%20s.%202013.pdf)
and [Palanan's zoning fees](https://www.palanan.gov.ph/wp-content/uploads/ZoningLocational-Clearance-Fee.pdf);
[BFP citizen's charter, FSEC](https://bfp.gov.ph/wp-content/uploads/2013/11/New-BFP-Citizen-Charter-FSEC.pdf);
[BFP MC 2021-020 on fire code fees](https://bfp.gov.ph/wp-content/uploads/2022/06/MC-2021-020-SUPPLEMENTAL-GUIDELINES-ASSESSMENT-COLLECTION-OF-FIRE-CODE-FEES-REL.-TO-THE-IMPLEMENTATION-OF-RA-9514-OTHERWISE-KNOWN-AS-THE-FIRE-CODE-OF-THE-PHILIPPINES-OF-2008-ITS-REVISED-IRR-OF-2019.pdf).

### Professional fees

**Work out professional fees** opens a worksheet of design and
supervision fees as a percentage of the project cost
([`lib/data/professional_fees.dart`](../lib/data/professional_fees.dart)).
Tick the services the owner pays for and change any percentage; **Put …
in professional fees** writes the total into the general requirement
*Professional fees: plans, design and signing*. The project cost starts
from the project total without its permits and professional fees lines.

UAP Doc 202 sets the architect's minimum basic fee (MBF) as a percentage
of the project construction cost by building group:

| Group | Examples | MBF |
| --- | --- | ---: |
| 1, simple | Warehouses, factories, farm buildings, markets | 6% |
| 2, moderately complex | Schools, offices, stores, fire stations | 7% |
| 3, complex | Hospitals, hotels, stadiums | 8% |
| 4, residences | Houses, duplexes, small apartment houses, townhouses | 10% |
| 5, monumental | Monuments and landmarks | 12% |

In UAP practice the residential 10% pays for the architect and the usual
engineering on the design team. The worksheet splits the MBF between the
four design services, so ticking all four gives UAP's figure and
unticking one (say the owner hires the structural engineer directly)
leaves it out:

| Service | Share of the MBF | House (Group 4) | Basis |
| --- | ---: | ---: | --- |
| Architectural design | 60% | 6% | Our estimate, in line with the 6% often quoted for architecture alone against 10% with structural, electrical and plumbing design |
| Structural design (civil or structural engineer; ASEP/PICE) | 20% | 2% | Our estimate |
| Electrical design (professional electrical engineer; IIEE) | 10% | 1% | Our estimate |
| Sanitary and plumbing design | 10% | 1% | Our estimate |
| Mechanical design (PSME), ticked by default except for houses | 5%, on top | 0.5% | Our estimate |
| Full-time construction supervision, not ticked by default | – | 1.5% | UAP SPP 204-A: 1–1.5% of the project construction cost; we use the top for small jobs |

ASEP, IIEE, PSME and the sanitary engineers' groups do publish their own
schedules, but we could not read them; one structural fee guide quotes
₱120–480 per m² of floor by building size. Fees are minimums, before
VAT, and are agreed with each professional.

For a ₱3.7M house: architectural ₱222,000, structural ₱74,000,
electrical ₱37,000 and plumbing ₱37,000, **₱370,000** in all (10%); with
full-time supervision (₱55,500), ₱425,500.
[`test/data/professional_fees_test.dart`](../test/data/professional_fees_test.dart)
checks it.

Sources (search-result excerpts, October 2026):
[UAP Doc 202 (Scribd copy)](https://www.scribd.com/document/348049076/UAP-DOC-202-pdf),
[UAP standards of professional practice](https://pdfcoffee.com/uap-standards-of-professional-practice-pdf-free.html),
[2010 SPP for Philippine architects, PRBoA](https://www.architectureboard.com.ph/wp-content/uploads/2019/09/1.4-2010-SPP-for-PH-Architects.pdf),
[Arch Juana's residential fee example](https://archjuana.com/how-to-compute-for-architectural-fee-in-the-philippines-for-architectural-and-engineering-design-services-for-a-residential-building-and-how-to-tell-if-the-fee-is-overpriced/),
[architect fees for a building permit (6% and 10%)](https://www.scribd.com/document/521331312/Construction-Cost-Estimates),
[SPP 204-A construction services](https://philarchitecturenotes.weebly.com/spp-204a--b-construction-services.html),
[minimum fees for structural designers](https://www.scribd.com/document/689094176/Minimum-Fee-for-Structural-Designers-in-Philippines).

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
| Cost per m² of floor area (when the project has a floor area) | Below half the economy rate or above 1.5 × the premium rate; a note below the economy rate or above the premium rate | ₱28,000–75,000 a m² from economy to premium, a contractor's price with VAT; for an owner's own build without markups and VAT, three quarters of that |
| Reinforcing steel per m³ of concrete (CHB wall bars left out) | Below 40 or above 250 kg/m³ | 80–150 kg/m³ in houses |
| Formwork per m³ of concrete | Above 15 m²/m³ | 4–12 m²/m³ |
| Labour as a share of materials | Below 15% or above 90% | 30–60% |
| Materials without a price | Any | – |
| Age of the prices | Six months or more since the oldest line was priced: its quote date when it uses your quoted price, else when its estimate was made | – |
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

- DPWH's own labour rates. DO 125 s.2025 sets them from the regional
  minimum wage times a labour cost factor; the app's **Rates for region**
  works the same way but with market premiums for skilled workers and
  foremen, one set of rates per project.
- Heavy equipment such as backhoes and cranes, and equipment for work the
  calculators don't measure.
- Under DPWH rules, general requirements are not marked up with OCM or
  profit; the app marks them up with the rest of the direct cost.
- Land, utility connections and the electrical service entrance.
  Professional fees and permits are only in the budget when you enter or
  work them out under General requirements.
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

### Purchase schedule

The **Purchase schedule** card lists every material of the shopping list
(`project.materials`) with when it is first needed and when to order it:

```
needed     = start of the earliest scheduled task that uses the material
order by   = needed − the longest lead time of its group (calendar days)
```

A material goes with the work item it is used in, as in the unit price
analysis: bars and forms with their element, gravel bedding with the
slab, purlins and gutters with the roof, the rest with the estimate's
main work. So cement is first needed for the footings, CHB for the walls
and tiles for the finishes. Lines are sorted by when to order them, so
doors needed late but made to order come before paint needed sooner.
With a start date the card and the PDF show dates; without one, the week
of the schedule and the lead time.

Lead times are typical for small orders from Metro Manila hardware stores
and suppliers (`leadTimes`); check them with yours, especially in the
provinces and before the holidays:

| Group | Lead time | Why |
| --- | ---: | --- |
| Cement and aggregates, masonry, reinforcing steel, lumber, ceiling framing, paint, electrical, plumbing, other | 3–7 days | Stock items, delivered by the hardware or the supplier's truck |
| Roofing and insulation | 7–14 days | Long-span sheets are roll-formed to length |
| Tiles and floor finishes | 7–14 days | Chosen designs are often ordered in from the distributor |
| Plumbing fixtures | 7–14 days | Chosen models, sometimes from the distributor |
| Doors and windows | 21–30 days | Doors, jambs and aluminium windows are made to the measured openings |

**Download purchase schedule** makes a PDF to hand to whoever buys.

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

**Learn from actuals.** Once there is a billing, the card compares the
budget of the work done with what was spent (`reviewActuals` in
[`lib/data/contract_math.dart`](../lib/data/contract_math.dart)):

```
earned materials = Σ each work item's material cost × its percent done at the last billing
earned labour    = Σ each work item's labour cost × its percent done
variance         = earned − spent (positive: under budget)
productivity     = earned labour ÷ labour spent × 100
suggested        = the project's productivity setting × productivity ÷ 100
                   (rounded, 25–200%)
```

A productivity of 80% means the crews took a quarter more labour than the
estimate for the work they finished. **Use n% productivity for this
estimate** sets the project's productivity (Budget, labour by crews) to
the suggested value, so the rest of the estimate, the schedule and the
time-related costs follow what the crews actually do. Applying it again
changes nothing, since the earned labour then matches. Read the figures
with care: labour paid at other rates than the project's daily rates
shows up here too, payroll recorded late makes the crews look faster, and
before about a fifth of the work is done (the card says so) a few days of
rain or a slow start weigh too much. Labour priced as a share of
materials has no crew outputs to adjust, so the button is not offered.

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
section F: one lot each, and the monthly costs as months × the monthly
cost. The lines add up to the direct cost; markups and
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

The **cost summary** lists Materials, Labour, Minor tools, Equipment
rental, Subcontracts and provisional sums, Hauling and delivery, General
requirements, Direct cost, Price escalation, Contingency, Overhead, Profit,
Subtotal before VAT, VAT and the total. Lines other than materials, labour
and the totals appear only when they are above zero, and the subtotal before VAT only
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
  Amount (PHP), and Supplier when any material has one in your price
  book.
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
as the PDF. The materials tab adds a Supplier column like the CSV. Saving again updates the same spreadsheet. See
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
 "priceQuotes": { "cement_40kg": { "supplier": "Wilcon Depot", "date": "2026-10-03" } },
 "history": [ … ]
}
```

- `projects` holds each project with its estimates, companions (with the
  prices they were made with) and cost settings.
- `prices` holds only the prices you set yourself, by item key. The region
  is not saved.
- `priceQuotes` holds the supplier and quote date of those prices, when
  there are any. Older backups without it restore as before.
- `history` holds the calculator history.

Restoring adds projects and history entries that are not already there,
matched by id, and keeps the ones you have. Prices in the backup replace
yours where both have one. Files from other apps are refused; damaged
projects or entries, unknown item keys and negative prices are skipped.

## Revisions and bids

The project menu has **Estimate revisions**, **Bill of quantities for
bidders** and **Compare quotes**. The models are in
[`lib/data/revisions.dart`](../lib/data/revisions.dart) and
[`lib/data/quotes.dart`](../lib/data/quotes.dart).

### Estimate revisions

**Save as a revision** keeps a copy of the project's items and cost
settings with the date, the next number (Rev 1, Rev 2…) and a note such as
"Client removed the second bathroom".

- A project keeps its last 20 revisions; numbers are never reused.
- Revisions are saved with the project, so they are in backups. An item
  that is the same as in the revision before it is saved as just its id,
  which keeps twenty revisions of a large estimate small.
- **Compare** shows any revision against the current estimate or another
  revision: the change in the total and the direct cost, the items added,
  removed and changed (matched by item, with their direct costs), unchanged
  items repriced by different settings such as daily rates, general
  requirements and hauling, and every cost setting that differs.
- **Restore** puts a revision's items and cost settings back. The current
  estimate is saved as a revision first unless it already matches one, and
  **Undo** reverses the restore. The project's details, contract, quotes
  and revisions are not changed.
- The PDF, CSV, Google Sheet and bill for bidders print "Revision: Rev 2"
  when the estimate matches a revision, or "Draft after Rev 2" when it has
  changed since the latest one. Projects without revisions print nothing.

### Bill of quantities for bidders

A bill for contractors or subcontractors to price, as PDF
(`<project>-bid-boq.pdf`) or CSV, for the whole job or one trade
(`<project>-bid-boq-electrical.csv`):

- the project, client, location, scope, revision and date;
- short instructions: price every item, prices include materials, labour,
  equipment, overhead, profit and VAT, price the quantities as given and
  list differences separately, unpriced items are taken as included, and
  state the validity and exclusions;
- the work items numbered as in the project's own bill (A.1, C.2…) with
  their quantities and units, and empty unit price and amount columns;
  each section has a subtotal line and the bill a total bid price line to
  fill in. The whole job ends with the general requirements (section F);
- lines for the bidder's name, address, validity, signature and date.

No unit costs or amounts from the estimate appear in it.

### Quotes from bidders

Each quote records the bidder, its scope (the whole job, a trade A–E or
the general requirements), the amount, the date, how many days it is
valid and the inclusions and exclusions as typed. Quotes are grouped by
scope, lowest first, against the estimate for that scope:

```
estimate (with markups) = scope's direct cost × total ÷ direct cost
estimate (direct cost)  = scope's direct cost
difference              = quote − estimate, in pesos and % of the estimate
```

- **With markups and VAT** suits contractors bidding to an owner;
  **Direct cost** suits subcontractor quotes, whose price becomes the
  contractor's cost. For the whole job with markups the estimate is the
  project total.
- The lowest quote in a scope is marked. A quote more than 20% below the
  estimate is flagged: a price that low often means part of the scope was
  missed. Quotes past their validity say so.
- **Mark as awarded** marks one quote per scope; marking another in the
  same scope moves the award. Awarded quotes do not change the bill of
  quantities or the budget.

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
