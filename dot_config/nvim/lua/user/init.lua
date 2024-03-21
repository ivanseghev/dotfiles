return {
  plugins = {
    {
      'Exafunction/codeium.vim',
      config = function ()
        -- Change '<C-g>' here to any keycode you like.
        vim.keymap.set('i', '<C-g>', function () return vim.fn['codeium#Accept']() end, { expr = true, silent = true })
        -- vim.keymap.set('i', '<C-;>', function () return vim.fn['codeium#CycleCompletions'](1) end, { expr = true, silent = true })
        -- vim.keymap.set('i', '<C-,>', function () return vim.fn['codeium#CycleCompletions'](-1) end, { expr = true, silent = true })
        -- vim.keymap.set('i', '<C-x>', function () return vim.fn['codeium#Clear']() end, { expr = true, silent = true })
      end,
      event = 'BufEnter'
    },
    {
    'AstroNvim/astrotheme',
    opts = {
        -- AstroThemeColor = "#232627",
        palettes = {
            astrodark = {
                ui = {
                    base = "#232627", -- changed this color
                    tabline = "#232627", -- changed this color
                    winbar = "#797D87",
                    tool = "#232627", -- changed this color
                    inactive_base = "#232627", -- changed this color
                    statusline = "#232627", -- changed this color
                    split = "#232627", -- changed this color
                    float = "#232627", -- changed this color
                    -- title = c.ui.accent,
                    border = "#3A3E47",
                    current_line = "#3A3E47", -- changed this color
                    -- scrollbar = c.ui.accent,
                    selection = "#26343F",
                    -- TODO: combine menu_selection and selection
                    -- menu_selection = c.ui.selection,
                    highlight = "#23272F",
                    none_text = "#3A3E47",
                    text = "#9B9FA9",
                    text_active = "#ADB0BB",
                    text_inactive = "#494D56",
                    text_match = "#E0E0Ee",

                    prompt = "#21242A",
                },
          },
        },
        -- terminal_color = false,
        -- termguicolors = false,
        -- style = { 
        --   transparent = true,
        -- },
    },
    },
  },
  -- lsp = {
  --   mappings = {
  --     i = {
  --       -- this mapping will only be set in buffers with an LSP attached
  --       -- K = { function() vim.lsp.buf.hover() end, desc = "Hover symbol details" },
  --       ["<C-;>"] = { function () return vim.fn['codeium#CycleCompletions'](1) end, desc = "codeium cycle completions" },
  --       ["<C-,>"] = { function () return vim.fn['codeium#CycleCompletions'](-1) end, desc = "codeium cycle completions" },
  --     },
  --   },
  -- },
}
