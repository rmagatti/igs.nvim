# Interactive Git Status

A minimalist Neovim plugin that enhances the usage of git status inside Neovim.

## ⭐ Features

### Edit files

Edit modified, added, unstaged or all files
- edit_modified()
- edit_added()
- edit_unstaged()
- edit_all()

### Send files to the Quickfix list

Send modified, added, unstaged or all files to the Quickfix List
- qf_modified()
- qf_added()
- qf_unstaged()
- qf_all()

### Diff support

Send the diff between a particular target (branch, file) to the Quickfix list
- qf_diff_branch()
this function is slightly different than the others as it asks for an input for a target to diff with.
      
### 🚀 Showcase

Send all changes to the Quickfix list
<img src="https://github.com/rmagatti/readme-assets/blob/main/interactive-git-status.gif" />

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

nnoremap <leader>iqm <cmd>lua require('igs').qf_modified({all_changes=true})<CR>
nnoremap <leader>iqs <cmd>lua require('igs').qf_added({all_changes=true})<CR>
nnoremap <leader>iqa <cmd>lua require('igs').qf_all({all_changes=true})<CR>
nnoremap <leader>iqq <cmd>lua require('igs').qf_diff_branch({all_changes=true})<CR>

nnoremap <localleader>db <cmd>lua require('igs').qf_diff_branch({all_changes=true})<CR>

```
**Note:** the { all_changes=true } option makes it so each of the changes is individually listed in the quickfix list instead of just the first one per file. 


### Compatibility

```
NVIM v0.5.0-dev+7d4f890aa
Build type: Release
LuaJIT 2.1.0-beta3
```
