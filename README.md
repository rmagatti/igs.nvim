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

### Conflicts support

Send the conflicting files in the merge to the Quickfix list
- qf_conflicts()
      
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

```lua
vim.keymap.set("n", "<leader>gem", function() require('igs').edit_modified() end, { noremap = true })
vim.keymap.set("n", "<leader>ges", function() require('igs').edit_added() end, { noremap = true })
vim.keymap.set("n", "<leader>gea", function() require('igs').edit_all() end, { noremap = true })

vim.keymap.set("n", "<leader>gqm", function() require('igs').qf_modified() end, { noremap = true })
vim.keymap.set("n", "<leader>gqs", function() require('igs').qf_added() end, { noremap = true })
vim.keymap.set("n", "<leader>gqa", function() require('igs').qf_all() end, { noremap = true })

vim.keymap.set("n", "<leader>iqm", function() require('igs').qf_modified({ all_changes = true }) end, { noremap = true })
vim.keymap.set("n", "<leader>iqs", function() require('igs').qf_added({ all_changes = true }) end, { noremap = true })
vim.keymap.set("n", "<leader>iqa", function() require('igs').qf_all({ all_changes = true }) end, { noremap = true })
vim.keymap.set("n", "<leader>iqq", function() require('igs').qf_diff_branch({ all_changes = true }) end, { noremap = true })

vim.keymap.set("n", "<localleader>db", function() require('igs').qf_diff_branch({ all_changes = true }) end, { noremap = true })
vim.keymap.set("n", "<localleader>dd", function() require('igs').qf_diff_branch({ all_changes = false }) end, { noremap = true })

vim.keymap.set("n", "<leader>oc", function() require('igs').qf_conflicts() end, { noremap = true })
```
**Note:** the { all_changes=true } option makes it so each of the changes is individually listed in the quickfix list instead of just the first one per file. 


### Compatibility

```
NVIM v0.8.1
Build type: Release
LuaJIT 2.1.0-beta3
```
