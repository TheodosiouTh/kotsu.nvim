---@type kotsu.Backend
local M = { name = "claude" }

function M.available()
  if vim.fn.executable("claude") == 1 then return true end
  return false, "`claude` CLI not found on PATH"
end

local FIXED_ARGS = { "--safe-mode", "--tools", "", "--no-session-persistence" }

function M.run(prompt, opts, on_done)
  local args = { "claude", "-p" }
  vim.list_extend(args, FIXED_ARGS)
  if opts.model then vim.list_extend(args, { "--model", opts.model }) end
  if opts.effort then vim.list_extend(args, { "--effort", opts.effort }) end
  table.insert(args, prompt)

  return vim.system(args, { text = true, timeout = opts.timeout_ms }, function(res)
    if res.code == 0 then
      local out = vim.trim(res.stdout or "")
      return on_done(true, out ~= "" and out or "(empty response)")
    end
    if res.code == 124 then
      return on_done(false, ("timed out after %dms."):format(opts.timeout_ms))
    end
    local err = vim.trim(res.stderr or "")
    on_done(false, ("claude exited with code %d:\n%s"):format(res.code, err ~= "" and err or "no error output"))
  end)
end

return M
