# Saving to Google Sheets

Users sign in with their own Google account and BuildQuantify saves each
project as a spreadsheet in their Google Drive. There is no server and no
service account; the browser talks to Google directly with the user's
permission.

## What users see

The app opens on a login screen with **Sign in with Google** and **Continue
without signing in**. It appears on the first visit and after signing out;
once the user signs in or chooses to continue, it steps aside and they land
where they were going (a shared calculator link, for example). Builds
without a client ID skip it.

1. On the login screen, a project's **Google Sheets** button, or Settings →
   **Sign in with Google**, they sign in.
2. Google asks them to pick an account and allow BuildQuantify to "see,
   edit, create and delete only the specific Google Drive files you use
   with this app".
3. The app creates **BuildQuantify – _project name_** in their Drive with
   three tabs:
   - **Bill of quantities**: trade sections A–E, each estimate with its
     companion materials, and subtotals;
   - **Materials**: the merged shopping list;
   - **Budget**: the cost build-up and the settings behind it.
4. **Update Google Sheet** rewrites those three tabs in the same
   spreadsheet. Other tabs the user adds are left alone; a deleted tab is
   added back; if the spreadsheet was deleted, a new one is made.

The app only remembers the account's name and email. The access token is
kept in memory and lasts about an hour; after that, or after a reload, the
next save asks Google again, usually with a single click.

### Permissions

| Scope | Why |
| --- | --- |
| `userinfo.email`, `userinfo.profile` | Show who is signed in |
| `drive.file` | Create spreadsheets and update the ones the app created |

`drive.file` cannot see any other file in the user's Drive. Google treats
these scopes as non-sensitive, so the app does not need Google's security
review. The consent screen may still need brand verification if you show a
logo.

## Set it up (once, by the app's owner)

You need a Google account and about ten minutes.

1. **Create a project.** Open <https://console.cloud.google.com/>, then
   create a project, for example "BuildQuantify".
2. **Turn on the Sheets API.** Go to APIs & Services → Library, search for
   **Google Sheets API** and choose **Enable**.
3. **Set up the consent screen.** Go to Google Auth Platform (APIs &
   Services → OAuth consent screen):
   - **Branding:** app name "BuildQuantify", a support email and a developer
     contact email.
   - **Audience:** External. While the app is in **Testing**, only the test
     users you list can sign in (up to 100); add yourself and your
     testers. Choose **Publish app** when you are ready for everyone.
   - **Data access:** add the scopes
     `https://www.googleapis.com/auth/drive.file`,
     `.../auth/userinfo.email` and `.../auth/userinfo.profile`.
4. **Create the client ID.** Go to Clients (APIs & Services → Credentials) →
   **Create client** → **Web application**. Under **Authorized JavaScript
   origins**, add every address the app is served from, with no path and
   no trailing slash, for example:
   - `https://buildquantify.web.app` (your real host)
   - `http://localhost:8080` (for `flutter run -d chrome --web-port 8080`)

   Leave **Authorized redirect URIs** empty. Copy the **Client ID**, which
   ends in `.apps.googleusercontent.com`. It is not a secret; it is built
   into the web app.
5. **Build with it:**

   ```sh
   flutter build web --release --no-web-resources-cdn \
     --dart-define=GOOGLE_CLIENT_ID=1234567890-abc.apps.googleusercontent.com
   ```

   For development:

   ```sh
   flutter run -d chrome --web-port 8080 \
     --dart-define=GOOGLE_CLIENT_ID=1234567890-abc.apps.googleusercontent.com
   ```

Without `GOOGLE_CLIENT_ID`, the app hides the Google Sheets button and
Settings explains that Google sign-in isn't set up. Everything else,
including PDF and Excel downloads, works as usual.

## Troubleshooting

| What you see | Cause and fix |
| --- | --- |
| Google's window says `invalid_client` or `origin_mismatch` | The client ID is wrong, or the page's address is not in **Authorized JavaScript origins**. Add it exactly, e.g. `https://example.com`, with no trailing slash. |
| "Access blocked: this app has not completed the Google verification process" | The consent screen is in Testing and the account is not a test user. Add it, or publish the app. |
| "The Google Sheets API isn't enabled for this app yet." | Enable the Google Sheets API in the same Cloud project as the client ID (step 2). |
| The window doesn't open | The browser blocked the pop-up. Allow pop-ups for the site and tap the button again. |
| "Your Google sign-in expired." | The hour-long token ran out or access was removed in the Google account. Tap again to sign in. |

## How it works

| File | Role |
| --- | --- |
| [`lib/features/auth/login_screen.dart`](../lib/features/auth/login_screen.dart) | The login screen; the router in [`lib/router.dart`](../lib/router.dart) shows it until the user signs in or continues |
| [`lib/data/google_auth.dart`](../lib/data/google_auth.dart) | Gets access tokens through Google Identity Services (`google_sign_in`) |
| [`lib/data/google_sheets_client.dart`](../lib/data/google_sheets_client.dart) | Calls the user info and Sheets REST APIs: create, update, format |
| [`lib/export/project_sheets.dart`](../lib/export/project_sheets.dart) | Turns a project into the three tabs |
| [`lib/state/google_account_controller.dart`](../lib/state/google_account_controller.dart) | Sign in, sign out, save; turns Google errors into messages |

Google only lets the sign-in window open in direct response to a tap, so
every save asks for the token first, before anything else is awaited. The
spreadsheet's id is stored on the project (and in backups) so later saves
update the same file.

Earlier versions sent rows through a Cloud Function that used a
service-account key. That key has been revoked, and the function and its
settings were removed.
