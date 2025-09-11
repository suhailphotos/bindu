-- lua/suhail/lazy/markdown.lua
return {
  "MeanderingProgrammer/render-markdown.nvim",
  -- Only load for Markdown files or when its command is used
  ft = { "markdown" },
  cmd = { "RenderMarkdown" },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  opts = {
    -- Start OFF. Nothing renders until you toggle.
    enabled = false,

    -- If you do enable it (manually), render in Normal mode only.
    -- This avoids any mode-flip redraws.
    render_modes = { "n" },

    -- Keep things snappy
    debounce = 120,

    -- Keep your previous choices consistent (from avante.lua)
    latex = { enable = false },
    html  = { enable = false },
  },

  -- Handy toggles (buffer-local by default)
  keys = {
    { "<leader>mr", "<cmd>RenderMarkdown buf_toggle<CR>", desc = "Markdown: toggle render (buffer)" },
    { "<leader>m1", "<cmd>RenderMarkdown buf_enable<CR>", desc = "Markdown: enable render (buffer)" },
    { "<leader>m0", "<cmd>RenderMarkdown buf_disable<CR>", desc = "Markdown: disable render (buffer)" },
  },
}
