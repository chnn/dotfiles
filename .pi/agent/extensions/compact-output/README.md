# Compact output

A rendering-only Pi extension. Tool execution, model-facing results, and session data are unchanged.

- Nerd Font chevrons: `` collapsed, `` expanded.
- `muted` chevrons, tool names, and section labels; `text` previews and plain expanded contents.
- One-line previews truncate to the available terminal width, including Unicode and `outputPad`.
- Expanded contents and wrapped continuation lines indent two spaces beyond the header.
- `read`: path / returned file contents.
- `write`: path / submitted file contents (or the error if writing failed).
- `bash`: command preview / foldable `command` and `output` sections.
- `edit`: path / theme-highlighted diff with added/removed/context colors and word-level change emphasis, **expanded by default**.
- `codemode`: syntax-highlighted one-line code preview and live nested-call statuses (shown below the header whether the row is collapsed or expanded) / foldable syntax-highlighted JavaScript `code` and `output` sections. Nested previews use the same rules as top-level tools (bash command only, file path only, etc.), including when codemode truncates argument JSON. Syntax colors follow Pi’s active theme.
- `subagent` (from the `subagent` extension): `label · model:thinking` header, a live status line (turns, tool calls, tokens, duration, resolved model), and the subagent's latest five tool calls with codemode-style statuses while collapsed / the session file plus foldable `prompt`, `activity` (every tracked tool call), and `output` (the bare answer, or the error) sections. Falls back to the plain result text when the result has no subagent details.
- Other tools, including MCP tools: argument preview / foldable `input` and `output` sections.
- Readable assistant text gets a full-width `customMessageBg` panel with one shaded padding row above and below. Native Markdown, horizontal `outputPad`, and syntax highlighting are preserved. Thinking and tool output remain unshaded.

Sections fold independently. When a row is expanded, each section starts collapsed as a one-line `> name <preview>`:

```
v bash

  v command

    <command>

  > output <output preview>
```

In fullscreen mode, click a row's header to toggle the row, and click a section header (or its contents) to toggle only that section. Codemode's tool status lines belong to the row and toggle the row. Section state persists while the row is collapsed. Pi's expand-all shortcut (`Ctrl+E` by default) expands rows with every section open, and collapse-all resets the sections.

Assistant panels use a compatibility shim in `assistant-panels.ts` because Pi 1.1 does not expose an assistant-renderer registration API. In TUI sessions it wraps the exported `AssistantMessageComponent.updateContent`, delegates to the original implementation, and boxes only its direct Markdown children. The patch is restored on reload/shutdown, and existing panels revert to native rendering on unload. Non-TUI modes and transcript/model data are unchanged. Pi UI-layout changes may require updating this shim.

Codemode code is formatted asynchronously with `oxfmt` on first expansion, then cached for that call. An async-function wrapper lets the formatter accept top-level `return` and `await`; the wrapper is removed from the displayed result. If `oxfmt` is missing, fails, or takes more than three seconds, the original code is displayed. No files are written and the formatted code is never executed.

## Install

From the dotfiles repository:

```sh
ln -s "$PWD/.pi/agent/extensions/compact-output" ~/.pi/agent/extensions/compact-output
```

Run `/reload` in Pi. No npm installation is needed; Pi supplies its own TUI packages.

To try it without installation:

```sh
pi -e ./.pi/agent/extensions/compact-output/index.ts
```

## Tests

```sh
node --test .pi/agent/extensions/compact-output/tests/render.test.mjs
```

Tests use your installed Pi. With a nonstandard installation, set `PI_PACKAGE_ROOT` to the directory containing Pi's `package.json` and `dist/`.
