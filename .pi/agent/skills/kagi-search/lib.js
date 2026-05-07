// Shared helpers for the Kagi API skill.

const BASE_URL = "https://kagi.com/api/v1";

export function getApiKey() {
	const key = process.env.KAGI_API_KEY;
	if (!key) {
		console.error(
			"Error: KAGI_API_KEY is not set. Get a key from https://kagi.com/settings/api and export it:\n" +
				'  export KAGI_API_KEY="your-api-key-here"',
		);
		process.exit(1);
	}
	return key;
}

export async function kagiPost(path, body) {
	const res = await fetch(`${BASE_URL}${path}`, {
		method: "POST",
		headers: {
			Authorization: `Bearer ${getApiKey()}`,
			"Content-Type": "application/json",
		},
		body: JSON.stringify(body),
	});

	const text = await res.text();
	let json;
	try {
		json = JSON.parse(text);
	} catch {
		json = null;
	}

	if (!res.ok) {
		const detail = json?.error?.map((e) => e.message || e.code).join("; ") || text || res.statusText;
		console.error(`Error: Kagi API request failed (HTTP ${res.status}): ${detail}`);
		process.exit(1);
	}

	if (!json) {
		console.error("Error: Could not parse Kagi API response as JSON.");
		process.exit(1);
	}

	return json;
}
