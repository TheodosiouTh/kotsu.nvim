local config = require("kotsu.config")
local context = require("kotsu.context")
local backends = require("kotsu.backend")

local M = {}

function M.check()
  local h = vim.health
  h.start("kotsu")

  if vim.fn.has("nvim-0.10") == 1 then
    h.ok("Neovim " .. tostring(vim.version()))
  else
    h.error("Neovim 0.10 or newer is required")
  end

  local opts = config.options
  local backend, err = backends.resolve(opts.backend)
  if not backend then
    h.error(err)
  else
    local ok, reason = backend.available()
    if ok then
      h.ok(("backend `%s` is available"):format(backend.name))
    else
      h.error(reason, { "Install the backend, or set `backend` in setup(). See :h kotsu-backend" })
    end
  end

  local n = #context.mappings(opts.context.modes)
  if n == 0 then
    h.warn("no mappings with a description found; answers will only use built-in keys")
  else
    h.ok(("%d mappings with descriptions found (sending up to %d)"):format(n, opts.context.max_mappings))
  end

  h.info(("modes %s, timeout %dms"):format(table.concat(opts.context.modes, " "), opts.timeout_ms))
end

return M
