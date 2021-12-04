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
    nnoremap <leader>ges <cmd>lua require('igs').edit_staged()<CR>
    nnoremap <leader>gea <cmd>lua require('igs').edit_all()<CR>

    nnoremap <leader>gqm <cmd>lua require('igs').qf_modified()<CR>
    nnoremap <leader>gqs <cmd>lua require('igs').qf_staged()<CR>
    nnoremap <leader>gqa <cmd>lua require('igs').qf_all()<CR>
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

M.qf_add = function(type)
  local changes = parse_changes()
  local qflist_what = {}

  for _, change in ipairs(changes) do
    local change_type = vim.trim(change:sub(1, 1))
    local file_path = vim.trim(change:sub(3))
    local changed_lines = get_changed_lines(file_path)

    logger.debug(change_type, file_path)

    if type == "all" then
      local bufnr = vim.fn.bufadd(file_path)
      table.insert(qflist_what, { bufnr = bufnr, lnum = changed_lines[1], col = 0 })
    elseif change_type == type then
      local bufnr = vim.fn.bufadd(file_path)
      table.insert(qflist_what, { bufnr = bufnr, lnum = changed_lines[1], col = 0 })
    end
  end

  logger.debug("qflist_what: ", vim.inspect(qflist_what))

  if vim.tbl_isempty(qflist_what) then
    logger.info "No changed files to parse"
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

M.edit_modified = function()
  M.edit "M"
end
M.edit_staged = function()
  M.edit "A"
end
M.edit_unstaged = function()
  M.edit "??"
end
M.edit_all = function()
  M.edit "all"
end

M.qf_modified = function()
  M.qf_add "M"
end
M.qf_staged = function()
  M.qf_add "A"
end
M.qf_unstaged = function()
  M.qf_add "??"
end
M.qf_all = function()
  M.qf_add "all"
end

return M
