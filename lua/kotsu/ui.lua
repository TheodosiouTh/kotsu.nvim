local M = {}

local state = { win = nil, buf = nil, question = nil, win_opts = nil, on_close = nil, lines = nil, hidden = false }

---@return boolean
function M.is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

---@return boolean
function M.is_hidden()
  return state.hidden and state.buf ~= nil and vim.api.nvim_buf_is_valid(state.buf)
end

function M.close()
  local win, buf, on_close = state.win, state.buf, state.on_close
  state.win, state.buf, state.question, state.win_opts, state.on_close, state.lines, state.hidden =
    nil, nil, nil, nil, nil, nil, false
  if win and vim.api.nvim_win_is_valid(win) then
    vim.api.nvim_win_close(win, true)
  end
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.api.nvim_buf_delete(buf, { force = true })
  end
  if on_close then on_close() end
end

function M.hide()
  if not M.is_open() then return false end
  local win = state.win
  state.win, state.hidden = nil, true
  vim.api.nvim_win_close(win, true)
  return true
end

local function truncate(s, max)
  if max < 1 then return "" end
  if vim.fn.strdisplaywidth(s) <= max then return s end
  local n = vim.fn.strchars(s)
  while n > 0 and vim.fn.strdisplaywidth(vim.fn.strcharpart(s, 0, n)) > max - 1 do
    n = n - 1
  end
  return vim.fn.strcharpart(s, 0, n) .. "…"
end

local function dimensions(lines)
  local o = state.win_opts
  local width = math.max(o.min_width, vim.fn.strdisplaywidth(" ⌨ " .. state.question .. " ") + 4)
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l) + 4)
  end
  width = math.min(width, math.floor(vim.o.columns * o.max_width))
  return width, " ⌨ " .. truncate(state.question, width - 8) .. " "
end

local function position(width, height)
  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.max(0, math.floor((vim.o.lines - height) / 2) - 1),
    col = math.max(0, math.floor((vim.o.columns - width) / 2)),
  }
end

local function set_lines(lines)
  state.lines = lines
  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false
end

local function resize(lines)
  local width, title = dimensions(lines)

  local cfg = position(width, 1)
  cfg.title, cfg.title_pos = title, "center"
  vim.api.nvim_win_set_config(state.win, cfg)

  local max_h = math.floor(vim.o.lines * state.win_opts.max_height)
  local rows = vim.api.nvim_win_text_height(state.win, {}).all
  vim.api.nvim_win_set_config(state.win, position(width, math.max(1, math.min(rows, max_h))))
end

local function fit(lines)
  set_lines(lines)
  if M.is_open() then resize(lines) end
end

local function open_window(win_opts)
  local cfg = position(win_opts.min_width, 1)
  cfg.style = "minimal"
  cfg.border = win_opts.border
  cfg.footer = " q / <Esc> to close "
  cfg.footer_pos = "center"
  cfg.zindex = 250
  state.win = vim.api.nvim_open_win(state.buf, true, cfg)
  vim.wo[state.win].wrap = true
  vim.wo[state.win].linebreak = true

  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set("n", key, M.close, { buffer = state.buf, nowait = true })
  end
  vim.api.nvim_create_autocmd("WinLeave", { buffer = state.buf, once = true, callback = M.hide })
end

---@param lines string[]
---@param question string single-line, already trimmed
---@param win_opts kotsu.WindowOptions
---@param on_close? fun() called once when this popup closes, incl. when superseded
function M.show(lines, question, win_opts, on_close)
  M.close()
  state.question, state.win_opts, state.on_close, state.hidden = question, win_opts, on_close, false

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = "hide"
  vim.bo[state.buf].filetype = "markdown"

  open_window(win_opts)
  fit(lines)
end

---@return boolean unhidden false when there was nothing hidden to restore
function M.unhide()
  if not M.is_hidden() then return false end
  state.hidden = false
  open_window(state.win_opts)
  resize(state.lines)
  return true
end

---@param lines string[]
---@return boolean updated false when the popup is fully closed (nothing to update)
function M.update(lines)
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then return false end
  fit(lines)
  return true
end

return M
