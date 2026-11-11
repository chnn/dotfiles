# Split a Pi session in Rex

Run `/split`, pick a point using Pi's native session tree, and press Enter. A separate Pi session opens in a Rex block immediately **to the right of the block running the command**. The new block takes focus.

The original Pi session is not forked, navigated, aborted, or rewritten. Its editor is left alone. Escape cancels without creating a fork or a block. Search, filters, folding, and copy work like `/tree`; label editing is disabled in this read-only picker.

Selection follows `/tree` semantics:

- **User message:** fork immediately before it and put its text in the new editor, like `/fork`.
- **Custom message:** likewise restore its text as a draft.
- **Other entry:** fork through that entry, inclusive.

Drafts are **not sent automatically**. Like native `/fork`, restoring a prompt restores text, not attached images. You can pick inactive branches too. Forks contain only the selected path, preserving compactions and resolved labels; abandoned branches are not copied.

## Install

From the dotfiles repository:

```sh
ln -s "$PWD/.pi/agent/extensions/split" ~/.pi/agent/extensions/split
```

Run `/reload` in Pi, then `/split`. Requires interactive Pi inside Rex, with `rex` on `PATH` and `REX_SESSION` / `REX_BLOCK` set. No npm install is needed.

Try without installing:

```sh
pi -e ./.pi/agent/extensions/split/index.ts
```

The child uses the same installed Node-based Pi CLI, agent configuration directory, working directory, session storage directory, current model, and thinking level. Normal global/project resources are loaded afresh; other one-off CLI options, environment overrides, and dynamically registered runtime configuration are not copied. The split extension itself is explicitly loaded in the child so further `/split` commands work even when testing with `-e`.

This forks **conversation history**, not project files: both sessions work in the same directory, not separate Git worktrees.

## Persistence and failures

The fork gets a new session ID/file and links to the original via `parentSession`. Creation uses an independent in-memory snapshot, so even opening/migrating the source file cannot change it. Unflushed and in-memory sessions are supported too.

Draft text travels in a private `0600` file next to the fork (`<session>.jsonl.split-draft`), not a shell command or command-line prompt. The child consumes and deletes it on startup. The fork itself is also created with `0600` permissions.

If Rex fails after the fork is saved, the error reports the session path. The fork and any draft handoff are deliberately retained: a timed-out request might still have opened a pane. **Check Rex before retrying.** Resume a saved fork with `pi --session <file>`. If a `.split-draft` file remains, its text can be pasted into the editor and the file deleted, or restored with `pi -e <path-to-split/index.ts> --session <file> --split-draft <draft-file>`.

## Tests

```sh
node --test .pi/agent/extensions/split/tests/split.test.mjs
```

Tests use your installed Pi, without extra dependencies. Set `PI_PACKAGE_ROOT` to its package directory for a nonstandard installation. They cover source immutability, independent persistence, inactive branches/labels, empty/setup-only forks, native picker integration/cancellation, Rex targeting, error recovery, and one-shot editor handoff. They mock Rex rather than opening panes.
