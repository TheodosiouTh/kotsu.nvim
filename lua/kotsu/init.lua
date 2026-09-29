local config = require("kotsu.config")
local context = require("kotsu.context")
local backends = require("kotsu.backend")
local ui = require("kotsu.ui")

local M = {}

local mapped_key
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
  ui.show(frame("Thinking…"), question, opts.window)

  local on_done = vim.schedule_wrap(function(success, text)
    if settled or id ~= request then return end
    settled = true
    ui.update(frame(success and text or ("**Error:** " .. text)))
  end)

  local run_ok, run_err = pcall(backend.run, prompt, { timeout_ms = opts.timeout_ms }, on_done)
  if not run_ok then on_done(false, ("backend `%s` failed: %s"):format(backend.name, run_err)) end
end

---Open the "How do I…" input prompt.
function M.prompt()
  vim.ui.input({ prompt = "How do I… " }, M.ask)
end

---Handler for :Kotsu.
---@param o table
function M.command(o)
  if o.args ~= "" then M.ask(o.args) else M.prompt() end
end

---@param opts? table see :h kotsu-config
function M.setup(opts)
  config.setup(opts)
  if mapped_key then
    pcall(vim.keymap.del, "n", mapped_key)
    mapped_key = nil
  end
  local key = config.options.keymap
  if key then
    vim.keymap.set("n", key, M.prompt, { desc = "How do I…? (shortcut help)" })
    mapped_key = key
  end
end

return M
