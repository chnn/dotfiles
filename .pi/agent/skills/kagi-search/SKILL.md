---
name: kagi-search
description: Web search and content extraction via the Kagi API. Use for searching up-to-date documentation, facts, or any web content, or when requested to "search the web", "read this page", or "download this webpage".
---

# Kagi Search

Web search and on-demand content extraction using the official Kagi API. No browser required.

## Setup

Requires a Kagi API key. Get one from https://kagi.com/settings/api and set it in your
environment (`~/.profile` or `~/.zprofile`):

```bash
export KAGI_API_KEY="your-api-key-here"
```

The scripts error out if `KAGI_API_KEY` is not set. They use only Node's built-in
`fetch`, so there is **no `npm install` step**.

## Workflow

**Search first, extract second.** Run a search to get ranked results with titles, URLs,
and snippets. The snippets are usually enough to answer a question. Only call `extract.js`
on the specific URLs whose full content you actually need — extraction is billed per page
at your Extract API rate, while search is much cheaper.

## Search

```bash
{baseDir}/search.js "query"                        # Basic search
{baseDir}/search.js "query" -n 10                  # Limit to 10 results
{baseDir}/search.js "query" --workflow news        # search | images | videos | news | podcasts
{baseDir}/search.js "query" --region DE            # ISO 3166-1 alpha-2 country code
{baseDir}/search.js "query" --after 2024-01-01     # Published/updated after date
{baseDir}/search.js "query" --before 2024-06-30    # Published/updated before date
{baseDir}/search.js "query" --json                 # Raw JSON response
```

### Options

- `-n <num>` - Maximum number of results to return
- `--workflow <type>` - Result type: `search` (default), `images`, `videos`, `news`, `podcasts`
- `--region <code>` - Two-letter ISO 3166-1 alpha-2 country code
- `--after <YYYY-MM-DD>` - Only results published/updated after this date
- `--before <YYYY-MM-DD>` - Only results published/updated before this date
- `--json` - Print the raw JSON response instead of formatted output

## Extract Page Content

Extract full markdown content from up to **10 URLs** at once. Do this **only** for results
that are relevant/useful — it costs extra.

```bash
{baseDir}/extract.js https://example.com/article
{baseDir}/extract.js https://a.com/page https://b.com/page   # Multiple URLs (max 10)
{baseDir}/extract.js --json https://example.com/article      # Raw JSON response
```

## Output Format

Search:

```
--- Result 1 ---
Title: Page Title
URL: https://example.com/page
Time: 2024-11-29T03:54:26Z
Snippet: Description from search results

--- Result 2 ---
...
```

Extract:

```
=== https://example.com/article ===
# Article Title

Markdown content extracted from the page...
```

## When to Use

- Searching for documentation, API references, or current information
- Looking up facts (often answerable from snippets alone)
- Fetching the full content of specific, relevant URLs via extraction
- Any task requiring web search without interactive browsing
