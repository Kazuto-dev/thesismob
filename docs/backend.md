# Backend

BuildQuantify's server: accounts, plans, the free trial, activation codes,
projects in the cloud, Enterprise companies and the admin tools. The app
itself still works without it; the server adds what one browser cannot
do alone.

- [`backend/`](../backend): the API, in Dart, with its database schema
  and tests.
- [`frontend/`](../frontend): the app, which nginx serves from the same
  server.
- At the repository root, [`Dockerfile`](../Dockerfile) builds both and
  [`docker-compose.yml`](../docker-compose.yml) runs them on an Ubuntu
  24.04 server: PostgreSQL, the backend, nginx (the frontend) and certbot
  for HTTPS. [`deploy/`](../deploy) holds the nginx settings and the
  server scripts.

## What needs the server

| Feature | Needs the server | Why |
| --- | --- | --- |
| Calculators, estimates, bills of quantities, budgets, PDFs, schedules, cash flow | No | They are worked out in the browser and work offline. |
| Saving to Google Sheets and Google Drive | No | The app writes straight to the user's own Google account. |
| Accounts | Yes | One identity across devices, which plans hang on. |
| Plans and the 14-day trial | Yes | Timed by the server, so clearing the browser does not restart a trial. |
| Activation codes | Yes | Each works once, for one account, and can be cancelled. |
| The free plan's two projects | Yes, for cloud projects | The server refuses a third; the app also checks on the device. |
| Projects on several devices | Yes | Projects are kept with the account, with versions so two devices do not overwrite each other. |
| A company's shared projects and price book (Enterprise) | Yes | Shared between the company's members. |
| Members, roles and invitations (Enterprise) | Yes | Who may see and change what. |
| "Contact us" for Enterprise | Yes | Stored and emailed to sales. |
| Issuing codes, accounts, counts, audit log | Yes | For you, the admin. |
| Online payments | Not yet | Codes are sent by email for now. A payment provider can later update the same subscriptions table. |

## How it fits together

```
 Browser                      Your Ubuntu server (docker compose)
 ───────                      ──────────────────────────────────────────────────
 https://yourdomain ────────► frontend: nginx :80/:443
                                ├─ /        the web app (built into the image)
                                └─ /api/ ──► backend: the API :8080 ──► db: PostgreSQL 16
                                                │
                              certbot: renews   ├─► Google: checks sign-in tokens
                              the certificate   └─► Gmail (SMTP 587): codes,
                                                    invitations, inquiries
```

nginx serves the app and the API from one address, so the browser needs
no cross-origin permission, and the app needs no address built in: it
calls `/api/…` on whatever domain it was opened from. Only nginx is
published; the backend and the database are reachable only inside
Docker's network. The paths below are the API's; through nginx they
start with `/api`, such as `https://yourdomain/api/v1/me`.

1. The app signs in with Google and sends the Google token to
   `POST /v1/auth/google`. The server asks Google whose token it is and
   that it was made for BuildQuantify's client ID, then answers with its
   own session token (30 days, extended while in use).
2. Every other call carries `Authorization: Bearer <session token>`.
3. The app reads the plan from `GET /v1/me` and keeps a copy for offline
   use.

## Plans on the server

| | Homeowners (free) | Business | Enterprise |
| --- | --- | --- | --- |
| How | Default | 14-day trial once, or a Business code | An Enterprise code: a company with seats |
| Cloud projects | 2 | Unlimited | Unlimited, shared with the company |
| Price (shown in the app) | Free | $20 / ₱1,150 a month (`PRICE_BUSINESS_*`) | Contact us |

- A code adds months to what is left, so renewals stack.
- Paid time keeps working for 3 days after it ends (`GRACE_DAYS`).
- When Business ends, the two oldest projects stay editable and the rest
  become read-only. Nothing is deleted, and everything can still be
  opened and exported.
