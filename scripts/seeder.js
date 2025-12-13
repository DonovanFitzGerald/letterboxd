const { faker } = require("@faker-js/faker");
const fs = require("fs");
const path = require("path");

const CONFIG = {
	users: 500,
	userFollows: 1000,
	languages: 100,
	countries: 200,
	studios: 250,
	movieLanguages: 2000,
	movieStudios: 2000,
	events: 200,
	releases: 1000,
	movieReleases: 1500,
	tags: 300,
	movieLists: 1000,
	movieListsmovie: 3000,
	movieListsTags: 1500,
	watches: 5000,
	watchComments: 2000,
};

const OUTPUT_FILE = path.join(__dirname, "..", "sql", "data.sql");
const SAFE_MOVIE_IDS_PATH = path.join(__dirname, "safe_movie_ids.json");

// Load safe movie IDs
const MOVIE_IDS = JSON.parse(fs.readFileSync(SAFE_MOVIE_IDS_PATH, "utf8"));
if (!Array.isArray(MOVIE_IDS) || MOVIE_IDS.length === 0) {
	throw new Error("safe_movie_ids.json is empty or invalid");
}

// Reference data
const LANGUAGES = [
	"English",
	"Spanish",
	"French",
	"German",
	"Japanese",
	"Korean",
	"Mandarin",
	"Hindi",
	"Portuguese",
	"Italian",
	"Russian",
	"Arabic",
	"Dutch",
	"Swedish",
	"Polish",
];
const COUNTRIES = [
	"United States",
	"United Kingdom",
	"France",
	"Germany",
	"Japan",
	"South Korea",
	"China",
	"India",
	"Brazil",
	"Italy",
	"Spain",
	"Canada",
	"Australia",
	"Mexico",
	"Russia",
	"Netherlands",
	"Sweden",
	"Norway",
	"Denmark",
	"Finland",
];
const RELEASE_TYPES = ["theatrical", "digital", "dvd", "festival"];
const FESTIVALS = [
	"Cannes Film Festival",
	"Venice Film Festival",
	"Sundance Film Festival",
	"Toronto Film Festival",
	"Berlin Film Festival",
	"Tribeca Film Festival",
];
const TAG_NAMES = [
	"Favorites",
	"Must Watch",
	"Award Winners",
	"Hidden Gems",
	"Classic",
	"Underrated",
	"Overrated",
	"Feel Good",
	"Mind Bending",
	"Tearjerker",
	"Date Night",
	"Family Friendly",
	"Guilty Pleasure",
	"Cult Classic",
	"Foreign Films",
	"Indie",
	"Blockbuster",
	"Slow Burn",
	"Fast Paced",
	"Visually Stunning",
	"Great Soundtrack",
	"Plot Twist",
	"Based on True Story",
	"Book Adaptation",
	"Remake",
	"Sequel",
	"Prequel",
	"Anthology",
	"Short Films",
	"Silent Films",
];

// ============================================================================
// Utility Functions
// ============================================================================

