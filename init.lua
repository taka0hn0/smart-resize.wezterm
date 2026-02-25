local wezterm = require 'wezterm'
local module = {}

-- ==== Cache window size and monitor resolution ====
local cache_file = wezterm.config_dir .. "/.wezterm_size_cache"

local function load_size_cache()
  local file = io.open(cache_file, "r")
  if file then
    local content = file:read("*a")
    file:close()
    -- Match 4 numbers: cols, rows, screen_width, screen_height
    local cols, rows, scr_w, scr_h = content:match("(%d+),(%d+),(%d+),(%d+)")
    if cols and rows and scr_w and scr_h then
      return tonumber(cols), tonumber(rows), tonumber(scr_w), tonumber(scr_h)
    end
  end
  return nil, nil, nil, nil
end

-- ==== Apply configurations and keybindings ====
function module.apply_to_config(config, opts)
  -- Allow users to override the default shortcut key
  opts = opts or {}
  local shortcut_key = opts.key or 'S'
  local shortcut_mods = opts.mods or 'CMD|SHIFT'

  local cached_cols, cached_rows, _, _ = load_size_cache()

  -- Use cached size if available, otherwise fallback to reasonable default
  config.initial_cols = cached_cols or 150
  config.initial_rows = cached_rows or 55

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

      local file = io.open(cache_file, "w")
      if file then
        file:write(dims.cols .. "," .. dims.viewport_rows .. "," .. math.floor(screen.width) .. "," .. math.floor(screen.height))
        file:close()
        window:toast_notification("WezTerm", "Saved current window size as default!", nil, 4000)
      end
    end),
  })
end

-- ==== Calculate window size on startup ====
wezterm.on('gui-startup', function(cmd)
  local mux = wezterm.mux
  local tab, pane, window = mux.spawn_window(cmd or {})
  local gui_window = window:gui_window()
  local screen = wezterm.gui.screens().active
  if not screen then return end

  local _, _, cached_scr_w, cached_scr_h = load_size_cache()

  -- If the current monitor matches the cached monitor, skip resizing to prevent flicker
  if cached_scr_w == math.floor(screen.width) and cached_scr_h == math.floor(screen.height) then
    return
  end

  -- If monitor changed or no cache exists, calculate 80% of the new screen
  local target_width = math.floor(screen.width * 0.8)
  local target_height = math.floor(screen.height * 0.85)

  gui_window:set_inner_size(target_width, target_height)

  local center_x = math.floor(screen.x + (screen.width - target_width) / 2)
  local center_y = math.floor(screen.y + (screen.height - target_height) / 2)
  
  gui_window:set_position(center_x, center_y)

  -- Save window size after 0.5 s and make it a default
  wezterm.time.call_after(0.5, function()
    local dims = pane:get_dimensions()
    local file = io.open(cache_file, "w")
    if file then
      file:write(dims.cols .. "," .. dims.viewport_rows .. "," .. math.floor(screen.width) .. "," .. math.floor(screen.height))
      file:close()
    end
  end)
end)

return module
