# Validating BuildQuantify's estimates

How the app's quantities and costs are checked today, and how to check
them against real jobs. A thesis or a company adopting the app should run
the field validation below before relying on its numbers for contracts.

## What an estimate is meant to be

The app makes **planning estimates**. In AACE International's estimate
classes (18R-97), they fall in:

| Stage in the app | AACE class | Expected accuracy |
| --- | --- | --- |
| Quick budget by floor area | Class 5, concept screening | −20% to −50% low, +30% to +100% high |
| A project with every item estimated, prices checked | Class 3, budget authorization | −10% to −20% low, +10% to +30% high |
| The same with supplier quotes and the crew's own outputs | Class 2, control or bid | −5% to −15% low, +5% to +20% high |

A detailed estimate can only be as good as its inputs: the measurements
from the plans, the prices and the crew outputs.

## What is checked in the code

### Formulas against hand calculations

Every calculator has unit tests whose expected values are worked out by
hand from the formula and the published factor, not by running the code
twice ([`test/materials`](../test/materials)). For example:

| Calculator | Case | Expected, by hand |
| --- | --- | --- |
| CHB | 10 × 3 m wall, 4" blocks, 5% waste | 30 m² × 12.5 = 375 + 19 = 394 blocks |
| Concrete slab | Class A mix | 9 bags of 40 kg, 0.5 m³ sand and 1.0 m³ gravel per m³ (Fajardo) |
| Footings, columns, beams | Bars | Net bar length with laps, bought as 6 m bars |
| Rebar weight | Unit mass | d² ÷ 162.2 kg/m (0.617 kg/m for 10 mm) |
| Light fixtures | Lumen method | ⌈lux × area ÷ (lumens × 0.6 × 0.8)⌉ |

[`docs/calculations.md`](calculations.md) lists every formula with its
source.

### Every calculator, every option

Shared tests ([`test/materials/calculators_test.dart`](../test/materials/calculators_test.dart))
run all 40 calculators and check that:

- each one calculates with plain inputs, and its total is quantity × price;
- exactly one price field shows for any combination of options;
- every work item it measures is known to the costing, with a positive
  quantity, so no material or labour drops out of a bill of quantities.

### Costs that add up

- The unit price analyses of a project add up to its direct cost
  ([`test/data/unit_prices_test.dart`](../test/data/unit_prices_test.dart)).
- Contract lines add up to the contract price to the centavo, and billing
  statements recoup the downpayment and hold retention as set
  ([`test/data/contract_test.dart`](../test/data/contract_test.dart)).
- The DPWH preset reproduces the DO 197 s.2016 build-up to the peso
  ([`test/data/project_test.dart`](../test/data/project_test.dart)).
- The browser smoke test enters a wall in the release build and checks the
  blocks, the materials total and the budget on screen
  ([`tool/smoke/smoke.mjs`](../tool/smoke/smoke.mjs)).

### Checks in the app

Each project's **Checks** card compares it with usual ranges for houses:
cost per m², steel per m³ of concrete, formwork per m³, labour against
materials, missing and old prices, and scope that usually goes together
(see [Checks](prices-and-costing.md#checks)). They catch a mistyped
dimension or a forgotten scope before an estimate goes out.

## Field validation

The tests prove the app does what its formulas say. Whether the formulas,
factors and outputs match real jobs needs completed projects.

### Sample

At least 10 completed houses or renovations (more is better), with:

- the plans the work was built from;
- what was actually delivered: delivery receipts or the warehouse log, by
  material;
- what was actually paid: payroll by trade and week, equipment rentals,
  general requirements;
- the dates work started and finished.

### Method

1. Estimate each project in the app from its plans only, as an estimator
   would before the job, without looking at the actuals. Record the
   project's crew productivity and rates if they were known beforehand.
2. Export the bill of quantities and the materials list (CSV).
3. For each material and each work item, record the estimate and the
   actual in a sheet with these columns:

   | Project | Item | Unit | Estimated | Actual | Error % |
   | --- | --- | --- | ---: | ---: | ---: |

   where **Error % = (estimated − actual) ÷ actual × 100**.
4. Do the same for labour (crew-days or pesos by trade), the schedule
   (working days) and the total cost.

### Measures

For each item type across the projects:

- **Mean absolute percentage error (MAPE)**: the average size of the
  error.
- **Bias**: the average error with its sign; a steady positive bias means
  the app over-estimates and a factor should come down.
- **Spread**: the standard deviation of the error, to see whether a factor
  is wrong or the inputs are just noisy.

### Targets

| Item | Target MAPE |
| --- | ---: |
| Concrete, CHB, plaster, rebar (structural quantities) | 5% |
| Tiles, paint, ceilings, roofing (finishes) | 10% |
| Electrical and plumbing materials | 15% |
| Labour, by trade | 20% |
| Schedule, working days | 20% |
| Total direct cost, detailed estimate | 10% |
| Quick budget by floor area | 25% |

An item over its target with a steady bias is a candidate for a factor
change (waste allowance, coverage, crew output); write down the source of
any change in `docs/calculations.md` or `docs/prices-and-costing.md`.

### Expert review

Ask a licensed civil engineer and a quantity surveyor to review, for a
sample house:

- the bill of quantities against their own take-off;
- the unit price analyses: crews, outputs and rates;
- the quotation and billing documents against their usual practice.

Record their comments and what changed as a result.

### Usability

Measure whether people can use the app to get these estimates with the
[usability test kit](usability-test.md).

## Known limits

- Quantities are only as right as the measurements typed in; the app does
  not read plans.
- Crew outputs are averages for small buildings in the Philippines; the
  project's productivity setting scales them but cannot capture a
  particular site.
- Prices are Metro Manila in late 2026 with regional factors; many are our
  own estimates and are marked as such in the price book.
- The schedule spreads the rain allowance evenly instead of by season and
  does not know which storey each column is on.
- The structural calculators measure materials for sizes the user enters.
  They are not a structural design and do not check that a member is
  strong enough.
