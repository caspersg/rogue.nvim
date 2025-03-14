local M = {}

M.loadstring = _VERSION >= "Lua 5.2" and load or loadstring

---@param var string
---@return unknown
function M.get_vim_variable(var)
  if vim.fn.exists(var) ~= 0 then
    return vim.fn.eval(var)
  end
end

local bit_exists, bit = pcall(require, "bit")
if bit_exists then
  M.bxor = bit.bxor
elseif _VERSION >= "Lua 5.3" then
  M.bxor = require("rogue.util.lua53")
elseif _VERSION >= "Lua 5.2" then
  ---@diagnostic disable-next-line: undefined-global
  M.bxor = bit32.bxor
else
  function M.bxor(x, y)
    local n = 0
    local ret = 0

    repeat
      local bit_x = x % 2
      local bit_y = y % 2
      if bit_x ~= bit_y then
        ret = ret + 2 ^ n
      end
      x = M.int_div(x, 2)
      y = M.int_div(y, 2)
      n = n + 1
    until x == 0 and y == 0
    return ret
  end
end

---@param var string
---@param value unknown
function M.set_vim_variable(var, value)
  if vim then
    if type(value) == "number" then
      vim.cmd("let " .. var .. " = " .. tostring(value))
    elseif type(value) == "string" then
      vim.cmd("let " .. var .. ' = "' .. value .. '"')
    end
  end
end

local function dump(obj, indent_depth, dumped_table_list, hex_flag)
  if not indent_depth then
    indent_depth = 0
  end
  if not dumped_table_list then
    dumped_table_list = {}
  end

  local t = type(obj)
  local s
  if t == "table" then
    local exists = false
    for _, v in ipairs(dumped_table_list) do
      if v == tostring(obj) then
        exists = true
      end
    end
    s = "{"
    if exists then
      s = s .. " ... "
    else
      table.insert(dumped_table_list, tostring(obj))
      local indent = "  "
      local is_empty = true
      for k, v in pairs(obj) do
        is_empty = false
        s = s .. "\n" .. string.rep(indent, indent_depth + 1)
        if type(k) == "string" then
          s = s .. k
        else
          s = s .. "[" .. k .. "]"
        end
        s = s .. " = "
        s = s .. dump(v, indent_depth + 1, dumped_table_list, hex_flag)
        s = s .. ","
      end
      if not is_empty then
        s = s .. "\n" .. string.rep(indent, indent_depth)
      end
    end
    s = s .. "} " .. tostring(obj)

    if indent_depth == 0 and not s:find("{ ... } table") then
      s = s:gsub(" table:[ xX%x]*", "")
    end
  elseif t == "string" then
    s = '"' .. obj .. '"'
  elseif hex_flag and t == "number" then
    s = string.format("0x%x", obj)
  else
    s = tostring(obj)
  end

  return s
end

---@param obj unknown
---@param hex_flag? boolean
---@return string
function M.dump(obj, hex_flag)
  return dump(obj, nil, nil, hex_flag or false)
end

---@param dividend number
---@param divisor number
---@return integer
function M.int_div(dividend, divisor)
  return math.floor(dividend / divisor)
end

function M.strwidth(s)
  return vim.fn.strwidth(s)
end

function M.split(str, sep)
  local ret = {}
  while true do
    local idx = str:find(sep, 1, true)
    if not idx then
      table.insert(ret, str)
      break
    end
    if idx == 1 then
      str = str:sub(idx + 1)
    else
      local prev = str:sub(1, idx - 1)
      str = str:sub(idx + 1)
      table.insert(ret, prev)
    end
  end
  return ret
end

function M.msleep(n)
  vim.cmd("sleep " .. tostring(n) .. "m")
end

return M
