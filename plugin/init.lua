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

-- State management
local last_screen_info = {}
local is_manual_override = {} -- Track if user manually resized the window

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

-- Core resizing logic
local function resize_window_for_monitor(window, pane)
  local screen = wezterm.gui.screens().active
  if not screen then return end

  local cur_w = math.floor(screen.width)
  local cur_h = math.floor(screen.height)
  local window_id = tostring(window:window_id())

  -- Update screen info tracking
  last_screen_info[window_id] = string.format("%d%d%d%d", 
    math.floor(screen.x), math.floor(screen.y), cur_w, cur_h)

  local size_cache = load_size_cache()
  local matched_cache = nil
  for _, entry in ipairs(size_cache) do
    if entry.scr_w == cur_w and entry.scr_h == cur_h then
      matched_cache = entry
      break
    end
  end

  if matched_cache and matched_cache.px_w and matched_cache.px_w > 0 then
    window:set_inner_size(matched_cache.px_w, matched_cache.px_h)
    local center_x = math.floor(screen.x + (screen.width - matched_cache.px_w) / 2)
    local center_y = math.floor(screen.y + (screen.height - matched_cache.px_h) / 2)
    wezterm.time.call_after(0.05, function() window:set_position(center_x, center_y) end)
  else
    local target_width = math.floor(screen.width * 0.8)
    local target_height = math.floor(screen.height * 0.85)
    window:set_inner_size(target_width, target_height)
    local center_x = math.floor(screen.x + (screen.width - target_width) / 2)
    local center_y = math.floor(screen.y + (screen.height - target_height) / 2)
    wezterm.time.call_after(0.05, function() window:set_position(center_x, center_y) end)
    
    wezterm.time.call_after(0.5, function()
      local dims = pane:get_dimensions()
      save_size_cache(cur_w, cur_h, dims.cols, dims.viewport_rows, dims.pixel_width, dims.pixel_height)
    end)
  end
end

function module.apply_to_config(config, opts)
  opts = opts or {}
  local shortcut_key = opts.key or 'S'
  local default_mods = is_mac and 'CMD|SHIFT' or 'CTRL|SHIFT'
  local shortcut_mods = opts.mods or default_mods

  local size_cache = load_size_cache()
  local primary_cache = size_cache[1]
  if primary_cache then
    config.initial_cols = primary_cache.cols
    config.initial_rows = primary_cache.rows
  end

  if not config.keys then config.keys = {} end
  table.insert(config.keys, {
    key = shortcut_key,
    mods = shortcut_mods,
    action = wezterm.action_callback(function(window, pane)
      local dims = pane:get_dimensions()
      local screen = wezterm.gui.screens().active
      if not screen then return end
      
      save_size_cache(
        math.floor(screen.width), math.floor(screen.height),
        dims.cols, dims.viewport_rows,
        dims.pixel_width, dims.pixel_height
      )
      window:toast_notification("WezTerm", "Saved size for this monitor!", nil, 4000)
    end),
  })
end

function module.setup_startup_hook()
  -- 1. Initial startup
  wezterm.on('gui-startup', function(cmd)
    wezterm.time.call_after(0.1, function()
      local mux = wezterm.mux
      if #mux.all_windows() > 0 then return end
      local _, pane, window = mux.spawn_window(cmd or {})
      resize_window_for_monitor(window:gui_window(), pane)
    end)
  end)

  -- 2. Detect manual resize
  wezterm.on('window-resized', function(window, pane)
    local window_id = tostring(window:window_id())
    -- Mark as manually overridden
    is_manual_override[window_id] = true
  end)

  -- 3. Monitor or resolution change
  wezterm.on('window-config-reloaded', function(window, pane)
    wezterm.time.call_after(0.1, function()
      local screen = wezterm.gui.screens().active
      if not screen then return end

      local window_id = tostring(window:window_id())
      local screen_id = string.format("%d%d%d%d", 
        math.floor(screen.x), math.floor(screen.y), 
        math.floor(screen.width), math.floor(screen.height))

      -- If monitor changed, reset override and resize
      if last_screen_info[window_id] ~= screen_id then
        is_manual_override[window_id] = false
        resize_window_for_monitor(window, pane)
      else
        -- If same monitor, only resize if NOT manually overridden
        if not is_manual_override[window_id] then
          resize_window_for_monitor(window, pane)
        end
      end
    end)
  end)
end

return module
