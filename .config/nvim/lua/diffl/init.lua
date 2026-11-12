-- Diffl: review changes between revisions (git or jj) as a quickfix list of
-- files, with a side-by-side diff for the selected entry.
--
--   :Diffl                     working copy vs. its parent (HEAD / @-)
--   :Diffl <rev>               changes introduced by <rev> (vs. its first parent)
--   :Diffl <left> <right>      changes between <left> and <right>
--
-- When the right-hand side of a file is identical to the working copy on disk,
-- the real file is opened so LSP, formatting, editing etc. all keep working.

local M = {}
local api = vim.api

local STATUS = {
  modified = "M",
  added = "A",
  removed = "D",
  renamed = "R",
  copied = "C",
}

---@class diffl.Rev
---@field id string|nil      commit id (nil = empty tree)
---@field label string       short human-readable name
---@field worktree boolean|nil  true if this side is the working copy on disk

---@class diffl.Entry
---@field status string      one-letter status (M/A/D/R/C/T/U)
---@field old string         repo-relative path on the left
---@field new string         repo-relative path on the right
---@field session table

local function fail(msg)
  error({ diffl = msg }, 0)
end

local function run(cmd, cwd)
  local ok, res = pcall(function()
    return vim.system(cmd, { cwd = cwd }):wait()
  end)
  if not ok then
    fail(("failed to run %s: %s"):format(cmd[1], res))
  end
  return res.code == 0, res.stdout or "", res.stderr or ""
end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function read_file(path)
  local stat = vim.uv.fs_stat(path)
  if not stat or stat.type ~= "file" then
    return nil
  end
  local f = io.open(path, "rb")
  if not f then
    return nil
  end
  local data = f:read("*a")
  f:close()
  return data
end

--------------------------------------------------------------------------------
-- Git backend
--------------------------------------------------------------------------------

local Git = {}
Git.__index = Git

function Git.new(root)
  return setmetatable({ root = root, name = "git" }, Git)
end

function Git:git(args)
  local cmd = { "git", "-c", "core.quotepath=off", "--no-pager" }
  vim.list_extend(cmd, args)
  return run(cmd, self.root)
end

function Git:empty_tree()
  if not self._empty_tree then
    local ok, out = self:git({ "hash-object", "-t", "tree", "/dev/null" })
    self._empty_tree = ok and trim(out) or "4b825dc642cb6eb9a060e54bf8d69288fbee4904"
  end
  return self._empty_tree
end

---@return string|nil
function Git:try_resolve(rev)
  local ok, out = self:git({ "rev-parse", "--verify", "--quiet", "--end-of-options", rev .. "^{commit}" })
  if ok then
    return trim(out)
  end
end

---@return diffl.Rev
function Git:resolve(rev)
  local id = self:try_resolve(rev)
  if not id then
    fail(("git: unknown revision %q"):format(rev))
  end
  return { id = id, label = id:sub(1, 8) }
end

---@return diffl.Rev
function Git:parent(rev)
  if self:try_resolve(rev.id .. "^2") then
    vim.notify("Diffl: " .. rev.label .. " is a merge; diffing against its first parent", vim.log.levels.WARN)
  end
  local id = self:try_resolve(rev.id .. "^1")
  if not id then
    return { id = nil, label = "empty" }
  end
  return { id = id, label = id:sub(1, 8) }
end

---@return diffl.Rev
function Git:working_copy_parent()
  local id = self:try_resolve("HEAD")
  if not id then
    return { id = nil, label = "empty" } -- unborn branch
  end
  return { id = id, label = id:sub(1, 8) }
end

function Git:working_copy()
  return { id = nil, label = "working-copy", worktree = true }
end

---@param left diffl.Rev
---@param right diffl.Rev
function Git:changes(left, right)
  local args = { "diff", "--name-status", "-z", "-M", "--no-ext-diff", "--no-color", "--no-relative" }
  table.insert(args, left.id or self:empty_tree())
  if not right.worktree then
    table.insert(args, right.id or self:empty_tree())
  end
  table.insert(args, "--")
  local ok, out, err = self:git(args)
  if not ok then
    fail("git diff failed: " .. trim(err))
  end

  local changes = {}
  local toks = vim.split(out, "\0", { plain = true })
  local i = 1
  while i <= #toks and toks[i] ~= "" do
    local status = toks[i]:sub(1, 1)
    if status == "R" or status == "C" then
      table.insert(changes, { status = status, old = toks[i + 1], new = toks[i + 2] })
      i = i + 3
    else
      table.insert(changes, { status = status, old = toks[i + 1], new = toks[i + 1] })
      i = i + 2
    end
  end

  -- Untracked files are part of the working copy too (jj tracks them automatically).
  if right.worktree then
    local ok2, untracked = self:git({ "ls-files", "-z", "--others", "--exclude-standard", "--full-name" })
    if ok2 then
      for _, path in ipairs(vim.split(untracked, "\0", { plain = true, trimempty = true })) do
        table.insert(changes, { status = "A", old = path, new = path })
      end
    end
  end

  table.sort(changes, function(a, b)
    return a.new < b.new
  end)
  return changes
