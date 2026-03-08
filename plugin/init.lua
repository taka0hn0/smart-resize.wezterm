local wezterm = require 'wezterm'
local module = {}

-- Helper to detect OS
local function get_os()
  if wezterm.target_triple:find("apple") then return "mac"
  elseif wezterm.target_triple:find("windows") then return "windows"
  else return "linux" end
end

local os_type = get_os()
local is_windows = os_type == "windows"
local is_mac = os_type == "mac"
local path_sep = is_windows and "\\" or "/"
local cache_file = wezterm.config_dir .. path_sep .. ".wezterm_size_cache"

-- Load size cache
local function load_size_cache()
  local cache = {}
  local file = io.open(cache_file, "r")
  if file then
    for line in file:lines() do
      local sw, sh, c, r, pw, ph = line:match("(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)")
      if sw and sh and c and r and pw and ph then
        table.insert(cache, {
          scr_w = tonumber(sw), scr_h = tonumber(sh),
          cols = tonumber(c), rows = tonumber(r),
          px_w = tonumber(pw), px_h = tonumber(ph)
        })
      end
    end
    file:close()
  end
  return cache
end

-- Save size cache
local function save_size_cache(scr_w, scr_h, cols, rows, px_w, px_h)
  local cache = load_size_cache()
  local new_cache = {}
  table.insert(new_cache, {
    scr_w = scr_w, scr_h = scr_h, cols = cols, rows = rows, px_w = px_w, px_h = px_h
  })
  for _, entry in ipairs(cache) do
    if not (entry.scr_w == scr_w and entry.scr_h == scr_h) then
      table.insert(new_cache, entry)
    end
    if #new_cache >= 5 then break end
  end
  local file = io.open(cache_file, "w")
  if file then
    for _, entry in ipairs(new_cache) do
      file:write(string.format("%d,%d,%d,%d,%d,%d\n",
        entry.scr_w, entry.scr_h, entry.cols, entry.rows, entry.px_w or 0, entry.px_h or 0))
    end
    file:close()
  end
end

function module.apply_to_config(config, opts)
  opts = opts or {}
  local save_key = opts.save_key or 'S'
  local default_mods = is_mac and 'CMD|SHIFT' or 'CTRL|SHIFT'
  local mods = opts.mods or default_mods

  -- Apply initial rows/cols from cache if available.
  -- This sets the window size BEFORE it is rendered by the OS.
  local size_cache = load_size_cache()
  local primary_cache = size_cache[1]
  if primary_cache then
    config.initial_cols = primary_cache.cols
    config.initial_rows = primary_cache.rows
  end

  if not config.keys then config.keys = {} end

  -- Keybind: Save current window size to cache (CMD+SHIFT+S)
  table.insert(config.keys, {
    key = save_key,
    mods = mods,
    action = wezterm.action_callback(function(window, pane)
      local dims = pane:get_dimensions()
      local screen = wezterm.gui.screens().active
      if screen then
        save_size_cache(
          math.floor(screen.width), math.floor(screen.height),
          dims.cols, dims.viewport_rows,
          dims.pixel_width, dims.pixel_height
        )
        window:toast_notification("WezTerm", "Window size saved! It will be used next time.", nil, 3000)
      end
    end),
  })
end

function module.setup_startup_hook()
  -- No startup hooks needed as we only rely on initial_cols/rows 
  -- in the config to avoid any visual artifacts or jumps.
end

return module