- The first Enterprise code creates the customer's company with them as
  owner. Later Enterprise codes add months and raise the seats.
- Company roles:
  - **Owner:** everything, including other owners.
  - **Admin:** members, the company price book, deleting projects.
  - **Estimator:** creates and changes the company's projects.
  - **Viewer:** opens projects only.

## API

All requests and answers are JSON. Errors look like
`{"error": {"code": "plan_limit", "message": "…"}}` with a matching HTTP
status. The app shows the message and acts on the code.

| Method and path | Who | What |
| --- | --- | --- |
| `GET /health` | Anyone | Is the server up |
| `GET /v1/plans` | Anyone | Plan names, prices, trial days, the free project limit, whether sign-in is on |
| `POST /v1/auth/google` | Anyone | `{idToken}` or `{accessToken}` from Google; returns a session `token` and the account |
| `POST /v1/auth/logout` | Signed in | Ends this session |
| `GET /v1/me` | Signed in | The account, its plan and companies |
| `DELETE /v1/me` | Signed in | Deletes the account and its projects |
| `POST /v1/trial` | Signed in | Starts the 14-day Business trial, once |
| `POST /v1/codes/redeem` | Signed in | `{code}`; at most 10 tries per 15 minutes |
| `GET /v1/projects` | Signed in | Own and company projects, with `readOnly` |
| `GET /v1/projects/{id}` | Signed in | One project with its `data` and `version` |
| `PUT /v1/projects/{id}` | Signed in | `{data, baseVersion, orgId?}`; a stale `baseVersion` returns 409 `conflict` |
| `DELETE /v1/projects/{id}` | Owner or company admin | Deletes a project |
| `GET`, `PUT /v1/documents/{key}` | Signed in | The account's own documents, such as `price_book` |
| `GET /v1/orgs`, `GET /v1/orgs/{id}` | Members | Companies, members and invitations |
| `PATCH /v1/orgs/{id}` | Owners and admins | Rename |
| `POST /v1/orgs/{id}/members` | Owners and admins | `{email, role}`: adds an account or invites an email |
| `PATCH`, `DELETE /v1/orgs/{id}/members/{userId}` | Owners and admins (anyone may leave) | Change a role, remove a member |
| `DELETE /v1/orgs/{id}/invitations/{email}` | Owners and admins | Withdraw an invitation |
| `GET`, `PUT /v1/orgs/{id}/documents/{key}` | Members read, managers write | The company price book and the like |
| `POST /v1/inquiries` | Anyone | Enterprise "Contact us"; emailed to `SALES_EMAIL` |
| `POST /v1/admin/codes` | Admins | `{plan, months, seats?, email?, note?, send?}`; returns the code once |
| `GET /v1/admin/codes?status=open` | Admins | Codes, with only their last four characters |
| `POST /v1/admin/codes/{id}/revoke` | Admins | Cancels an unused code |
| `GET /v1/admin/users?q=` | Admins | Accounts and their plans |
| `POST /v1/admin/users/{id}/extend` | Admins | `{months}`: Business time by hand |
| `PATCH /v1/admin/orgs/{id}` | Admins | `{seats?, addMonths?}` |
| `GET /v1/admin/inquiries`, `POST …/{id}/handled` | Admins | Enterprise inquiries |
| `GET /v1/admin/stats`, `GET /v1/admin/audit` | Admins | Counts, and who changed what |

Admins are the Google accounts listed in `ADMIN_EMAILS`.

## Running it on the Oracle server

You need the server (Ubuntu 24.04, ARM or Intel) with SSH access. A
domain comes later; until then the app runs on the server's IP address.

1. **Open the ports in Oracle Cloud.** In the console, go to the
   instance's VCN, then its subnet's security list, and add ingress rules
   for TCP 80 and TCP 443 from `0.0.0.0/0`.
