local g = require("rogue.main")
local mesg = require("rogue.mesg")
local util = require("rogue.util")

local score_file = "rogue_vim.scores"

local xxx_f = 0
local xxx_s = 0

local function center_margin(buf)
  return util.int_div((g.DCOLS - util.strwidth(buf:gsub("%(%w%(", ""))), 2)
end

local function center(row, buf)
  g.mvaddstr(row, center_margin(buf), buf)
end

local function layer(lower, lcol, upper, ucol)
  local s1 = lower:sub(1, ucol - lcol)
  local s2 = lower:sub(ucol - lcol + 1 + util.strwidth(upper:gsub("%(%w%(", "")))
  return s1 .. upper .. s2
end

local function tomb_str(str, xpos, idx, upper)
  if upper then
    local ucol = center_margin(upper)
    str[idx] = layer(str[idx], xpos[idx], upper, ucol)
  end
  local count = 0
  str[idx], count = str[idx]:gsub("^(%-+)$", "(g(%1(g(")
  if count > 0 then
    return
  end
  str[idx], count = str[idx]:gsub("^(_.*_)$", "(g(%1(g(")
  if count > 0 then
    return
  end
  str[idx] = str[idx]:gsub("^/", "(g(/(g("):gsub("\\\\$", "(g(\\\\(g("):gsub("%|", "(g(|(g("):gsub("%*", "(y(*(y(")
end

local function is_vowel(ch)
  local c = string.char(ch:byte(1))
  return (c == "a") or (c == "e") or (c == "i") or (c == "o") or (c == "u")
end

function g.killed_by(monster, other)
  local xpos = {
    util.int_div(g.DCOLS, 2) - 5,
    util.int_div(g.DCOLS, 2) - 6,
    util.int_div(g.DCOLS, 2) - 7,
    util.int_div(g.DCOLS, 2) - 8,
    util.int_div(g.DCOLS, 2) - 9,
    util.int_div(g.DCOLS, 2) - 10,
    util.int_div(g.DCOLS, 2) - 10,
    util.int_div(g.DCOLS, 2) - 10,
    util.int_div(g.DCOLS, 2) - 10,
    util.int_div(g.DCOLS, 2) - 10,
    util.int_div(g.DCOLS, 2) - 10,
    util.int_div(g.DCOLS, 2) - 10,
    util.int_div(g.DCOLS, 2) - 11,
    util.int_div(g.DCOLS, 2) - 19,
  }
  local str = {
    "----------",
    "/          \\\\",
    "/            \\\\",
    "/              \\\\",
    "/                \\\\",
    "/                  \\\\",
    "|                  |",
    "|                  |",
    "|                  |",
    "|                  |",
    "|                  |",
    "|                  |",
    "*|     *  *  *      | *",
    "________)/\\\\\\\\_//(\\\\/(/\\\\)/\\\\//\\\\/|_)_______",
  }
  local os1
  local os2
  os1 = { [0] = "", mesg[168], mesg[169], mesg[170], mesg[171] }
  os2 = { [0] = "", mesg[172], mesg[173], mesg[174], mesg[175] }

  if other ~= g.QUIT then
    g.rogue.gold = util.int_div((g.rogue.gold * 9), 10)
  end
  local buf, buf2
  if other ~= 0 then
    buf = os1[other]
    buf2 = os2[other]
  else
    if mesg.JAPAN then
      buf = monster.m_name
      buf2 = mesg[176]
    else
      buf = mesg[176]
      buf2 = monster.m_name
      if mesg.English and is_vowel(buf2) then
        -- "an" of vowel
        buf = buf .. "n"
      end
    end
  end
  if g.show_skull and other ~= g.QUIT then
    g.clear()
    local inscribed_words
    if mesg.JAPAN then
      inscribed_words = {
        [4] = "(y(" .. mesg[177] .. "(y(",
        [5] = "(y(" .. mesg[178] .. "(y(",
        [7] = g.nick_name,
        [8] = mesg[180] .. g.znum(g.rogue.gold),
        [10] = buf,
        [11] = buf2,
        [12] = g.znum(tonumber(os.date("%Y"))),
      }
    else
      inscribed_words = {
        [4] = "(y(" .. mesg[177] .. "(y(",
        [5] = "(y(" .. mesg[178] .. "(y(",
        [6] = "(y(" .. mesg[179] .. "(y(",
        [8] = g.nick_name,
        [9] = string.format(mesg[180]:gsub("%%ld", "%%d"), g.rogue.gold),
        [10] = buf,
        [11] = buf2,
        [12] = os.date("%Y"),
      }
    end
    for i = 1, #str do
      tomb_str(str, xpos, i, inscribed_words[i])
      g.mvaddstr(i + 3 - 1, xpos[i], str[i])
    end

    g.check_message()
    g.message("")
  else
    if mesg.JAPAN then
      buf = buf .. buf2
      buf = buf .. mesg[181]
      buf = buf .. g.znum(g.rogue.gold)
      buf = buf .. mesg[496]
    else
      if buf2 ~= "" then
        buf = buf .. " " .. buf2
      end
      buf = buf .. string.format(mesg[181]:gsub("%%ld", "%%d"), g.rogue.gold)
    end
    g.message(buf)
  end
  g.message("")
  g.put_scores(monster, other)
