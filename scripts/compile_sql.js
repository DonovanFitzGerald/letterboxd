const fs = require("fs");
const path = require("path");

const SQL_FILES = [
	"schema.sql",
	"data.sql",
	"optimizations.sql",
	"stored_procedures.sql",
];

const SQL_DIR = path.join(__dirname, "..", "sql");
const OUTPUT_FILE = path.join(__dirname, "..", "main.sql");

function generateHeader(filename) {
	const separator = "-".repeat(60);
	return `-- ${separator}
-- MARK: ${filename}
-- ${separator}

`;
}

function compileSql() {
	const compiledParts = [];

	for (const filename of SQL_FILES) {
		const filePath = path.join(SQL_DIR, filename);
		const content = fs.readFileSync(filePath, "utf-8");
		const header = generateHeader(filename);
		compiledParts.push(header + content.trim());
		console.log(`Compiled: ${filename}`);
	}

	if (compiledParts.length === 0) {
		console.error("Error: No SQL files were compiled.");
		process.exit(1);
	}

	const output = compiledParts.join("\n\n");
	fs.writeFileSync(OUTPUT_FILE, output, "utf-8");

	console.log(`\n Compiling Complete`);
}

compileSql();
