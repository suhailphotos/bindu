-- lua/suhail/lazy/markdown.lua
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = { "markdown" },                 -- load only for md
  cmd = { "RenderMarkdown" },          -- or when you call the command
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    enabled = false,                   -- OFF by default (no visuals)
    render_modes = { "n" },            -- render only in Normal mode
    debounce = 120,
    latex = { enable = false },
    html  = { enable = false },
  },
  keys = {
    { "<leader>mr", "<cmd>RenderMarkdown buf_toggle<CR>", desc = "Markdown: toggle render (buffer)" },
    { "<leader>m1", "<cmd>RenderMarkdown buf_enable<CR>", desc = "Markdown: enable render (buffer)" },
    { "<leader>m0", "<cmd>RenderMarkdown buf_disable<CR>", desc = "Markdown: disable render (buffer)" },
  },
}
