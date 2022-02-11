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

local parse_changes = function()
  local status = vim.fn.system "git status --porcelain"
  logger.debug("status: ", vim.inspect(status))

  local changes = vim.split(vim.trim(status), "\n")

  return changes
end

-- TODO: use this
---@diagnostic disable-next-line: unused-local, unused-function
local get_processed_changes = function()
  local changes = parse_changes()
  local processed_changes = {}

  for _, change in ipairs(changes) do
    local change_type = vim.trim(change:sub(1, 1))
    local file_path = vim.trim(change:sub(3))

    table.insert(processed_changes, { change_type = change_type, file_path = file_path })
  end

  return processed_changes
end

local get_changed_lines = function(file_path)
  local diff_line = vim.fn.system("git diff -U0 " .. file_path .. " | grep '^@@'")
  local changed_lines = {}

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

M.qf_add = function(options)
  local type = options.type
  local all_changes = (function()
    if options.all_changes ~= nil then
      return options.all_changes
    else
      return false
    end
  end)()

  local changes = parse_changes()
  local qflist_what = {}

  for _, change in ipairs(changes) do
    local change_type = vim.trim(change:sub(1, 1))
    local file_path = vim.trim(change:sub(3))
    local changed_lines = get_changed_lines(file_path)

    logger.debug(change_type, file_path)

    if type == "all" then
      local bufnr = vim.fn.bufadd(file_path)

      if all_changes then
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

  logger.debug("qflist_what: ", vim.inspect(qflist_what))

  -- ref: https://git-scm.com/docs/git-status#_short_format
  local change_type_verbose = {
    ["??"] = "untracked",
    ["!!"] = "ignored",
    [" "] = "unmodified",
    ["M"] = "modified",
    ["A"] = "added",
    ["T"] = "file type changed",
    ["D"] = "deleted",
    ["R"] = "renamed",
    ["C"] = "copied",
    ["U"] = "updated but unmerged"
  }

  if vim.tbl_isempty(qflist_what) then
    logger.info("No " .. (change_type_verbose[type] or "any") .. " files to parse")
    return
  end

  vim.fn.setqflist(qflist_what)

  if M.conf.run_copen then
    vim.cmd [[copen]]
  end
end

M.edit = function(type)
  local changes = parse_changes()

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
  if vim.tbl_isempty(options) then
    return { all_changes = false }
  end

  local all_changes = (function()
    if options.all_changes ~= nil then
      return options.all_changes
    else
      return false
    end
  end)()

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

return M
