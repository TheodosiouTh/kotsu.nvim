local M = {}

---@alias kotsu.BackendRun fun(prompt: string, opts: { timeout_ms: integer, model: string?, effort: string? }, on_done: fun(ok: boolean, text: string)): any?

---@class kotsu.Backend
---@field name string
---@field available fun(): boolean, string?
---@field run kotsu.BackendRun

local builtin = {
  claude = "kotsu.backend.claude",
}

---@param backend string|kotsu.BackendRun
---@return kotsu.Backend? backend, string? err
function M.resolve(backend)
  if type(backend) == "function" then
    return {
      name = "custom",
      available = function() return true end,
      run = backend,
    }
  end

  local mod = builtin[backend]
  if not mod then
    local names = vim.tbl_keys(builtin)
    table.sort(names)
    return nil, ("unknown backend %q (available: %s)"):format(tostring(backend), table.concat(names, ", "))
  end

  local ok, loaded = pcall(require, mod)
  if not ok then
    return nil, ("backend `%s` failed to load: %s"):format(backend, loaded)
  end
  return loaded
end

return M