end

---@return string|nil
function Git:show(rev, path)
  if not rev.id then
    return nil
  end
  local ok, out = self:git({ "cat-file", "blob", rev.id .. ":" .. path })
  if ok then
    return out
  end
end

function Git:complete()
  local ok, out = self:git({ "for-each-ref", "--format=%(refname:short)", "refs/heads", "refs/tags", "refs/remotes" })
  local items = { "HEAD", "HEAD~1", "HEAD~2" }
  if ok then
    vim.list_extend(items, vim.split(out, "\n", { trimempty = true }))
  end
  return items
end

--------------------------------------------------------------------------------
-- Jujutsu backend
--------------------------------------------------------------------------------

local Jj = {}
Jj.__index = Jj

local JJ_ROOT_COMMIT = string.rep("0", 40)

function Jj.new(root)
  return setmetatable({ root = root, name = "jj", snapshotted = false }, Jj)
end

function Jj:jj(args)
  local cmd = { "jj", "--no-pager", "--color=never" }
  -- Snapshot the working copy once per :Diffl invocation, then reuse it.
  if self.snapshotted then
    table.insert(cmd, "--ignore-working-copy")
  end
  vim.list_extend(cmd, args)
  local ok, out, err = run(cmd, self.root)
  self.snapshotted = true
  return ok, out, err
end

