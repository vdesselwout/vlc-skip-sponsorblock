-- skip_sponsorblock.lua — VLC 3.x Lua interface script (debug build)
-- Auto-skips chapters whose title starts with "[SponsorBlock]:",
-- but only the FIRST time each one is reached per file. If you go back
-- into a skipped chapter, it plays normally.

local PATTERN  = "^%[SponsorBlock%]:"
local POLL_US  = 250000          -- check 4x per second
local DEBUG    = false            -- set to false once it works

local skipped     = {}           -- chapter index -> true (already skipped once)
local current_uri = nil
local last_ch     = nil

local function log(m)  vlc.msg.warn("[skip_sponsorblock] " .. m) end
local function dbg(m)  if DEBUG then log(m) end end

local function chapter_list(input)
  local ok, vals, texts = pcall(vlc.var.get_list, input, "chapter")
  if not ok then
    dbg("get_list failed: " .. tostring(vals))
    return nil, nil
  end
  return vals, texts
end

local function tick()
  local input = vlc.object.input()
  if not input then return end

  local item = vlc.input.item()
  local uri  = item and item:uri()
  if uri ~= current_uri then          -- new file: forget what we skipped
    current_uri = uri
    skipped, last_ch = {}, nil
    dbg("new file: " .. tostring(uri))
    local vals, texts = chapter_list(input)
    if vals then
      dbg("file has " .. #vals .. " chapter(s)")
      for i, v in ipairs(vals) do
        dbg("  chapter " .. tostring(v) .. " = " .. tostring(texts and texts[i]))
      end
    end
  end

  local ok, ch = pcall(vlc.var.get, input, "chapter")
  if not ok or type(ch) ~= "number" or ch < 0 then return end

  if ch ~= last_ch then
    last_ch = ch
    local vals, texts = chapter_list(input)
    local title, count
    if vals then
      count = #vals
      for i, v in ipairs(vals) do
        if v == ch then title = texts and texts[i] end
      end
    end
    dbg("now in chapter " .. ch .. ": " .. tostring(title))

    if title and title:find(PATTERN) and not skipped[ch] then
      skipped[ch] = true
      log("skipping chapter " .. ch .. ": " .. title)
      vlc.osd.message("Skipped: " .. title)
      if count and ch + 1 < count then
        vlc.var.set(input, "chapter", ch + 1)
      else
        -- final chapter: nothing to skip to, so just pause
        if vlc.playlist.status() == "playing" then vlc.playlist.pause() end
      end
    end
  end
end

log("loaded")

-- VLC 3 has no vlc.misc.should_die(); it stops the script by cancelling
-- it during mwait(), so a plain endless loop is the right shape here.
local should_die = vlc.misc.should_die or function() return false end

while not should_die() do
  local ok, err = pcall(tick)
  if not ok then log("error: " .. tostring(err)) end
  vlc.misc.mwait(vlc.misc.mdate() + POLL_US)
end
