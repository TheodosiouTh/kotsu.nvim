if vim.g.loaded_kotsu then return end
vim.g.loaded_kotsu = true

if vim.fn.has("nvim-0.10") == 0 then
  vim.notify("kotsu needs Neovim 0.10 or newer", vim.log.levels.ERROR)
  return
end

vim.api.nvim_create_user_command("Kotsu", function(o)
  require("kotsu").command(o)
end, { nargs = "*", desc = "Ask how to do something with shortcuts" })

vim.keymap.set("n", "<Plug>(kotsu-prompt)", function()
  require("kotsu").prompt()
end, { desc = "How do I…? (shortcut help)" })

vim.keymap.set({ "n", "t" }, "<Plug>(kotsu-toggle)", function()
  require("kotsu").toggle()
end, { desc = "Hide/unhide the kotsu popup" })