---@return diffl.Rev
function Jj:resolve(rev)
  local tmpl = 'commit_id ++ " " ++ change_id.short(8) ++ " " ++ parents.map(|c| c.commit_id()).join(",") ++ "\\n"'
  local ok, out, err = self:jj({ "log", "--no-graph", "-r", rev, "-T", tmpl })
  if not ok then
    fail(("jj: %s"):format(trim(err)))
  end
  local lines = vim.split(out, "\n", { trimempty = true })
  if #lines ~= 1 then
    fail(("jj: revset %q resolved to %d revisions (expected 1)"):format(rev, #lines))
  end
  local id, change, parents = lines[1]:match("^(%S+) (%S+) ?(%S*)$")
  return {
    id = id,
    label = change,
    parents = vim.split(parents or "", ",", { trimempty = true }),
  }
end

---@return diffl.Rev
function Jj:parent(rev)
  local parents = rev.parents or {}
  if #parents == 0 then
    return { id = JJ_ROOT_COMMIT, label = "root" }
  end
  if #parents > 1 then
    vim.notify("Diffl: " .. rev.label .. " is a merge; diffing against its first parent", vim.log.levels.WARN)
  end
  return self:resolve(parents[1])
end

function Jj:working_copy()
  local wc = self:resolve("@")
  wc.worktree = true
  return wc
end

function Jj:working_copy_parent()
  return self:parent(self:resolve("@"))
end

function Jj:changes(left, right)
  local tmpl = '"[" ++ json(status) ++ "," ++ json(source.path()) ++ "," ++ json(target.path()) ++ "]\\n"'
  local ok, out, err = self:jj({
    "diff",
    "--from",
    left.id or JJ_ROOT_COMMIT,
    "--to",
    right.id,
    "-T",
    tmpl,
  })
  if not ok then
    fail("jj diff failed: " .. trim(err))
  end
  local changes = {}
  for _, line in ipairs(vim.split(out, "\n", { trimempty = true })) do
    local ok_json, t = pcall(vim.json.decode, line)
    if ok_json and type(t) == "table" then
      table.insert(changes, { status = STATUS[t[1]] or "M", old = t[2], new = t[3] })
    end
  end
  return changes
end

local function jj_fileset(path)
  return 'root-file:"' .. path:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

function Jj:show(rev, path)
  if not rev.id or rev.id == JJ_ROOT_COMMIT then
    return nil
  end
  local ok, out = self:jj({ "file", "show", "-r", rev.id, "--", jj_fileset(path) })
  if ok then
    return out
  end
end

function Jj:complete()
  local items = { "@", "@-", "@--", "trunk()" }
  local ok, out = self:jj({ "bookmark", "list", "-T", 'if(remote, "", name ++ "\\n")' })
  if ok then
    vim.list_extend(items, vim.split(out, "\n", { trimempty = true }))
  end
  return items
end

--------------------------------------------------------------------------------
-- Repo detection
--------------------------------------------------------------------------------

local function start_dir()
  local buf = api.nvim_get_current_buf()
  local name = api.nvim_buf_get_name(buf)
  if vim.bo[buf].buftype == "" and name ~= "" and not name:match("^%a[%w+.-]*://") then
    local dir = vim.fs.dirname(vim.fs.normalize(vim.fn.fnamemodify(name, ":p")))
    -- The buffer's directory may not exist yet (new file); walk up until it does.
    while dir and not exists(dir) do
      local parent = vim.fs.dirname(dir)
      dir = parent ~= dir and parent or nil
    end
    if dir then
      return dir
    end
  end
  return vim.fs.normalize(vim.uv.cwd())
end

--- Walk up from the current buffer (or cwd) to the nearest repo root.
--- At the same level, jj wins over git (colocated repos).
local function detect_repo()
  local dir = start_dir()
  local candidates = { dir }
  for parent in vim.fs.parents(dir) do
    table.insert(candidates, parent)
  end
  for _, d in ipairs(candidates) do
    if vim.fn.isdirectory(d .. "/.jj") == 1 then
      if vim.fn.executable("jj") ~= 1 then
        fail("found a jj repo at " .. d .. " but `jj` is not executable")
      end
      return Jj.new(d)
    end
    if exists(d .. "/.git") then
      return Git.new(d)
    end
  end
  fail("not inside a git or jj repository: " .. dir)
end

--------------------------------------------------------------------------------
-- Buffers & layout
--------------------------------------------------------------------------------

local group = api.nvim_create_augroup("Diffl", { clear = true })
local placeholders = {} ---@type table<integer, diffl.Entry>
local layouts = {} ---@type table<integer, {left: integer, right: integer, right_buf: integer}>
local session_count = 0

local function to_lines(content)
  if content == nil or content == "" then
    return {}
  end
  if content:find("\0", 1, true) then
    return { "[binary file]" }
  end
  local lines = vim.split(content, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  return lines
end

local function find_buf(name)
  for _, b in ipairs(api.nvim_list_bufs()) do
    if api.nvim_buf_get_name(b) == name then
      return b
    end
  end
end

--- Create a read-only scratch buffer holding a file's content at some revision.
local function scratch(name, path, content)
  local old = find_buf(name)
  if old then
    pcall(api.nvim_buf_delete, old, { force = true })
  end
  local buf = api.nvim_create_buf(false, true)
  api.nvim_buf_set_name(buf, name)
  api.nvim_buf_set_lines(buf, 0, -1, false, to_lines(content))
  local bo = vim.bo[buf]
  bo.buftype = "nofile"
  bo.bufhidden = "wipe"
  bo.swapfile = false
  bo.modifiable = false
  bo.readonly = true
  vim.b[buf].diffl = true
  local ft = vim.filetype.match({ filename = path, buf = buf })
  if ft then
    bo.filetype = ft
  end
  return buf
end

local function close_previous(tab, win)
  local prev = layouts[tab]
  layouts[tab] = nil
  if not prev then
    return
  end
  if prev.left ~= win and api.nvim_win_is_valid(prev.left) then
    if vim.b[api.nvim_win_get_buf(prev.left)].diffl then
      pcall(api.nvim_win_close, prev.left, true)
    end
  end
  if prev.right ~= win and api.nvim_win_is_valid(prev.right) then
    if api.nvim_win_get_buf(prev.right) == prev.right_buf then
      pcall(api.nvim_win_close, prev.right, false)
    end
    if api.nvim_win_is_valid(prev.right) then
      api.nvim_win_call(prev.right, function()
        vim.cmd("diffoff")
      end)
    end
  end
end

---@param entry diffl.Entry
---@param win integer window currently showing the placeholder
local function show(entry, win)
  local s = entry.session
  local vcs = s.vcs

  -- Left side.
  local left_content = entry.status ~= "A" and vcs:show(s.left, entry.old) or nil
  local left_name = ("diffl://%s/%s"):format(s.left.label, entry.old)

  -- Right side: use the real working-copy file whenever its content matches.
  local abs = s.vcs.root .. "/" .. entry.new
  local use_real, right_content = false, nil
  if entry.status ~= "D" then
    if s.right.worktree then
      use_real = exists(abs)
    else
      right_content = vcs:show(s.right, entry.new)
      local disk = read_file(abs)
      use_real = disk ~= nil and right_content ~= nil and disk == right_content
    end
  end

  local tab = api.nvim_win_get_tabpage(win)

  -- Quickfix refuses to reuse windows holding 'nofile' buffers, so jumping
  -- from the quickfix window may have opened a fresh split. If so, close it
  -- and reuse the existing diff layout's right window instead.
  local prev = layouts[tab]
  if prev and win > prev.newest and win ~= prev.right and api.nvim_win_is_valid(prev.right) then
    local target = prev.right
    api.nvim_set_current_win(target)
    pcall(api.nvim_win_close, win, false)
    win = target
  end

  close_previous(tab, win)

  -- `diffoff!` (not `diffoff`) so that buffers from the previous entry that are
  -- now hidden (e.g. the real file the quickfix jump just replaced) are also
  -- dropped from the diff; otherwise they'd linger as a third diff participant.
  api.nvim_win_call(win, function()
    vim.cmd("diffoff!")
  end)

  local right_buf
  if use_real then
    api.nvim_win_call(win, function()
      vim.cmd.edit(vim.fn.fnameescape(abs))
    end)
    right_buf = api.nvim_win_get_buf(win)
  else
    local suffix = entry.status == "D" and " (deleted)" or ""
    right_buf = scratch(("diffl://%s/%s%s"):format(s.right.label, entry.new, suffix), entry.new, right_content)
    api.nvim_win_set_buf(win, right_buf)
  end

  local suffix = entry.status == "A" and " (added)" or ""
  local left_buf = scratch(left_name .. suffix, entry.old, left_content)
  local left_win = api.nvim_open_win(left_buf, false, { split = "left", win = win })

  for _, w in ipairs({ left_win, win }) do
    api.nvim_win_call(w, function()
      vim.cmd("diffthis")
    end)
  end
  layouts[tab] = { left = left_win, right = win, right_buf = right_buf, newest = left_win }

  api.nvim_set_current_win(win)
  vim.cmd("diffupdate")
  api.nvim_win_set_cursor(win, { 1, 0 })
  if vim.fn.diff_hlID(1, 1) == 0 and vim.fn.diff_filler(1) == 0 then
    pcall(vim.cmd, "normal! ]c")
  end
end

api.nvim_create_autocmd("BufWinEnter", {
  group = group,
  pattern = "diffl-qf://*",
  callback = function(args)
    local entry = placeholders[args.buf]
    if not entry then
      return
    end
    vim.bo[args.buf].buflisted = false
    local win = api.nvim_get_current_win()
    vim.schedule(function()
      if not api.nvim_win_is_valid(win) or api.nvim_win_get_buf(win) ~= args.buf then
        return
      end
      local ok, err = pcall(show, entry, win)
      if not ok then
        local msg = type(err) == "table" and err.diffl or tostring(err)
        vim.notify("Diffl: " .. msg, vim.log.levels.ERROR)
      end
    end)
  end,
})

local function qftf(info)
  local items = vim.fn.getqflist({ id = info.id, items = 1 }).items
  local out = {}
  for i = info.start_idx, info.end_idx do
    local entry = placeholders[items[i].bufnr]
    if entry then
      local path = entry.new
      if entry.old ~= entry.new then
        path = entry.old .. " → " .. entry.new
      end
      table.insert(out, entry.status .. "  " .. path)
    else
      table.insert(out, items[i].text)
    end
  end
  return out
end

--------------------------------------------------------------------------------
-- Marking files as reviewed: `dd` / visual `d` in a Diffl quickfix list
--------------------------------------------------------------------------------

--- Remove entries first..last from the quickfix list shown in the current window.
--- Returns false if the list isn't a Diffl list (so callers can fall back).
local function remove_entries(first, last)
  if vim.fn.getwininfo(api.nvim_get_current_win())[1].loclist == 1 then
    return false
  end
  local qf = vim.fn.getqflist({ id = 0, idx = 0, items = 1, context = 1 })
  if type(qf.context) ~= "table" or not qf.context.diffl then
    return false
  end

  first, last = math.min(first, last), math.max(first, last)
  last = math.min(last, #qf.items)
  local removed = last - first + 1
  for _ = first, last do
    table.remove(qf.items, first)
  end

  -- Keep the "current entry" pointing at the same file where possible.
  local cur = qf.idx
  if cur > last then
    cur = cur - removed
  elseif cur >= first then
    cur = first
  end
  cur = math.max(1, math.min(cur, #qf.items))

  -- Action "r" replaces only the items; title, context and quickfixtextfunc stay.
  vim.fn.setqflist({}, "r", { id = qf.id, items = qf.items, idx = cur })

  if #qf.items == 0 then
    vim.notify("Diffl: all files reviewed", vim.log.levels.INFO)
  else
    api.nvim_win_set_cursor(0, { math.min(first, #qf.items), 0 })
  end
  return true
end

--- Run the built-in command for non-Diffl lists, reporting errors (e.g. E21) cleanly.
local function fallback(cmd)
  local ok, err = pcall(vim.cmd, cmd)
  if not ok then
    vim.notify(tostring(err):match("E%d+:.*") or tostring(err), vim.log.levels.ERROR)
  end
end

local function map_qf(buf)
  if vim.b[buf].diffl_mapped then
    return
  end
  vim.b[buf].diffl_mapped = true
  -- The quickfix buffer is shared by all lists (:colder/:cnewer), so check at
  -- press time whether the visible list is a Diffl list.
  vim.keymap.set("n", "dd", function()
    local line = vim.fn.line(".")
    local last = line + vim.v.count1 - 1
    if not remove_entries(line, last) then
      fallback("normal! " .. vim.v.count1 .. "dd")
    end
  end, { buffer = buf, desc = "Diffl: mark file(s) as reviewed" })
  vim.keymap.set("x", "d", function()
    local first, last = vim.fn.line("v"), vim.fn.line(".")
    api.nvim_feedkeys(api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
    if not remove_entries(first, last) then
      fallback("normal! gvd")
    end
  end, { buffer = buf, desc = "Diffl: mark selected files as reviewed" })
end

api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "qf",
  callback = function(args)
    map_qf(args.buf)
  end,
})

--------------------------------------------------------------------------------
-- Entry point
--------------------------------------------------------------------------------

---@param args string[]
function M.diffl(args)
  local ok, err = pcall(function()
    if #args > 2 then
      fail("usage: :Diffl [rev] | :Diffl <left> <right>")
    end
    local vcs = detect_repo()

    local left, right
    if #args == 0 then
      right = vcs:working_copy()
      left = vcs:working_copy_parent()
    elseif #args == 1 then
      right = vcs:resolve(args[1])
      left = vcs:parent(right)
    else
      left = vcs:resolve(args[1])
      right = vcs:resolve(args[2])
    end
    if left.label == right.label and left.id and right.id then
      left.label, right.label = left.id:sub(1, 12), right.id:sub(1, 12)
    end

    local changes = vcs:changes(left, right)
    local title = ("Diffl [%s] %s → %s"):format(vcs.name, left.label, right.label)
    if #changes == 0 then
      vim.notify(title .. ": no changes", vim.log.levels.INFO)
      return
    end

    session_count = session_count + 1
    local session = { vcs = vcs, left = left, right = right }
    local items = {}
    for i, c in ipairs(changes) do
      ---@type diffl.Entry
      local entry = { status = c.status, old = c.old, new = c.new, session = session }
      local buf = api.nvim_create_buf(false, true)
      api.nvim_buf_set_name(buf, ("diffl-qf://%d/%d/%s"):format(session_count, i, c.new))
      vim.bo[buf].bufhidden = "hide"
      vim.bo[buf].modifiable = false
      placeholders[buf] = entry
      table.insert(items, { bufnr = buf, lnum = 1, col = 1, text = c.status .. " " .. c.new })
    end

    vim.fn.setqflist({}, " ", {
      title = title,
      items = items,
      quickfixtextfunc = qftf,
      context = { diffl = session_count },
    })
    vim.cmd("botright copen")
    -- The quickfix window may already have existed (no FileType event).
    map_qf(api.nvim_get_current_buf())
  end)
  if not ok then
    local msg = type(err) == "table" and err.diffl or tostring(err)
    vim.notify("Diffl: " .. msg, vim.log.levels.ERROR)
  end
end

function M.complete(arglead)
  local ok, vcs = pcall(detect_repo)
  if not ok then
    return {}
  end
  local ok2, items = pcall(vcs.complete, vcs)
  if not ok2 then
    return {}
  end
  return vim.tbl_filter(function(s)
    return vim.startswith(s, arglead)
  end, items)
end

return M
