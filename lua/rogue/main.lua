local original_global_data = {}
for k, v in pairs(_G) do
  original_global_data[k] = tostring(v)
end

Rogue = {}
local g = Rogue -- alias
local mesg = require("rogue.mesg")
local util = require("rogue.util")

g.version = "1.0.2"

-- Checks added global data is Rogue only
local function check_global()
  local added_global_data = {}
  for k, v in pairs(_G) do
    if not original_global_data[k] then
      added_global_data[k] = tostring(v)
    end
  end
  g.p("original_global_data", true)
  g.p("added_global_data", true)
end

local function init_dirs()
  g.home_dir = os.getenv("HOME")
  if not g.home_dir then
    g.home_dir = os.getenv("USERPROFILE")
    if not g.home_dir then
      g.home_dir = "."
    end
  end
  g.home_dir = g.home_dir:gsub("\\", "/")

  g.game_dir = vim.g["rogue#directory"]
  if type(g.game_dir) ~= "string" or g.game_dir == "" then
    g.game_dir = g.home_dir
  else
    g.game_dir = g.game_dir:gsub("\\", "/")
    g.game_dir = g.game_dir:gsub("~", g.home_dir)
    local exists = vim.fn.isdirectory(g.game_dir)
    if exists == 0 then
      vim.fn.mkdir(g.game_dir, "p")
    end
  end

  if string.char(g.home_dir:byte(#g.home_dir)) ~= "/" then
    g.home_dir = g.home_dir .. "/"
  end
  if string.char(g.game_dir:byte(#g.game_dir)) ~= "/" then
    g.game_dir = g.game_dir .. "/"
  end
end

local function main()
  if not mesg[1] then
    print("Cannot open message file")
    return
  end
  if vim.o.columns < g.DCOLS or vim.o.lines < g.DROWS then
    vim.fn.confirm(mesg[14])
    return
  end
  local first = true
  g.update_flag = true

  local args = util.split(util.get_vim_variable("s:args"), " ")
  if g.init(args) then
    -- restored game
    first = false
    g.refresh()
    g.play_level()
  end

  while true do
    g.free_stuff(g.level_objects)
    g.free_stuff(g.level_monsters)
    g.clear_level()
    g.make_level()
    g.put_objects()
    g.put_stairs()
    g.add_traps()
    g.put_mons()
    g.put_player(g.party_room)
    g.print_stats()
    if first then
      g.message(string.format(mesg[10], g.nick_name))
      first = false
    end
    g.refresh()
    g.play_level()
  end
end

function g.main()
  init_dirs()
  g.cov_start()
  local ret, err = xpcall(main, g.error_handler)
  g.cov_stop()
  -- check_global()
  g.log_close()
  if not ret and err ~= g.EXIT_SUCCESS then
    error(err)
  end
end

g.EXIT_SUCCESS = "g.EXIT_SUCCESS"
function g.exit(e)
  local level = 2
  if e == nil then
    e = g.EXIT_SUCCESS
  end
  if e == g.EXIT_SUCCESS then
    level = 0
  end
  error(e, level)
end

function g.expand_fname(fname, dir)
  fname = fname:gsub("\\", "/")
  if string.char(fname:byte(1)) == "~" then
    fname = fname:gsub("~/", g.home_dir)
  elseif not (fname:find("^/.*") or fname:find("^[A-Za-z]:/.*")) then
    fname = dir .. fname
  end
  return fname
end

function g.iconv_from_utf8(str)
  if g.needs_iconv then
    return vim.fn.iconv(str, "utf-8", vim.fn.eval("s:save_encoding"))
  end
  return str
end

function g.iconv_to_utf8(str)
  if g.needs_iconv then
    return vim.fn.iconv(str, vim.fn.eval("s:save_encoding"), "utf-8")
  end
  return str
end

return g
