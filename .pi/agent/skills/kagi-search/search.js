#!/usr/bin/env node
// Perform a Kagi web search. Cheap relative to extraction — use this first,
// then run extract.js only on the URLs whose full content you actually need.

import { kagiPost } from "./lib.js";

function usage() {
	console.error(
		"Usage: search.js <query> [options]\n\n" +
			"Options:\n" +
			"  -n <num>            Maximum number of results to return\n" +
			"  --workflow <type>   search (default) | images | videos | news | podcasts\n" +
			"  --region <code>     ISO 3166-1 alpha-2 country code\n" +
			"  --after <date>      Only results after YYYY-MM-DD\n" +
			"  --before <date>     Only results before YYYY-MM-DD\n" +
			"  --json              Print the raw JSON response",
	);
	process.exit(1);
}

const args = process.argv.slice(2);
if (args.length === 0) usage();

let query = null;
let limit = null;
let workflow = "search";
const filters = {};
let rawJson = false;

for (let i = 0; i < args.length; i++) {
	const arg = args[i];
	switch (arg) {
		case "-n":
			limit = parseInt(args[++i], 10);
			break;
		case "--workflow":
			workflow = args[++i];
			break;
		case "--region":
			filters.region = args[++i];
			break;
		case "--after":
			filters.after = args[++i];
			break;
		case "--before":
			filters.before = args[++i];
			break;
		case "--json":
			rawJson = true;
			break;
		default:
			if (arg.startsWith("-")) {
				console.error(`Error: unknown option "${arg}"`);
				usage();
			}
			if (query === null) query = arg;
			else query += ` ${arg}`;
	}
}

if (!query) usage();

const body = { query, workflow };
if (limit && Number.isFinite(limit)) body.limit = limit;
if (Object.keys(filters).length > 0) body.filters = filters;

const json = await kagiPost("/search", body);

if (rawJson) {
	console.log(JSON.stringify(json, null, 2));
	process.exit(0);
}

const data = json.data || {};
// Collect results across the relevant result buckets, preserving order.
const buckets = [
	"search",
	"image",
	"video",
	"podcast",
	"news",
	"interesting_news",
	"interesting_finds",
	"direct_answer",
	"infobox",
	"code",
];

const results = [];
for (const bucket of buckets) {
	if (Array.isArray(data[bucket])) results.push(...data[bucket]);
}

if (results.length === 0) {
	console.log("No results found.");
	process.exit(0);
}

results.forEach((r, idx) => {
	console.log(`--- Result ${idx + 1} ---`);
	if (r.title) console.log(`Title: ${r.title}`);
	if (r.url) console.log(`URL: ${r.url}`);
	if (r.time) console.log(`Time: ${r.time}`);
	if (r.snippet) console.log(`Snippet: ${r.snippet}`);
	console.log("");
});