const escapeSQL = (str) => str.replace(/'/g, "''").replace(/\\/g, "\\\\");

const formatDate = (date) => date.toISOString().split("T")[0];

const formatDateTime = (date) =>
	date.toISOString().slice(0, 19).replace("T", " ");

const randomInt = (min, max) =>
	Math.floor(Math.random() * (max - min + 1)) + min;

const randomFrom = (arr) => arr[Math.floor(Math.random() * arr.length)];

const pastDate = (years = 3) => formatDateTime(faker.date.past({ years }));

const pastDateOnly = (years = 3) => formatDate(faker.date.past({ years }));

const formatValue = (val) => {
	if (val === null) return "NULL";
	if (typeof val === "number") return val;
	return `'${escapeSQL(String(val))}'`;
};

function buildInsert(table, rows) {
	if (rows.length === 0) return `-- No data for ${table}`;
	const columns = Object.keys(rows[0]);
	const formattedRows = rows.map(
		(row) => `(${columns.map((col) => formatValue(row[col])).join(", ")})`
	);
	return `INSERT INTO ${table} (${columns.join(
		", "
	)}) VALUES\n${formattedRows.join(",\n")};`;
}

// For relationships where both sides are 1..N integer IDs
function generateUniquePairs(count, maxA, maxB, rowBuilder) {
	const rows = [];
	const seen = new Set();
	let generated = 0;
	while (generated < count && generated < maxA * maxB) {
		const a = randomInt(1, maxA);
		const b = randomInt(1, maxB);
		const key = `${a}-${b}`;
		if (!seen.has(key)) {
			seen.add(key);
			rows.push(rowBuilder(a, b));
			generated++;
		}
	}
	return rows;
}

// For movie_X tables where movie_id must come from MOVIE_IDS array
function generateUniqueMoviePairs(count, movieIds, maxOtherId, rowBuilder) {
	const rows = [];
	const seen = new Set();
	let generated = 0;
	const maxA = movieIds.length;

	while (generated < count && generated < maxA * maxOtherId) {
		const movieId = randomFrom(movieIds);
		const otherId = randomInt(1, maxOtherId);
		const key = `${movieId}-${otherId}`;
		if (!seen.has(key)) {
			seen.add(key);
			rows.push(rowBuilder(movieId, otherId));
			generated++;
		}
	}
	return rows;
}

// For movie_lists_movie: (movie_list_id, movie_id)
function generateUniqueMovieListMoviePairs(
	count,
	movieListCount,
	movieIds,
	rowBuilder
) {
	const rows = [];
	const seen = new Set();
	let generated = 0;
	const maxmovie = movieIds.length;

	while (generated < count && generated < movieListCount * maxmovie) {
		const movieListId = randomInt(1, movieListCount);
		const movieId = randomFrom(movieIds);
		const key = `${movieListId}-${movieId}`;
		if (!seen.has(key)) {
			seen.add(key);
			rows.push(rowBuilder(movieListId, movieId));
			generated++;
		}
	}
	return rows;
}

// ============================================================================
// Generator Functions
// ============================================================================

const generateUsers = (count) =>
	buildInsert(
		"users",
		Array.from({ length: count }, () => {
			const ts = pastDate(3);
			return {
				name: faker.person.fullName(),
				email: faker.internet.email().toLowerCase(),
				profile_image: null,
				password: faker.string.hexadecimal({
					length: 64,
					casing: "lower",
					prefix: "",
				}),
				created_at: ts,
				updated_at: ts,
			};
		})
	);

const generateUserFollows = (count, userCount) => {
	const rows = generateUniquePairs(count, userCount, userCount, (a, b) => {
		if (a === b) return null;
		return { user_id: a, follow_user_id: b, created_at: pastDate(2) };
	}).filter(Boolean);
	return buildInsert("user_follows", rows);
};

const generateLanguages = (count) =>
	buildInsert(
		"languages",
		Array.from({ length: Math.min(count, LANGUAGES.length) }, (_, i) => {
			const ts = pastDate(5);
			return {
				id: i + 1,
				name: LANGUAGES[i],
				created_at: ts,
				updated_at: ts,
			};
		})
	);

const generateCountries = (count) =>
	buildInsert(
		"countries",
		Array.from({ length: Math.min(count, COUNTRIES.length) }, (_, i) => ({
			id: i + 1,
			name: COUNTRIES[i],
			flag_url: `/flags/${COUNTRIES[i]
				.substring(0, 2)
				.toLowerCase()}.png`,
		}))
	);

const generateStudios = (count) =>
	buildInsert(
		"studios",
		Array.from({ length: count }, (_, i) => {
			const ts = pastDate(5);
			return {
				id: i + 1,
				name: faker.company.name().substring(0, 45),
				bio: faker.company.catchPhrase(),
				created_at: ts,
				updated_at: ts,
			};
		})
	);

const generatemovieLanguages = (count, movieIds, languageCount) => {
	let idx = 0;
	const rows = generateUniqueMoviePairs(
		count,
		movieIds,
		languageCount,
		(movieId, languageId) => {
			idx++;
			return {
				movie_id: movieId,
				language_id: languageId,
				is_primary: idx === 1 || Math.random() > 0.7 ? 1 : 0,
				created_at: pastDate(3),
			};
		}
	);
	return buildInsert("movie_languages", rows);
};

const generatemovieStudios = (count, movieIds, studioCount) => {
	const rows = generateUniqueMoviePairs(
		count,
		movieIds,
		studioCount,
		(movieId, studioId) => ({
			movie_id: movieId,
			studio_id: studioId,
			created_at: pastDate(3),
		})
	);
	return buildInsert("movie_studios", rows);
};

const generateEvents = (count) =>
	buildInsert(
		"events",
		Array.from({ length: count }, (_, i) => {
			const ts = pastDate(5);
			return {
				id: i + 1,
				name: randomFrom(FESTIVALS) + " " + (2010 + (i % 15)),
				date: pastDateOnly(10),
				created_at: ts,
				updated_at: ts,
			};
		})
	);

const generateReleases = (count, eventCount, countryCount) =>
	buildInsert(
		"releases",
		Array.from({ length: count }, (_, i) => {
			const ts = pastDate(3);
			return {
				id: i + 1,
				name: faker.music.songName().substring(0, 40) + " Release",
				date: pastDateOnly(20),
				release_type: randomFrom(RELEASE_TYPES),
				event_id: Math.random() > 0.7 ? randomInt(1, eventCount) : null,
				country_id: randomInt(1, countryCount),
				created_at: ts,
				updated_at: ts,
			};
		})
	);

const generatemovieReleases = (count, movieIds, releaseCount) => {
	const rows = generateUniqueMoviePairs(
		count,
		movieIds,
		releaseCount,
		(movieId, releaseId) => ({
			movie_id: movieId,
			release_id: releaseId,
			created_at: pastDate(3),
		})
	);
	return buildInsert("movie_releases", rows);
};

const generateTags = (count) =>
	buildInsert(
		"tags",
		Array.from({ length: Math.min(count, TAG_NAMES.length) }, (_, i) => {
			const ts = pastDate(3);
			return {
				id: i + 1,
				name: TAG_NAMES[i],
				created_at: ts,
				updated_at: ts,
			};
		})
	);

const generateMovieLists = (count, userCount) =>
	buildInsert(
		"movie_lists",
		Array.from({ length: count }, (_, i) => {
			const ts = pastDate(2);
			return {
				id: i + 1,
				name: faker.lorem.words(3).substring(0, 45),
				is_watch_list: Math.random() > 0.7 ? 1 : 0,
				is_private: Math.random() > 0.8 ? 1 : 0,
				user_id: randomInt(1, userCount),
				created_at: ts,
				updated_at: ts,
			};
		})
	);

const generateMovieListsmovie = (count, movieListCount, movieIds) => {
	const rows = generateUniqueMovieListMoviePairs(
		count,
		movieListCount,
		movieIds,
		(movieListId, movieId) => ({
			movie_list_id: movieListId,
			movie_id: movieId,
			created_at: pastDate(2),
		})
	);
	return buildInsert("movie_lists_movie", rows);
};

const generateMovieListsTags = (count, movieListCount, tagCount) => {
	let idx = 0;
	const rows = generateUniquePairs(
		count,
		movieListCount,
		tagCount,
		(a, b) => {
			idx++;
			return {
				is_primary: idx === 1 || Math.random() > 0.7 ? 1 : 0,
				movie_list_id: a,
				tag_id: b,
				created_at: pastDate(2),
			};
		}
	);
	return buildInsert("movie_lists_tags", rows);
};

const generateWatches = (count, movieIds, userCount) =>
	buildInsert(
		"watches",
		Array.from({ length: count }, () => {
			const ts = pastDate(2);
			return {
				liked: Math.random() > 0.3 ? 1 : 0,
				is_private: Math.random() > 0.9 ? 1 : 0,
				rating: randomInt(1, 10),
				review_text: faker.lorem.sentences(2),
				movie_id: randomFrom(movieIds),
				user_id: randomInt(1, userCount),
				created_at: ts,
				updated_at: ts,
			};
		})
	);

const generateWatchComments = (count, userCount, watchCount) =>
	buildInsert(
		"watch_comments",
		Array.from({ length: count }, () => {
			const ts = pastDate(1);
			return {
				liked: Math.random() > 0.4 ? 1 : 0,
				comment_text: faker.lorem.sentence(),
				user_id: randomInt(1, userCount),
				watch_id: randomInt(1, watchCount),
				created_at: ts,
				updated_at: ts,
			};
		})
	);

// Main execution
function seed() {
	console.log("Generating seed data...");
	console.log(`Using ${MOVIE_IDS.length} safe movie IDs from JSON`);

	const c = CONFIG;
	const actualLanguages = Math.min(c.languages, LANGUAGES.length);
	const actualCountries = Math.min(c.countries, COUNTRIES.length);
	const actualTags = Math.min(c.tags, TAG_NAMES.length);

	const sections = [
		{ name: "Users", sql: generateUsers(c.users) },
		{
			name: "User Follows",
			sql: generateUserFollows(c.userFollows, c.users),
		},
		{ name: "Languages", sql: generateLanguages(c.languages) },
		{ name: "Countries", sql: generateCountries(c.countries) },
		{ name: "Studios", sql: generateStudios(c.studios) },
		{
			name: "movie-Languages",
			sql: generatemovieLanguages(
				c.movieLanguages,
				MOVIE_IDS,
				actualLanguages
			),
		},
		{
			name: "movie-Studios",
			sql: generatemovieStudios(c.movieStudios, MOVIE_IDS, c.studios),
		},
		{ name: "Events", sql: generateEvents(c.events) },
		{
			name: "Releases",
			sql: generateReleases(c.releases, c.events, actualCountries),
		},
		{
			name: "movie-Releases",
			sql: generatemovieReleases(c.movieReleases, MOVIE_IDS, c.releases),
		},
		{ name: "Tags", sql: generateTags(c.tags) },
		{ name: "Movie Lists", sql: generateMovieLists(c.movieLists, c.users) },
		{
			name: "Movie Lists-movie",
			sql: generateMovieListsmovie(
				c.movieListsmovie,
				c.movieLists,
				MOVIE_IDS
			),
		},
		{
			name: "Movie Lists-Tags",
			sql: generateMovieListsTags(
				c.movieListsTags,
				c.movieLists,
				actualTags
			),
		},
		{
			name: "Watches",
			sql: generateWatches(c.watches, MOVIE_IDS, c.users),
		},
		{
			name: "Watch Comments",
			sql: generateWatchComments(c.watchComments, c.users, c.watches),
		},
	];

	const output = [
		"-- Seed Data for Letterboxd Database",
		"-- Generated: " + new Date().toISOString(),
		"",
		"START TRANSACTION;",
		"",
	];

	for (const section of sections) {
		output.push(`-- ${section.name}`);
		output.push(section.sql);
		output.push("");
		console.log(`Generated: ${section.name}`);
	}

	output.push("COMMIT;");

	fs.writeFileSync(OUTPUT_FILE, output.join("\n"), "utf-8");
	console.log(`\nSeed data written to: ${OUTPUT_FILE}`);
}

seed();
