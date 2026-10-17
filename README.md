# BuildQuantify

BuildQuantify estimates how much construction material a job needs and what
it costs, using the sizes and prices of the Philippine market. Its 51
calculators cover earthworks, concrete and rebar through to finishes,
wiring and plumbing.

The repository has two halves:

- [`frontend/`](frontend): the app, in Flutter for the web;
- [`backend/`](backend): the server, in Dart with PostgreSQL, for accounts,
  plans, the free trial, activation codes, cloud projects and companies.

At the root are [`docker-compose.yml`](docker-compose.yml), which runs
both on the server with nginx and PostgreSQL, the pipeline in
[`.github/workflows`](.github/workflows) that tests every push and deploys
`main` to the server, [`deploy/`](deploy) (nginx settings and server
scripts) and [`docs/`](docs).

Each estimate prices every material the job needs (cement, sand, bars, tie
wire, forms, fittings…) from a built-in price book of 2026 Metro Manila
prices that you can edit and adjust by region. Estimates go into named
projects. A project builds:

- finish estimates from a room schedule: each room entered once, rooms
  sharing a finish grouped into one estimate per level;
- a bill of quantities grouped by trade;
- a single merged shopping list;
- a budget with labour, contingency and, for bids, overhead, profit and VAT,
  with owner, contractor and DPWH presets;
- numbered estimate revisions to compare and restore, a bill of quantities
  for bidders (whole job or one trade) and a comparison of the quotes that
  come back.

Projects export to PDF, Excel (CSV) or plain text, save to Google Sheets
after signing in with Google on the login screen, and can be backed up to a
file. After the first visit the app works fully offline, in
light or dark mode. On phones it offers to install itself on the home
screen: with Chrome's install dialog on Android, and with the Share →
Add to Home Screen steps on iPhone, where only the user can add it.

| Login | Project on a phone | Project on a desktop |
| --- | --- | --- |
| ![Login on a phone](frontend/test/golden/goldens/login_phone.png) | ![Project on a phone](frontend/test/golden/goldens/project_phone.png) | ![Project on a desktop](frontend/test/golden/goldens/project_desktop.png) |

- [How each material is calculated, with sources](docs/calculations.md)
- [Prices, budgets and exports](docs/prices-and-costing.md)
- [Google Sheets and Drive backups](docs/google-sheets.md)
- [Design system](docs/design-system.md) and [design QA](docs/design-qa.md)
- [Translations](docs/translations.md)
- [Usability test kit](docs/usability-test.md)
- [Validating the estimates](docs/validation.md)
- [Backend: accounts, plans, codes and the server](docs/backend.md)

- **Structural:** concrete hollow blocks (adjustable rebar spacing),
  concrete slabs, footings, columns and beams (concrete, bars, ties, forms),
  plywood, ceilings (boards with metal or wood framing), foam insulation
- **Architectural:** paint (both faces, neutraliser, skim coat, primer),
  tiles (by piece or box, adhesive or mortar bed, skirting), roofing (gable,
  shed or hip, purlins, screws, ridge roll, gutters), doors, windows,
  carpet, wallpaper
- **Electrical:** whole-house rough-in (circuits, wire sizes, breakers,
  panel), LED bulbs (sized by room), switches, junction boxes, outlets,
  wire, utility boxes
- **Plumbing:** PVC pipe (with a fittings allowance and solvent cement),
  sinks, toilets, faucets, showers, water tanks, septic tanks (block or
  polyethylene)

