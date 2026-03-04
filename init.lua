local wezterm = require 'wezterm'
local module = {}

-- Helper to detect OS
local function get_os()
  if wezterm.target_triple:find("apple") then
    return "mac"
  elseif wezterm.target_triple:find("windows") then
    return "windows"
  else
    return "linux"
  end
end

local os_type = get_os()
local is_windows = os_type == "windows"
local is_mac = os_type == "mac"

-- Set path separator and cache file path
local path_sep = is_windows and "\\" or "/"
local cache_file = wezterm.config_dir .. path_sep .. ".wezterm_size_cache"

-- Function to load window size cache
local function load_size_cache()
  local cache = {}
  local file = io.open(cache_file, "r")
  if file then
    for line in file:lines() do
      -- Match 6 numbers: scr_w, scr_h, cols, rows, px_w, px_h
      local sw, sh, c, r, pw, ph = line:match("(%d+),(%d+),(%d+),(%d+),(%d+),(%d+)")
      if sw and sh and c and r and pw and ph then
        table.insert(cache, {
          scr_w = tonumber(sw), scr_h = tonumber(sh),
          cols = tonumber(c), rows = tonumber(r),
          px_w = tonumber(pw), px_h = tonumber(ph)
        })
      else
        -- Fallback for old cache format (4 numbers)
        local o_sw, o_sh, o_c, o_r = line:match("(%d+),(%d+),(%d+),(%d+)")
        if o_sw then
           table.insert(cache, {
              scr_w = tonumber(o_sw), scr_h = tonumber(o_sh),
              cols = tonumber(o_c), rows = tonumber(o_r)
           })
        end
      end
    end
    file:close()
  end
  return cache
end

-- Function to save / update window size cache
local function save_size_cache(scr_w, scr_h, cols, rows, px_w, px_h)
  local cache = load_size_cache()
  local new_cache = {}

  -- 1. Add new monitor info at the top
  table.insert(new_cache, {
    scr_w = scr_w, scr_h = scr_h, cols = cols, rows = rows, px_w = px_w, px_h = px_h
  })

  -- 2. Copy existing cache except for the newly added monitor
  for _, entry in ipairs(cache) do
    if not (entry.scr_w == scr_w and entry.scr_h == scr_h) then
      table.insert(new_cache, entry)
    end
    -- Keep maximum of five monitors in cache
    if #new_cache >= 5 then break end
  end

  -- 3. Write back to file
  local file = io.open(cache_file, "w")
  if file then
    for _, entry in ipairs(new_cache) do
      file:write(string.format("%d,%d,%d,%d,%d,%d\n",
        entry.scr_w, entry.scr_h, entry.cols, entry.rows, entry.px_w or 0, entry.px_h or 0))
    end
    file:close()
  end
end

-- ==== Apply configurations and keybindings ====
function module.apply_to_config(config, opts)
  -- Allow users to override the default shortcut key
  opts = opts or {}
  local shortcut_key = opts.key or 'S'
  local default_mods = is_mac and 'CMD|SHIFT' or 'CTRL|SHIFT'
  local shortcut_mods = opts.mods or default_mods

  local size_cache = load_size_cache()
  -- Get the top value as a default (most recently used monitor)
  local primary_cache = size_cache[1] or {}

  -- Use cached size if available, otherwise fallback to reasonable default
  config.initial_cols = primary_cache.cols or 150
  config.initial_rows = primary_cache.rows or 55

  -- Initialize keys table if it doesn't exist
  if not config.keys then
    config.keys = {}
  end

  -- Add the shortcut to save the window size
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
      window:toast_notification("WezTerm", "Saved current window size for this monitor!", nil, 4000)
    end),
  })
end

-- ==== Setup window size calculation on startup ====
-- Expose this as a function so users can call it safely from their wezterm.lua
function module.setup_startup_hook()
  wezterm.on('gui-startup', function(cmd)
    -- Add a slight delay to ensure GUI components are fully loaded
    wezterm.time.call_after(0.1, function()
      local mux = wezterm.mux
      
      -- Prevent multiple windows from spawning if already active
      if #mux.all_windows() > 0 then return end
      
      local tab, pane, window = mux.spawn_window(cmd or {})
      local gui_window = window:gui_window()
      local screen = wezterm.gui.screens().active
      if not screen then return end

      local cur_w = math.floor(screen.width)
      local cur_h = math.floor(screen.height)

      local size_cache = load_size_cache()
      local primary_cache = size_cache[1] or {}

      -- Check if the current monitor exists in the cache
      local matched_cache = nil
      for _, entry in ipairs(size_cache) do
        if entry.scr_w == cur_w and entry.scr_h == cur_h then
          matched_cache = entry
          break
        end
      end

      if matched_cache then
        if primary_cache.scr_w == cur_w and primary_cache.scr_h == cur_h then
          -- If using the most recent monitor, skip resizing to prevent flicker
          return
        else
          -- If using a different monitor used before, restore the pixel size for the display
          if matched_cache.px_w and matched_cache.px_w > 0 then
             gui_window:set_inner_size(matched_cache.px_w, matched_cache.px_h)
             local center_x = math.floor(screen.x + (screen.width - matched_cache.px_w) / 2)
             local center_y = math.floor(screen.y + (screen.height - matched_cache.px_h) / 2)
             gui_window:set_position(center_x, center_y)
          end

          -- Make this monitor the most recent one
          wezterm.time.call_after(0.5, function()
            local dims = pane:get_dimensions()
            save_size_cache(cur_w, cur_h, dims.cols, dims.viewport_rows, dims.pixel_width, dims.pixel_height)
          end)
        end
        return
      end

      -- If monitor changed or no cache exists, calculate 80% of the new screen size
      local target_width = math.floor(screen.width * 0.8)
      local target_height = math.floor(screen.height * 0.85)

      gui_window:set_inner_size(target_width, target_height)

      local center_x = math.floor(screen.x + (screen.width - target_width) / 2)
      local center_y = math.floor(screen.y + (screen.height - target_height) / 2)
      
      gui_window:set_position(center_x, center_y)

      -- Save window size after 0.5 seconds and make it the default
      wezterm.time.call_after(0.5, function()
        local dims = pane:get_dimensions()
        save_size_cache(cur_w, cur_h, dims.cols, dims.viewport_rows, dims.pixel_width, dims.pixel_height)
      end)
    end)
  end)
end

return module
