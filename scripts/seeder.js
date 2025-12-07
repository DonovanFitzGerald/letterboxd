const { faker } = require("@faker-js/faker");
const fs = require("fs");
const path = require("path");

const TEMPLATE_CONFIGS = {
	cast: 191272,
	crew: 146742,
	genre: 19,
	movie: 19760,
	movie_genre: 49372,
	person: 116860,
};

const CONFIG = {
	users: 50,
	userFollows: 100,
	languages: 10,
	countries: 20,
	studios: 25,
	moviesLanguages: 200,
	moviesStudios: 200,
	events: 20,
	releases: 100,
	moviesReleases: 150,
	tags: 30,
	movieLists: 100,
	movieListsMovies: 300,
	movieListsTags: 150,
	watches: 500,
	watchComments: 200,
};

const OUTPUT_FILE = path.join(__dirname, "..", "sql", "data.sql");

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

function buildInsert(table, rows) {
	if (rows.length === 0) return `-- No data for ${table}`;
	const columns = Object.keys(rows[0]);
	const formatValue = (val) => {
		if (val === null) return "NULL";
		if (typeof val === "number") return val;
		return `'${escapeSQL(String(val))}'`;
	};
	const formattedRows = rows.map(
		(row) => `(${columns.map((col) => formatValue(row[col])).join(", ")})`
	);
	return `INSERT INTO ${table} (${columns.join(
		", "
	)}) VALUES\n${formattedRows.join(",\n")};`;
}

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

const generateMoviesLanguages = (count, movieCount, languageCount) => {
	let idx = 0;
	const rows = generateUniquePairs(
		count,
		movieCount,
		languageCount,
		(a, b) => {
			idx++;
			return {
				movie_id: a,
				language_id: b,
				is_primary: idx === 1 || Math.random() > 0.7 ? 1 : 0,
				created_at: pastDate(3),
			};
		}
	);
	return buildInsert("movies_languages", rows);
};

const generateMoviesStudios = (count, movieCount, studioCount) =>
	buildInsert(
		"movies_studios",
		generateUniquePairs(count, movieCount, studioCount, (a, b) => ({
			movie_id: a,
			studio_id: b,
			created_at: pastDate(3),
		}))
	);

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

const generateMoviesReleases = (count, movieCount, releaseCount) =>
	buildInsert(
		"movies_releases",
		generateUniquePairs(count, movieCount, releaseCount, (a, b) => ({
			movie_id: a,
			release_id: b,
			created_at: pastDate(3),
		}))
	);

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

const generateMovieListsMovies = (count, movieListCount, movieCount) =>
	buildInsert(
		"movie_lists_movies",
		generateUniquePairs(count, movieListCount, movieCount, (a, b) => ({
			movie_list_id: a,
			movie_id: b,
			created_at: pastDate(2),
		}))
	);

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

const generateWatches = (count, movieCount, userCount) =>
	buildInsert(
		"watches",
		Array.from({ length: count }, () => {
			const ts = pastDate(2);
			return {
				liked: Math.random() > 0.3 ? 1 : 0,
				is_private: Math.random() > 0.9 ? 1 : 0,
				rating: randomInt(1, 10),
				review_text: faker.lorem.sentences(2),
				movie_id: randomInt(1, movieCount),
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

	const c = CONFIG;
	const t = TEMPLATE_CONFIGS;
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
			name: "Movies-Languages",
			sql: generateMoviesLanguages(
				c.moviesLanguages,
				t.movie,
				actualLanguages
			),
		},
		{
			name: "Movies-Studios",
			sql: generateMoviesStudios(c.moviesStudios, t.movie, c.studios),
		},
		{ name: "Events", sql: generateEvents(c.events) },
		{
			name: "Releases",
			sql: generateReleases(c.releases, c.events, actualCountries),
		},
		{
			name: "Movies-Releases",
			sql: generateMoviesReleases(c.moviesReleases, t.movie, c.releases),
		},
		{ name: "Tags", sql: generateTags(c.tags) },
		{ name: "Movie Lists", sql: generateMovieLists(c.movieLists, c.users) },
		{
			name: "Movie Lists-Movies",
			sql: generateMovieListsMovies(
				c.movieListsMovies,
				c.movieLists,
				t.movie
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
		{ name: "Watches", sql: generateWatches(c.watches, t.movie, c.users) },
		{
			name: "Watch Comments",
			sql: generateWatchComments(c.watchComments, c.users, c.watches),
		},
	];

	const output = [
		"-- Seed Data for Letterboxd Database",
		"-- Generated: " + new Date().toISOString(),
		"",
	];

	for (const section of sections) {
		output.push(`-- ${section.name}`);
		output.push(section.sql);
		output.push("");
		console.log(`Generated: ${section.name}`);
	}

	fs.writeFileSync(OUTPUT_FILE, output.join("\n"), "utf-8");
	console.log(`\nSeed data written to: ${OUTPUT_FILE}`);
}

seed();
