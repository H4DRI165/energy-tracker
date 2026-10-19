/* eslint-disable no-console */
// Seeds tariffs/domestic_general from the app's bundled schedule.
//
// Usage (from the functions/ directory, with Application Default Credentials):
//   npm run seed:tariff

const admin = require("firebase-admin");
const schedule = require("../assets/tariff/domestic_general.json");

admin.initializeApp();

/**
 * Seeds the tariff document from the bundled schedule.
 * @return {Promise<void>} resolves once the document is written.
 */
async function main() {
  await admin.firestore()
      .doc("tariffs/domestic_general")
      .set(schedule, {merge: true});
  console.log("Seeded tariffs/domestic_general");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
