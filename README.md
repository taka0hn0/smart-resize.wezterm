<div align="center">
  <h1>🧠</h1>
  <h1>smart-resize.wezterm</h1>
  <p>
    <strong>A smart, lightweight window resizing plugin for WezTerm.</strong>
  </p>
  <img src="https://img.shields.io/badge/WezTerm-Plugin-blue?style=for-the-badge&logo=wezterm">
  <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge">
</div>

<br>

# Smart-resize.wezterm

A lightweight WezTerm plugin that intelligently manages your terminal window size across different monitors. It automatically calculates the optimal dimensions based on your current screen resolution and remembers your preferred size for each display, completely eliminating jarring startup flickering.

## 🧐 Why this plugin?

By default, WezTerm calculates window size based on `initial_cols` and `initial_rows`. <br><br>However, with this approach, if you connect to a different monitor or change the display resolution settings, the window’s screen occupancy will no longer remain consistent, and you will need to reconfigure it.
<br><br>**Smart-resize.wezterm** solves this by:
1. **Predicting** the correct dimensions before the window is fully rendered.
2. **Restoring** the exact pixel size cached from your previous session.
3. **Adapting** instantly when you plug in or unplug external monitors.

## ✨ Features

- **Smart Auto-Scaling**: Automatically calculates an optimal window size (80% width, 85% height) and centers it on your screen upon initial launch.
- **Multi-Monitor Awareness**: Detects monitor changes or resolution adjustments in real-time and automatically restores the saved dimensions for that specific display.
- **Flicker-Free Startup**: By caching your exact pixel dimensions, WezTerm opens instantly at the correct size.
- **Manual Resize Protection**: If you manually resize the window, the plugin respects your choice and disables auto-resizing until you restart WezTerm or change monitors.

## 🚀 Installation

Add the following to your `wezterm.lua`:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 1. Import the plugin (Note: .git#main ensures you get the latest stable version)
local smart_resize = wezterm.plugin.require("[https://github.com/taka0hn0/smart-resize.wezterm.git#main](https://github.com/taka0hn0/smart-resize.wezterm.git#main)")

-- 2. Apply it to your config
smart_resize.apply_to_config(config)

-- 3. Setup startup and monitor-change hooks
smart_resize.setup_startup_hook()

return config

```

## 💻 OS Compatibility

| OS | Default Shortcut | Cache Location |
| --- | --- | --- |
| **macOS** | `Cmd + Shift + S` | `~/.config/wezterm/.wezterm_size_cache` |
| **Linux** | `Ctrl + Shift + S` | `~/.config/wezterm/.wezterm_size_cache` |
| **Windows** | `Ctrl + Shift + S` | `%APPDATA%\wezterm\.wezterm_size_cache` |

> [!IMPORTANT]
> **Linux Users:** If you are using a **Tiling Window Manager** (like Hyprland, Sway, or i3), your WM may override the plugin's attempts to resize or center the window.

## ⌨️ Usage & Configuration

### Saving Your Size

1. Manually resize your WezTerm window to your liking.
2. Press the shortcut:
* **macOS**: `Cmd + Shift + S`
* **Windows/Linux**: `Ctrl + Shift + S`


3. A toast notification will confirm that your preferences have been saved for the current monitor.

### Customizing the Shortcut

```lua
smart_resize.apply_to_config(config, {
  key = 'S',
  mods = 'ALT|SHIFT'
})
```

### Manual Override Mode

The plugin is "smart" enough to respect your manual adjustments. If you drag the window edges to resize it manually, the plugin will **disable auto-resizing** for that specific window until:

* You restart WezTerm.
* You move the window to a different monitor or change resolution.

## 🧹 Resetting the Cache

To reset your saved window sizes and return to the default auto-calculated dimensions, delete the hidden cache file.

**Recommended Alias:**
Add this to your shell configuration (`.zshrc`, `.bashrc`, etc.):

**🍎macOS / 🐧Linux**
```bash
alias wez-reset="rm -f ~/.config/wezterm/.wezterm_size_cache && echo 'Deleted WezTerm window size cache!'"
```

**🪟Windows (PowerShell Profile)**
```powershell
function wez-reset { 
    Remove-Item "$env:APPDATA\wezterm\.wezterm_size_cache" -ErrorAction SilentlyContinue
    Write-Host "Deleted WezTerm window size cache!" -ForegroundColor Green 
}
```

After setting this up, you can just type
```bash
wez-reset
```
to clear the cache.

## 🛠️ Troubleshooting

### Plugin not updating?

WezTerm caches plugins for performance. To force an update to the latest version, clear the plugin download folder:

* **macOS**: `rm -rf "$HOME/Library/Application Support/wezterm/plugins/"*`
* **Linux**: `rm -rf "$HOME/.local/share/wezterm/plugins/"*`

## 📄 License

This project is licensed under the MIT License.

