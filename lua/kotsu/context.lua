local M = {}

---@param modes string[]
---@return string[] lines "mode  lhs  desc", buffer-local mappings shadowing global ones
function M.mappings(modes)
  local out, seen = {}, {}
  local function add(mode, km)
    if not km.desc or km.desc == "" then return end
    local key = mode .. "\0" .. km.lhs
    if seen[key] then return end
    seen[key] = true
    out[#out + 1] = ("%s  %s  %s"):format(mode, (km.lhs:gsub(" ", "<Space>")), km.desc)
  end
  for _, mode in ipairs(modes) do
    for _, km in ipairs(vim.api.nvim_buf_get_keymap(0, mode)) do add(mode, km) end
    for _, km in ipairs(vim.api.nvim_get_keymap(mode)) do add(mode, km) end
  end
  return out
end

---@param question string
---@param opts kotsu.Options
---@return string
function M.build_prompt(question, opts)
  local v = vim.version()
  local maps = vim.list_slice(M.mappings(opts.context.modes), 1, opts.context.max_mappings)
  local ft = vim.bo.filetype
  local lines = {
    ("You are a Neovim expert. The user runs Neovim %d.%d and works keyboard only."):format(v.major, v.minor),
  }
  if opts.prompt.extra then lines[#lines + 1] = opts.prompt.extra end
  vim.list_extend(lines, {
    ("Current filetype: %s."):format(ft ~= "" and ft or "none"),
    "Give the fastest keyboard way to do the task below.",
    "Prefer the user's own mappings (listed below), then built-in Vim motions, operators and commands.",
    "Format: first line is only the key sequence in backticks. Then at most 4 short lines of explanation,",
    "and optionally one alternative. No preamble. Do not invent mappings that are not listed or built in.",
    "",
    "User's mappings (mode  keys  description):",
    table.concat(maps, "\n"),
    "",
    "Task: " .. question,
  })
  return table.concat(lines, "\n")
end

return M
