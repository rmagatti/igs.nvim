local M = {
  conf = {
    debug = false, -- print debug logs
    log_level = "info", -- log level for igs
    run_copen = true, -- run copen after qf commands
    default_mappings = false, -- set default mappings
  },
}

M.setup = function(config)
  M.conf = vim.tbl_deep_extend("force", M.conf, config or {})

  if M.conf.default_mappings then
    vim.cmd [[
    nnoremap <leader>gem <cmd>lua require('igs').edit_modified()<CR>
    nnoremap <leader>ges <cmd>lua require('igs').edit_added()<CR>
    nnoremap <leader>gea <cmd>lua require('igs').edit_all()<CR>

    nnoremap <leader>gqm <cmd>lua require('igs').qf_modified()<CR>
    nnoremap <leader>gqs <cmd>lua require('igs').qf_added()<CR>
    nnoremap <leader>gqa <cmd>lua require('igs').qf_all()<CR>

    nnoremap <leader>iqm <cmd>lua require('igs').qf_modified({all_changes=true})<CR>
    nnoremap <leader>iqs <cmd>lua require('igs').qf_added({all_changes=true})<CR>
    nnoremap <leader>iqa <cmd>lua require('igs').qf_all({all_changes=true})<CR>
    nnoremap <leader>iqq <cmd>lua require('igs').qf_diff_branch({all_changes=true})<CR>

    nnoremap <localleader>db <cmd>lua require('igs').qf_diff_branch({all_changes=true})<CR>
    nnoremap <localleader>dd <cmd>lua require('igs').qf_diff_branch({all_changes=false})<CR>
  ]]
  end
end

local logger = {
  debug = function(...)
    if M.conf.debug then
      print("igs:", ...)
    end
  end,
  info = function(...)
    if M.conf.debug or M.conf.log_level == "info" then
      print("igs:", ...)
    end
  end,
}

local open_qflist = function(qflist_what)
  logger.debug("qflist_what: ", vim.inspect(qflist_what))

  if vim.tbl_isempty(qflist_what) then
    logger.info "No files to add to the quickfix list"
    return
  end

  vim.fn.setqflist(qflist_what)

  if M.conf.run_copen then
    vim.cmd [[copen]]
  end
end

local parse_status_changes = function()
  local status = vim.fn.system "git status --porcelain"
  logger.debug("status: ", vim.inspect(status))

  local changes = vim.split(vim.trim(status), "\n")

  return changes
end

-- TODO: use this
---@diagnostic disable-next-line: unused-local, unused-function
local get_processed_changes = function()
  local changes = parse_status_changes()
  local processed_changes = {}

  for _, change in ipairs(changes) do
    local change_type = vim.trim(change:sub(1, 1))
    local file_path = vim.trim(change:sub(3))

    table.insert(processed_changes, { change_type = change_type, file_path = file_path })
  end

  return processed_changes
end

local get_changes = function(diff_target, options)
  local diff_line = vim.fn.system("git diff -U0 " .. diff_target .. " | grep '^@@'")
  local changed_lines = {}

  if options and options.target_branch then
    local diff_cmd = "git diff -U0 .." .. options.target_branch .. " " .. diff_target .. " | grep '^@@'"
    diff_line = vim.fn.system(diff_cmd)

    logger.debug("diff_line: ", diff_line)
  end

  local chunks = vim.split(vim.trim(diff_line), " ")
  for _, chunk in ipairs(chunks) do
    local first_letter = chunk:sub(1, 1)

    if first_letter == "+" then
      local line_nr = vim.split(chunk, ",")[1]:gsub("+", "")
      table.insert(changed_lines, tonumber(line_nr))
    end
  end

  return changed_lines
end

local get_changed_files = function(diff_target)
  local diff = vim.fn.system("git diff -U0 --name-only " .. diff_target)

  local filepaths = vim.split(vim.trim(diff), "\n")

  logger.debug("filepaths: ", vim.inspect(filepaths))

  return filepaths
end

local parse_boolean_option = function(options, option_name)
  if options and options[option_name] ~= nil then
    return options[option_name]
  else
    return false
  end