> [!NOTE]
> Earlier versions embedded a Google service-account private key, which is
> still in git history. That key has been revoked, and the app no longer
> uses a service account or any key; see
> [Google Sheets export](#google-sheets-export).

## Run it

Requires Flutter **3.47.7** (Dart 3.13).

```sh
cd frontend
flutter pub get
flutter run -d chrome
```

To run everything together as on the server (app, API, database and
nginx): in `frontend/`, `flutter build web --release
--no-web-resources-cdn --dart-define=API_URL=/api`; then at the
repository root, `cp .env.example .env`, set `POSTGRES_PASSWORD`, run
`./deploy/update.sh` and open <http://localhost/>. See
[docs/backend.md](docs/backend.md).

## Build for the web

```sh
cd frontend
flutter build web --release --no-web-resources-cdn \
  --dart-define=GOOGLE_CLIENT_ID=1234567890-abc.apps.googleusercontent.com \
  --dart-define=API_URL=https://api.example.com
```

- `--no-web-resources-cdn` serves the CanvasKit renderer and fallback fonts
  with the app instead of from a Google CDN, so the app still loads on
  networks that block it.
- `GOOGLE_CLIENT_ID` is the OAuth client ID that lets users sign in with
  Google and save projects to Google Sheets; see
  [docs/google-sheets.md](docs/google-sheets.md). Without it, everything
  else works and Settings explains that Google sign-in isn't set up.
- `API_URL` is the address of the BuildQuantify server
  ([docs/backend.md](docs/backend.md)), for accounts, plans, the free trial
  and activation codes: a full address, or `/api` when nginx serves the app
  and the API together (the Docker image does this). Without it, the app
  works on its own on the free plan and Settings shows no plan card.
- `frontend/web/sw.js` is a service worker that caches the app as it loads, so after
  one visit it starts without a connection. It is skipped on `localhost`
  unless the URL has `?offline`, so debug builds are never served stale.
- URLs use the `#/` form (for example `#/category/structural/chb`), so any
  static host works without rewrite rules. Enable gzip or brotli on the host.

## Google Sheets export

Users sign in with their own Google account and each project is saved as a
spreadsheet in their Google Drive, with the bill of quantities, the materials
list and the budget on separate tabs. The app asks only for the `drive.file`
permission, so it can open the spreadsheets it creates and nothing else, and
Google does not require an app review. Sheets and Drive are reached straight
from the browser, with no key. Setup
for the Google client ID is in [docs/google-sheets.md](docs/google-sheets.md).

## Test

The app, in `frontend/`:

```sh
cd frontend
flutter analyze
flutter test                                    # unit, widget and golden tests
flutter test --platform chrome test/data test/materials test/state
                                                # same logic compiled to JavaScript
```

Golden images are compared on Linux only, since font rendering differs
between operating systems. After an intended UI change, regenerate them on
Linux with `flutter test --update-goldens test/golden`.

The browser smoke test drives the release build in Chromium:

```sh
flutter build web --release --no-web-resources-cdn
python3 -m http.server 8090 --directory build/web &
cd tool/smoke && npm ci && npx playwright install chromium
BASE_URL=http://127.0.0.1:8090/ node smoke.mjs
```

The server, in `backend/`, against a PostgreSQL database:

```sh
cd backend
dart pub get
TEST_DATABASE_URL=postgres://user:pass@localhost:5432/test dart test -j 1
```

CI runs all of the above on every push (`.github/workflows/ci.yml`), then
starts `docker-compose.yml` the way the server does and checks that nginx
serves the app and reaches the API. Pushes to `main` then deploy to the
server; see [docs/backend.md](docs/backend.md#deploying-to-the-server).

## Project layout

```
docker-compose.yml         database, backend, frontend (nginx), run on the
                           code in this folder: nothing is built on the server
.env.example               the server's settings
.github/workflows/         CI: tests, a run of the server's setup, deploys
deploy/                    nginx settings; setup, checkout, update, admin,
                           backup and restore scripts for the server
docs/                      calculations, prices, backend, design
backend/                   the API (Dart)
  bin/                     server.dart, and admin.dart (codes, accounts)
  lib/src/                 routes, database, plans, codes, Google sign-in,
                           email
  test/                    unit tests, and the API against PostgreSQL
frontend/                  the app (Flutter)
  lib/
    main.dart, app.dart    start-up, providers, theme
    router.dart            go_router routes, old-URL redirects
    core/                  theme, breakpoints, formatting, shared widgets
    data/                  Estimate and Project models, cost build-up,
                           storage, legacy import, Sheets and API clients
    state/                 history, projects, price book, account, settings
    materials/             the 51 calculators as data (MaterialSpec), the
                           price-book items and shared estimating factors
    export/                bill of quantities as PDF, CSV, text; backups
    features/              screens: home, category, calculator, history,
                           projects, prices (the price book), settings,
                           help, shell
  assets/                  images and the Plus Jakarta Sans font (OFL)
  web/                     index.html, service worker, icons
  tool/smoke/              Playwright smoke test
  test/                    unit, widget and golden tests
```

UI code imports `package:material_ui/material_ui.dart`, which Flutter now
recommends over `package:flutter/material.dart`.

### Adding a material

1. Add any new things to buy to the price book in
   `frontend/lib/materials/items_*.dart`, with a price and its source (mark guesses
   `estimate: true`).
2. Add a `MaterialSpec` to the right file in `frontend/lib/materials/`
   with its
   fields, choices, `compute` function, definitions, solution steps,
   sources and search keywords. Set `itemKey` on the result and `priceRef`
   on the spec so its price is suggested, and list the other materials it
   needs with `buy(itemKey, quantity)`. List it in `catalog.dart`.
3. Give it an `icon`, or draw
   `frontend/assets/images/materials/<id>.png` (192 px,
   one colour on transparent; the app tints it).
4. Add hand-worked examples to the matching test in
   `frontend/test/materials/`.

The calculator screen, routing, projects and exports pick it up
automatically.

## Data

Projects, prices, history and the name of the signed-in Google account are
saved in the browser (SharedPreferences / localStorage). Settings → Backup
and restore downloads them as a JSON file and restores them on another
device. On first start the app imports the history and summary saved by the
original version, and an earlier summary becomes the project "My project";
the old entries are left in place.

## Calculation changes

Quantities now follow Philippine estimating practice: 4-litre paint gallons,
real wallpaper roll and carpet roll sizes, roofing laid on the slope with
end laps, CHB with openings deducted and a 5% waste allowance by default, and
more. Saved estimates keep the values they were calculated with. See
[docs/calculations.md](docs/calculations.md) for every formula, its sources
and a before-and-after table.

## Other platforms

The Android, iOS and desktop folders are unchanged from the original project.
They have not been rebuilt with Flutter 3.47; run `flutter create .` to
refresh their build files if you build for them.
