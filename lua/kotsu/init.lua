local config = require("kotsu.config")
local context = require("kotsu.context")
local backends = require("kotsu.backend")
local ui = require("kotsu.ui")

local M = {}

local mapped_key
local mapped_toggle_key
local request = 0

local function notify(msg, level)
  vim.notify("kotsu: " .. msg, level or vim.log.levels.ERROR)
end

local function frame(text)
  local lines = vim.split(text, "\n", { plain = true })
  table.insert(lines, 1, "")
  table.insert(lines, "")
  return lines
end

---Ask a question and show the answer in the popup.
---@param question? string
function M.ask(question)
  if type(question) ~= "string" then return end
  question = vim.trim((question:gsub("%s+", " ")))
  if question == "" then return end

  local opts = config.options
  local backend, err = backends.resolve(opts.backend)
  if not backend then return notify(err) end
  local ok, reason = backend.available()
  if not ok then return notify(reason) end

  local prompt = context.build_prompt(question, opts)

  request = request + 1
  local id, settled = request, false
  local ticket = {}

  ui.show(frame("Thinking…"), question, opts.window, function()
    local h = ticket.handle
    if h then pcall(function() if not h:is_closing() then h:kill(15) end end) end
  end)

  local on_done = vim.schedule_wrap(function(success, text)
    if settled or id ~= request then return end
    settled = true
    ui.update(frame(success and text or ("**Error:** " .. text)))
  end)

  local run_ok, result = pcall(
    backend.run, prompt, { timeout_ms = opts.timeout_ms, model = opts.model, effort = opts.effort }, on_done
  )
  if run_ok then
    ticket.handle = result
  else
    on_done(false, ("backend `%s` failed: %s"):format(backend.name, result))
  end
end

---Open the "How do I…" input prompt.
function M.prompt()
  vim.ui.input({ prompt = "How do I… " }, M.ask)
end

---Hide the popup if open, or restore it if hidden. No-op if nothing's been asked yet.
function M.toggle()
  if ui.is_open() then
    ui.hide()
  elseif ui.is_hidden() then
    ui.unhide()
  end
end

---Handler for :Kotsu.
---@param o table
function M.command(o)
  if o.args ~= "" then M.ask(o.args) else M.prompt() end
end

---@param old_key string|false?
---@param new_key string|false?
---@param modes string|string[]
---@return string|false? still_mapped the key now mapped, for the caller to remember
local function sync_keymap(old_key, new_key, fn, desc, modes)
  if old_key then pcall(vim.keymap.del, modes, old_key) end
  if new_key then vim.keymap.set(modes, new_key, fn, { desc = desc }) end
  return new_key or nil
end

---@param opts? table see :h kotsu-config
function M.setup(opts)
  config.setup(opts)
  mapped_key = sync_keymap(mapped_key, config.options.keymap, M.prompt, "How do I…? (shortcut help)", "n")
  mapped_toggle_key =
    sync_keymap(mapped_toggle_key, config.options.toggle_keymap, M.toggle, "Hide/unhide the kotsu popup", { "n", "t" })
end

return M