end

M.qf_add_branch_diff = function(options)
  local all_changes = parse_boolean_option(options, "all_changes")
  local branch_name = options.branch_name or error "branch_name is required"
  local qflist_what = {}

  local changed_files = get_changed_files(branch_name)

  logger.debug("changed_files: ", vim.inspect(changed_files))

  for _, file in ipairs(changed_files) do
    local changed_lines = get_changes(file, { target_branch = branch_name })
    local bufnr = vim.fn.bufadd(file)

    logger.debug("changed_lines: ", vim.inspect(changed_lines))

    if all_changes then
      for _, line in ipairs(changed_lines) do
        table.insert(qflist_what, { bufnr = bufnr, lnum = line })
      end
    else
      table.insert(qflist_what, { bufnr = bufnr, lnum = changed_lines[1], col = 0 })
    end
  end

  open_qflist(qflist_what)
end

M.qf_add = function(options)
  local changes = parse_status_changes()
  local all_changes = parse_boolean_option(options, "all_changes")
  local type = options.type
  local qflist_what = {}

  for _, change in ipairs(changes) do
    local change_type = vim.trim(change:sub(1, 1))
    local file_path = vim.trim(change:sub(3))
    local changed_lines = get_changes(file_path)

    logger.debug(change_type, file_path)

    if type == "all" then
      local bufnr = vim.fn.bufadd(file_path)
      logger.debug("type: ", type)

      if all_changes then
        logger.debug("all_changes: ", all_changes)

        for _, line in ipairs(changed_lines) do
          table.insert(qflist_what, { bufnr = bufnr, lnum = line })
        end
      else
        table.insert(qflist_what, { bufnr = bufnr, lnum = changed_lines[1], col = 0 })
      end
    elseif change_type == type then
      local bufnr = vim.fn.bufadd(file_path)
      table.insert(qflist_what, { bufnr = bufnr, lnum = changed_lines[1], col = 0 })
    end
  end

  -- -- ref: https://git-scm.com/docs/git-status#_short_format
  -- local change_type_verbose = {
  --   ["??"] = "untracked",
  --   ["!!"] = "ignored",
  --   [" "] = "unmodified",
  --   ["M"] = "modified",
  --   ["A"] = "added",
  --   ["T"] = "file type changed",
  --   ["D"] = "deleted",
  --   ["R"] = "renamed",
  --   ["C"] = "copied",
  --   ["U"] = "updated but unmerged",
  -- }

  open_qflist(qflist_what)
end

M.edit = function(type)
  local changes = parse_status_changes()

  for _, change in ipairs(changes) do
    local change_type = vim.trim(change:sub(1, 1))
    local file_path = vim.trim(change:sub(3))

    if type == "all" then
      vim.cmd("edit " .. file_path)
    elseif change_type == type then
      logger.debug("editing", change_type, file_path)
      vim.cmd("edit " .. file_path)
    end
  end
end

local function process_options(options)
  if not options or vim.tbl_isempty(options) then
    return { all_changes = false }
  end

  local all_changes = parse_boolean_option(options, "all_changes")

  return { all_changes = all_changes }
end

M.edit_modified = function()
  M.edit "M"
end

M.edit_added = function()
  M.edit "A"
end

M.edit_unstaged = function()
  M.edit "??"
end

M.edit_all = function()
  M.edit "all"
end

M.qf_modified = function(options)
  M.qf_add { type = "M", all_changes = process_options(options).all_changes }
end

M.qf_added = function(options)
  M.qf_add { type = "A", all_changes = process_options(options).all_changes }
end

M.qf_unstaged = function(options)
  M.qf_add { type = "??", all_changes = process_options(options).all_changes }
end

M.qf_all = function(options)
  M.qf_add { type = "all", all_changes = process_options(options).all_changes }
end

M.qf_diff_branch = function(options)
  vim.ui.input({ prompt = "Target diff with: " }, function(branch_name)
    M.qf_add_branch_diff { all_changes = process_options(options).all_changes, branch_name = branch_name }
  end)
end

return M
