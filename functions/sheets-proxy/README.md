# sheets-proxy

A small HTTP Cloud Function that appends estimate rows to a Google Sheet for
the BuildQuantify web app.

Earlier versions of the app shipped a service-account private key inside the
web bundle, so anyone could copy it. This function replaces that: it runs **as**
the service account using Google Cloud's built-in identity, so there is no key
file anywhere, and the browser can only ask it to "append these rows to this
sheet".

## Request

`POST` JSON:

```json
{
  "spreadsheetId": "1AbC...",
  "sheetName": "Sheet1",
  "header": ["Materials", "Area(sqm)", "Quantity", "Cost(₱)"],
  "rows": [["CHB 4\"", 30, 375, 9375]]
}
```

- The header is written only when the sheet is empty.
- Values are stored with `RAW` input, so text can never become a formula.
- Responses: `200 {ok}`, `400` invalid input, `403` sheet not shared with the
  service account, `404` spreadsheet or tab not found, `5xx` failures.
- Limits: 200 rows per request, 12 cells per row, 300 characters per cell.

## Deploy

1. **Revoke the leaked key first.** In Google Cloud Console → IAM & Admin →
   Service Accounts → `flutter-test@qualified-tea-408701.iam.gserviceaccount.com`
   → Keys, delete key `ea91bc…`. The function does not need any key.
2. Enable the Google Sheets API for the project.
3. Deploy (set `ALLOWED_ORIGINS` to wherever the web app is hosted):

   ```sh
   gcloud functions deploy sheets-proxy \
     --gen2 --runtime=nodejs20 --region=asia-southeast1 \
     --source=functions/sheets-proxy --entry-point=appendRows \
     --trigger-http --allow-unauthenticated \
     --service-account=flutter-test@qualified-tea-408701.iam.gserviceaccount.com \
     --set-env-vars=ALLOWED_ORIGINS=https://your-app.web.app
   ```

4. Build the app with the function URL:

   ```sh
   flutter build web --release --dart-define=SHEETS_PROXY_URL=https://REGION-PROJECT.cloudfunctions.net/sheets-proxy
   ```

Users keep sharing their spreadsheet with the same service-account email as an
Editor, exactly as the in-app instructions describe.

`ALLOWED_ORIGINS` is a comma-separated list. Browsers from other origins are
refused; it does not stop non-browser clients, so consider adding
[App Check](https://firebase.google.com/docs/app-check) or rate limiting if the
endpoint is abused.

## Develop

```sh
npm install
npm test                                   # validation unit tests
ALLOWED_ORIGINS=http://localhost:8080 npm start   # serves on :8080 with your local gcloud credentials
```
