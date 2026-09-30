local M = {}

---@class kotsu.ContextOptions
---@field modes string[]
---@field max_mappings integer

---@class kotsu.PromptOptions
---@field extra? string

---@class kotsu.WindowOptions
---@field border string|string[]
---@field min_width integer
---@field max_width number
---@field max_height number

---@class kotsu.Options
---@field keymap string|false
---@field backend string|kotsu.BackendRun
---@field timeout_ms integer
---@field model? string
---@field effort? "low"|"medium"|"high"|"xhigh"|"max"
---@field context kotsu.ContextOptions
---@field prompt kotsu.PromptOptions
---@field window kotsu.WindowOptions
M.defaults = {
  keymap = "<Leader>?",
  backend = "claude",
  timeout_ms = 60000,
  model = "haiku",
  effort = "low",
  context = {
    modes = { "n", "x", "o", "i" },
    max_mappings = 500,
  },
  prompt = {
    extra = nil,
  },
  window = {
    border = "rounded",
    min_width = 40,
    max_width = 0.7,
    max_height = 0.6,
  },
}

---@type kotsu.Options
M.options = vim.deepcopy(M.defaults)

local function check(name, ok, expected)
  if not ok then
    error(("kotsu: option `%s` must be %s"):format(name, expected), 0)
  end
end

local function is_ratio(v) return type(v) == "number" and v > 0 and v <= 1 end

local function is_positive(v) return type(v) == "number" and v > 0 end

---@param opts? table
---@return kotsu.Options
function M.setup(opts)
  check("opts", opts == nil or type(opts) == "table", "a table or nil")
  opts = opts or {}

  local o = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts)
  if opts.context and opts.context.modes then
    o.context.modes = vim.deepcopy(opts.context.modes)
  end

  check("keymap", o.keymap == false or type(o.keymap) == "string", "a string or false")
  check("backend", type(o.backend) == "string" or type(o.backend) == "function", "a string or a function")
  check("timeout_ms", is_positive(o.timeout_ms), "a positive number")
  check("model", o.model == nil or type(o.model) == "string", "a string or nil")
  check(
    "effort",
    o.effort == nil or vim.tbl_contains({ "low", "medium", "high", "xhigh", "max" }, o.effort),
    "one of low|medium|high|xhigh|max, or nil"
  )
  check("context.modes", vim.islist(o.context.modes), "a list of mode strings")
  check("context.max_mappings", is_positive(o.context.max_mappings), "a positive number")
  check("prompt.extra", o.prompt.extra == nil or type(o.prompt.extra) == "string", "a string or nil")
  check("window.border", type(o.window.border) == "string" or vim.islist(o.window.border), "a string or a list")
  check("window.min_width", is_positive(o.window.min_width), "a positive number")
  check("window.max_width", is_ratio(o.window.max_width), "a number in (0, 1]")
  check("window.max_height", is_ratio(o.window.max_height), "a number in (0, 1]")

  M.options = o
  return o
end

return M