2. **Get the code onto the server and prepare it:**
   ```sh
   git clone https://github.com/kazuto-dev/thesismob.git buildquantify
   cd buildquantify
   sudo ./deploy/setup-ubuntu.sh
   ```
   This installs Docker and opens ports 80 and 443 in the server's own
   firewall. It also turns on automatic security updates, creates `.env`
   with a random database password, and schedules a backup every night
   at 02:30.
3. **Fill in `.env`** at the repository root: `ADMIN_EMAILS` and the
   Gmail settings (next section). Add `DOMAIN`, `CERTBOT_EMAIL` and
   `GOOGLE_CLIENT_ID` when you have them.
4. **Start it:** log out and in again first, so your user can run Docker,
   then:
   ```sh
   cd buildquantify
   docker compose up -d --build
   docker compose logs -f backend
   ```
   The first build takes 10–15 minutes on a 2-CPU server, because it
   downloads Flutter and compiles the app; later builds reuse most of it.
   The app is then at `http://<the server's IP>/`, and
   `curl http://<the server's IP>/api/health` answers
   `{"ok":true,…}`.
5. **Add the domain and HTTPS.** Point the domain's DNS `A` record (such
   as `app.yourdomain.com`) at the server's public IP, set `DOMAIN` and
   `CERTBOT_EMAIL` in `.env`, then:
   ```sh
   ./deploy/get-certificate.sh
   ```
   It checks the domain reaches the server, gets a Let's Encrypt
   certificate and switches nginx to HTTPS, with HTTP redirecting to it.
   certbot renews the certificate by itself, and nginx picks up the new
   one within six hours.
6. **Turn on Google sign-in.** In Google Cloud Console, add
   `https://app.yourdomain.com` to the OAuth client's authorized
   JavaScript origins, set `GOOGLE_CLIENT_ID` in `.env` and rebuild with
   `docker compose up -d --build`. Google sign-in works only over HTTPS
   (or on `localhost`), so it needs step 5 first. Settings then shows the
   Plan card: sign in, start the trial, enter a code, compare the plans
   and ask about Enterprise.
7. **Keep the free server from being reclaimed.** Oracle reclaims Always
   Free instances that stay mostly idle for a week. Upgrading the account
   to Pay As You Go stops that; the Always Free resources still cost
   nothing.

### Gmail for sending codes

Oracle blocks outgoing mail on port 25, so the server sends through
Gmail on port 587.

1. On the Google account that sends (for example the business Gmail or
   Google Workspace account), turn on 2-Step Verification.
2. Create an app password at <https://myaccount.google.com/apppasswords>.
3. In `.env`, set:
   - `SMTP_HOST=smtp.gmail.com`
   - `SMTP_PORT=587`
   - `SMTP_USERNAME=` the account
   - `SMTP_PASSWORD=` the 16-letter app password, without spaces
   - `MAIL_FROM=BuildQuantify <the account>`
4. Restart with `docker compose up -d`.

A personal Gmail account sends up to about 500 emails a day, which is
plenty for codes. Without `SMTP_HOST`, emails are written to the API's
log instead.

### Issuing a code after someone pays

On the server:

```sh
cd buildquantify
docker compose exec backend admin issue-code --plan business --months 1 \
  --email customer@gmail.com --send
```

- **What it prints:** the code, such as `BQ-7K2M-9QXD-4HTR-W8NC`. With
  `--send`, it is also emailed to the customer.
- **Who can use it:** with `--email`, only that Google account. Leave it
  out for a code anyone can use, for example one you send yourself.
- **Enterprise:** use `--plan enterprise --months 12 --seats 10 --note
  "Company name"`.
- **Expiry:** a code must be used within 30 days (`CODE_VALID_DAYS`).

Other commands:

Each runs as `docker compose exec backend admin …`:

