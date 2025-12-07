const fs = require("fs");
const path = require("path");
const mysql = require("mysql2/promise");

// -------------------------------------------
// CONFIG
// -------------------------------------------
const OUTPUT_FILE = path.join(__dirname, "safe_movie_ids.json");

const DB = {
	host: "localhost",
	port: 3310,
	user: "root",
	password: "",
	database: "letterboxd",
};

// -------------------------------------------
// QUERY
// -------------------------------------------

const QUERY = `
    SELECT id FROM movie ORDER BY id;
`;

// -------------------------------------------

async function main() {
	try {
		console.log("Connecting to database...");

		const db = await mysql.createConnection(DB);

		console.log("Fetching movie IDs...");
		const [rows] = await db.query(QUERY);

		const ids = rows.map((r) => r.id);

		console.log(`Fetched ${ids.length} valid movie IDs.`);

		// Write to JSON
		fs.writeFileSync(OUTPUT_FILE, JSON.stringify(ids, null, 2), "utf8");

		console.log(`Saved to ${OUTPUT_FILE}`);

		await db.end();
		console.log("Done.");
	} catch (err) {
		console.error("Error:", err);
		process.exit(1);
	}
}

main();
