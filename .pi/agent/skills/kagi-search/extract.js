#!/usr/bin/env node
// Extract full markdown content from one or more URLs via the Kagi Extract API.
// This costs extra (billed per page) — only run it on results that are actually
// relevant/useful after reviewing search snippets.

import { kagiPost } from "./lib.js";

function usage() {
	console.error(
		"Usage: extract.js [--json] <url> [<url> ...]\n\n" +
			"Extracts markdown content from up to 10 URLs.\n" +
			"NOTE: extraction is billed per page — extract only relevant results.\n\n" +
			"Options:\n" +
			"  --json   Print the raw JSON response",
	);
	process.exit(1);
}

const args = process.argv.slice(2);
let rawJson = false;
const urls = [];

for (const arg of args) {
	if (arg === "--json") rawJson = true;
	else if (arg.startsWith("-")) {
		console.error(`Error: unknown option "${arg}"`);
		usage();
	} else urls.push(arg);
}

if (urls.length === 0) usage();
if (urls.length > 10) {
	console.error("Error: at most 10 URLs can be extracted per request.");
	process.exit(1);
}

const json = await kagiPost("/extract", { pages: urls.map((url) => ({ url })) });

if (rawJson) {
	console.log(JSON.stringify(json, null, 2));
	process.exit(0);
}

const data = json.data || [];
for (const page of data) {
	console.log(`=== ${page.url} ===`);
	if (page.markdown) {
		console.log(page.markdown);
	} else {
		console.log(`(extraction failed${page.error ? `: ${page.error}` : ""})`);
	}
	console.log("");
}

if (Array.isArray(json.errors) && json.errors.length > 0) {
	console.error("\nErrors:");
	for (const e of json.errors) {
		console.error(`  ${e.location || e.url}: ${e.message || e.code}`);
	}
}