end

local function mvaddbanner(row, col, ban)
  ban = ban:gsub("(#+)", "(G(%1(G(")
  g.mvaddstr(row, col, ban)
end

local function id_all()
  for i = 0, g.SCROLS - 1 do
    g.id_scrolls[i].id_status = g.IDENTIFIED
  end
  for i = 0, g.WEAPONS - 1 do
    g.id_weapons[i].id_status = g.IDENTIFIED
  end
  for i = 0, g.ARMORS - 1 do
    g.id_armors[i].id_status = g.IDENTIFIED
  end
  for i = 0, g.WANDS - 1 do
    g.id_wands[i].id_status = g.IDENTIFIED
  end
  for i = 0, g.POTIONS - 1 do
    g.id_potions[i].id_status = g.IDENTIFIED
  end
end

local function get_value(obj)
  local wc = obj.which_kind
  local what_is = obj.what_is
  local val
  if what_is == g.WEAPON then
    val = g.id_weapons[wc].value
    if (wc == g.ARROW) or (wc == g.DAGGER) or (wc == g.SHURIKEN) or (wc == g.DART) then
      val = val * obj.quantity
    end
    val = val + (obj.d_enchant * 85) + (obj.hit_enchant * 85)
  elseif what_is == g.ARMOR then
    val = g.id_armors[wc].value + (obj.d_enchant * 75)
    if obj.is_protected then
      val = val + 200
    end
  elseif what_is == g.WAND then
    val = g.id_wands[wc].value * (obj.class + 1)
  elseif what_is == g.SCROL then
    val = g.id_scrolls[wc].value * obj.quantity
  elseif what_is == g.POTION then
    val = g.id_potions[wc].value * obj.quantity
  elseif what_is == g.AMULET then
    val = 5000
  elseif what_is == g.RING then
    val = g.id_rings[wc].value * (obj.class + 1)
  end
  if val <= 0 then
    val = 10
  end
  return val
end

local function sell_pack()
  local row = 2
  local obj = g.rogue.pack.next_object
  g.clear()
  g.mvaddstr(1, 0, mesg[198])

  while obj do
    if obj.what_is ~= g.FOOD then
      obj.identified = true
      local val = get_value(obj)
      g.rogue.gold = g.rogue.gold + val

      if row < g.DROWS then
        g.mvaddstr(row, 0, string.format("%5d      %s", val, g.get_desc(obj, true)))
        row = row + 1
      end
    end
    obj = obj.next_object
  end
  g.refresh()
  if g.rogue.gold > g.MAX_GOLD then
    g.rogue.gold = g.MAX_GOLD
  end
  g.message("")
end

function g.win()
  g.unwield(g.rogue.weapon) -- disarm and relax
  g.unwear(g.rogue.armor)
  g.un_put_on(g.rogue.left_ring)
  g.un_put_on(g.rogue.right_ring)

  g.clear()
  local ban = {
    "#   #               #   #           #          ###  #     #     ",
    "#   #               ## ##           #           #   #     #     ",
    "#   #  ###  #   #   # # #  ###   ####  ###      #  ###    #     ",
    " #### #   # #   #   #   #     # #   # #   #     #   #     #     ",
    "    # #   # #   #   #   #  #### #   # #####     #   #     #     ",
    "#   # #   # #  ##   #   # #   # #   # #         #   #  #        ",
    " ###   ###   ## #   #   #  ####  ####  ###     ###   ##   #     ",
  }
  for i = 1, 7 do
    mvaddbanner(i + 5, g.DCOLS / 2 - 30, ban[i])
  end
  center(15, "(y(" .. mesg[182] .. "(y(")
  center(16, "(y(" .. mesg[183] .. "(y(")
  center(17, "(y(" .. mesg[184] .. "(y(")
  center(18, "(y(" .. mesg[185] .. "(y(")

  g.message("")
  g.message("")
  id_all()
  sell_pack()
  g.put_scores(nil, g.WIN)
