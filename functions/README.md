# Cloud Functions — tariff data

The app reads `tariffs/domestic_general` for the published domestic schedule
and monthly AFA rates. `TariffRepository` falls back to the bundled asset when
Firestore is unavailable or the document is invalid.

## One-time seed

```bash
# From the repository root
gcloud auth application-default login

cd functions
npm install
npm run seed:tariff
```

This writes `assets/tariff/domestic_general.json` to Firestore. Re-run it after
changing base rates, EEI bands or protection periods.

## Monthly AFA sync

`syncAfaRates` runs at 09:00 on the 2nd of each month (`Asia/Kuala_Lumpur`).
It fetches `https://www.mytnb.com.my/tariff/EN.json`, parses `afaGraph.data`
and merges the declared rates into `tariffs/domestic_general.afaByMonth`.

```bash
firebase deploy --only functions:syncAfaRates
```

The function:

- only writes values that parse as numbers in `-20..20` sen/kWh,
- keeps existing months (history) and forecast entries,
- marks fetched values as `status: "final"`,
- fails loudly if the document has not been seeded or the page shape changes.

Forecasts are not fetched. Add or update them in the seed JSON if you want the
app to include a forecast for a future month.

## Manual override

Edit `tariffs/domestic_general` in the Firebase console (or re-run the seed)
and restart the app. The app prefers Firestore over the bundled asset.
