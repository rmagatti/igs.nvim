# Interactive Git Status

A minimalist Neovim plugin that enhances the usage of git status inside Neovim.

## ⭐ Features

- Edit changed, staged, unstaged or all files
- Send changed, staged, unstaged or all files to the Quickfix List

### 🚀 Showcase

<img src="https://github.com/rmagatti/readme-assets/blob/main/goto-preview-zoomed.gif" />

### 📦 Installation

Packer.nvim

```lua
use {
  'rmagatti/igs.nvim',
  config = function()
    require('igs').setup {}
  end
}
```

### ⚙️ Configuration

**Default**

```lua
require('igs').setup {
  debug = false, -- print debug logs
  log_level = "info", -- log level for igs
  run_copen = true, -- run copen after qf commands
  default_mappings = false, -- set default mappings
}
```

### ⌨️ Mappings

There are no mappings by default, you can set `default_mappings = true` in the config to make use of the mappings I use or define your own.

**Default**

```viml
nnoremap <leader>gem <cmd>lua require('igs').edit_modified()<CR>
nnoremap <leader>ges <cmd>lua require('igs').edit_staged()<CR>
nnoremap <leader>gea <cmd>lua require('igs').edit_all()<CR>

nnoremap <leader>gqm <cmd>lua require('igs').qf_modified()<CR>
nnoremap <leader>gqs <cmd>lua require('igs').qf_staged()<CR>
nnoremap <leader>gqa <cmd>lua require('igs').qf_all()<CR>
```

### Compatibility

```
NVIM v0.5.0-dev+7d4f890aa
Build type: Release
LuaJIT 2.1.0-beta3
```