end

function g.quit(from_intrpt)
  g.check_message()
  g.message(mesg[495], true)
  if g.rgetchar() ~= "y" then
    g.check_message()
    return
  end
  g.check_message()
  if from_intrpt then
    g.message(mesg[12], true)
  end
  g.killed_by(nil, g.QUIT)
  -- NOTREACHED
end

local function sf_error()
  g.message("", true)
  g.message(mesg[199])
end

local function score_line(monster, other)
  local buf = string.format("   %6d   %s: ", g.rogue.gold, g.nick_name)
  if mesg.JAPAN then
    if other ~= g.WIN then
      if g.has_amulet() then
        buf = buf .. mesg[189]
      end
      buf = buf .. mesg[190] .. g.znum(g.cur_level) .. mesg[191]
    end
  end
  if monster then
    if mesg.JAPAN then
      buf = buf .. monster.m_name .. mesg[197]
    else
      buf = buf .. mesg[197]
      if is_vowel(monster.m_name) then
        buf = buf .. "an " .. monster.m_name
      else
        buf = buf .. "a " .. monster.m_name
      end
    end
  elseif other == g.HYPOTHERMIA then
    buf = buf .. mesg[192]
  elseif other == g.STARVATION then
    buf = buf .. mesg[193]
  elseif other == g.POISON_DART then
    buf = buf .. mesg[194]
  elseif other == g.QUIT then
    buf = buf .. mesg[195]
  elseif other == g.WIN then
    buf = buf .. mesg[196]
  end
  if mesg.JAPAN then
    buf = buf .. mesg[496]
  else
    buf = buf .. string.format(mesg[190], g.cur_level)
    if other ~= g.WIN and g.has_amulet() then
      buf = buf .. mesg[189]
    end
  end
  buf = buf .. string.rep(" ", g.DCOLS - 4 - util.strwidth(buf))
  return buf
end

function g.put_scores(monster, other)
  local scores = {}
  local file = g.game_dir .. score_file
  local fp = io.open(file, "rb")
  if fp then
    local buf = fp:read("*a")
    g.xxx(true)
    buf = g.xxxx(buf)
    vim.cmd('let &encoding = "utf-8"')
    buf = g.iconv_from_utf8(buf)
    vim.cmd("let &encoding = s:save_encoding")
    scores = assert(util.loadstring("return " .. buf), mesg[199])()
    fp:close()
  end

  local MAX_RANK = 10
  local rank = #scores + 1
  if g.score_only then
    rank = MAX_RANK + 1
  else
    for i = 1, #scores do
      if g.rogue.gold > scores[i].score then
        rank = i
        break
      end
    end
  end

  if rank <= MAX_RANK then
    fp = io.open(file, "wb")
    if not fp then
      g.message(mesg[186])
      sf_error()
      g.exit()
    end
    table.insert(scores, rank, { score = g.rogue.gold, line = score_line(monster, other) })
    if #scores > MAX_RANK then
      table.remove(scores)
    end
    local buf = util.dump(scores)
    buf = g.iconv_to_utf8(buf)
    g.xxx(true)
    buf = g.xxxx(buf)
    fp:write(buf)
    fp:close()
  end

  g.clear()
  g.mvaddstr(3, (mesg.JAPAN and 20 or 25), "(y(" .. mesg[187] .. "(y(")
  g.mvaddstr(6, 0, "(g(" .. mesg[188] .. "(g(")

  for i = 1, #scores do
    local c = ""
    if rank == i then
      c = "(C("
    end
    g.mvaddstr(i + 7, 0, c .. string.format(" %2d", i) .. scores[i].line .. c)
  end
  g.refresh()
  g.message("")
  g.exit()
end

function g.xxxx(buf)
  local ret = ""
  for i = 1, #buf do
    local c = g.xxx(false)
    local x = util.bxor(buf:byte(i), c)
    x = x % 0x100
    ret = ret .. string.char(x)
  end
  return ret
end

function g.xxx(st)
  if st then
    xxx_f = 37
    xxx_s = 7
    return 0
  end
  local r = ((xxx_f * xxx_s) + 9337) % 8887
  xxx_f = xxx_s
  xxx_s = r
  return r
end