| Command | What it does |
| --- | --- |
| `admin codes` | Lists the open codes |
| `admin revoke-code <id>` | Cancels an unused code |
| `admin users ana` | Finds accounts and shows their plans |
| `admin extend --email ana@gmail.com --months 1` | Adds time by hand; negative months take it back |
| `admin org --id <id> --seats 15` | Changes a company's seats |
| `admin inquiries` | Lists Enterprise inquiries |
| `admin stats` | Counts of users, trials and paying accounts |

The same actions are in the API for an admin screen in the app.

### Backups, restores and updates

- **Backups:** `./deploy/backup.sh` saves the database to `deploy/backups/` and
  keeps 14 days; cron runs it nightly. To keep copies off the server,
  install the OCI CLI, create an Object Storage bucket and set
  `OCI_BUCKET` for the cron job. Object Storage includes free space.
- **Restoring:**
  `./deploy/restore.sh deploy/backups/buildquantify-YYYYMMDD-HHMM.dump`
  replaces the database with a backup; it asks first.
- **Updating:** `./deploy/update.sh` backs up, pulls the latest code and
  rebuilds both images. The API brings the database schema up to date
  when it starts.

## Security

- **Only nginx is reachable,** on ports 80 and 443. The backend and the
  database have no published port, and the API runs as an unprivileged
  user. nginx sends the real client address to the API and replaces any
  `X-Forwarded-For` a client sends, so rate limits cannot be dodged.
- **HTTPS** uses TLS 1.2 and 1.3 with HSTS once the certificate is in
  place; the security headers (`nosniff`, `SAMEORIGIN` framing, a strict
  referrer policy) are set on every response.
- **Codes and session tokens are stored only as SHA-256 hashes,** so a
  copy of the database does not hand out working codes. Codes have
  80 random bits and are limited to 10 tries per 15 minutes per account
  and per address.
- **Google sign-ins are accepted only for `GOOGLE_CLIENT_ID`** and only
  with a verified email.
- **The app and the API share one address,** so no other site may call
  the API from a browser (`ALLOWED_ORIGINS` allows more, for a copy of
  the app hosted elsewhere).
- **Every code issued and redeemed, plan change and membership change
  goes to the audit log.**
- **Keep `.env` private.** It holds the database and Gmail passwords;
  `setup-ubuntu.sh` makes it readable by your user only.
- **Privacy:** accounts hold an email address, a name and projects.
  `DELETE /v1/me` removes an account and its projects, for the Data
  Privacy Act right to erasure. Mention the server in the app's privacy
  policy.

## In the app

- [`frontend/lib/data/api_client.dart`](../frontend/lib/data/api_client.dart)
  talks to the API, at `API_URL`: `/api` in the Docker image, or a full
  address for a copy hosted elsewhere.
- [`frontend/lib/state/account_controller.dart`](../frontend/lib/state/account_controller.dart)
  keeps the session and the last plan on the device, so the plan holds
  offline and ends on its date even without a connection.
- [`frontend/lib/features/settings/plan_section.dart`](../frontend/lib/features/settings/plan_section.dart)
  is the Plan card in Settings.
- `context.watch<AccountController>().plan` gives the plan in force:
  `AppPlan.free`, `business` or `enterprise`.
- Business features are not yet locked in the app; the plan is read but
  not enforced on the device. Cloud projects are limited by the server.

## Development and tests

```sh
cd backend
dart pub get
# Unit tests, plus the API end to end against a real PostgreSQL:
TEST_DATABASE_URL=postgres://bq:bq@localhost:5432/bq_test dart test -j 1
# Run it locally:
DATABASE_URL=postgres://bq:bq@localhost:5432/bq_dev ADMIN_EMAILS=you@gmail.com \
  ALLOWED_ORIGINS='*' dart run bin/server.dart
```

The API tests empty the test database before each test. CI runs them
against PostgreSQL 16, then builds both images and checks that nginx
serves the app and reaches the API.

Schema changes go in a new entry at the end of `migrations` in
[`backend/lib/src/db.dart`](../backend/lib/src/db.dart). Never edit one
that has already run on the server.
