local source = {}
local Job = require'plenary.job'

---Source constructor.
source.new = function()
  local self = setmetatable({}, { __index = source })
  self.your_awesome_variable = 1
  return self
end

---Return the source is available or not.
---@return boolean
function source:is_available()
  return true
end

---Return the source name for some information.
function source:get_debug_name()
  return 'npm'
end

---Invoke completion (required).
---  If you want to abort completion, just call the callback without arguments.
---@param params cmp.SourceCompletionApiParams
---@param callback fun(response: lsp.CompletionResponse|nil)
function source:complete(params, callback)
  local cur_line = params.context.cursor_line
  local cur_col = params.context.cursor.col
  local _, idx_after_third_quote = string.find(cur_line, '.*".*".*"')
  local find_version = false
  if idx_after_third_quote then
    find_version = cur_col >= idx_after_third_quote
  end
  print(find_version)
  local name = string.match(cur_line, '%s*"([^"]*)"?')
  if find_version then
    Job:new({
      "npm",
      "info",
      name,
      "version",
      "--json",
      on_exit = function (job)
        local result = job:result()
        table.remove(result, 1)
        table.remove(result, table.getn(result))
        local items = {}
        for _, npm_item in ipairs(result) do
          local version = string.match(npm_item, '%s*"(.*)",?')
          table.insert(items, { label = version })
        end
        callback(items)
      end
    }):start()
  else
    Job:new({
    "npm",
    "search",
    "--no-description",
    "-p",
    name,
    on_exit = function (job)
      local result = job:result()
      local items = {}
      for _, npm_item in ipairs(result) do
        local name, _, version = string.match(npm_item, "(.*)\t(.*)\t(.*)\t")
        name = name:gsub("%s.*", "")
        local label = name .. "" .. version
        table.insert(items, { label = label, insertText = name })
      end
      callback(items)
     end
    }):start()
  end
end

---Resolve completion item that will be called when the item selected or before the item confirmation.
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:resolve(completion_item, callback)
  callback(completion_item)
end

---Execute command that will be called when after the item confirmation.
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function source:execute(completion_item, callback)
  callback(completion_item)
end

require('cmp').register_source('npm', source.new())
