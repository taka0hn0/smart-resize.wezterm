
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

## ✨ Features

- **Smart Auto-Scaling**: Automatically calculates an optimal window size (80% width, 85% height) and centers it on your screen upon initial launch or when connecting to a new monitor.
- **Multi-Monitor Awareness**: Detects monitor changes or resolution adjustments in real-time and automatically restores the saved dimensions for that specific display.
- **Flicker-Free Startup**: By caching your exact column and row counts, WezTerm opens instantly at the correct size, bypassing the usual "small-to-large" window animation.
- **Zero-Config Persistence**: Once you manually resize a window and save it, the plugin handles everything. It even auto-caches its initial calculations so you don't have to.

## 🚀 Installation

Add the following to your `wezterm.lua`:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 1. Import the plugin (Note: .git#main is recommended for stable auto-clone)
local smart_resize = wezterm.plugin.require("[https://github.com/taka0hn0/smart-resize.wezterm.git#main](https://github.com/taka0hn0/smart-resize.wezterm.git#main)")

-- 2. Apply it to your config
smart_resize.apply_to_config(config)

-- 3. Setup startup and monitor-change hooks
smart_resize.setup_startup_hook()

return config

```

## 💻 OS Compatibility

This plugin is designed to work across all major operating systems:

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

You can override the default keybinding in the `apply_to_config` options:

```lua
smart_resize.apply_to_config(config, {
  key = 'S',
  mods = 'ALT|SHIFT' -- Change your mods here
})
```

### Real-time Monitor Detection

The plugin automatically hooks into `window-config-reloaded`. When you plug in an external monitor or change your resolution, the plugin will:

1. Identify the new screen resolution.
2. Search the cache for a matching size.
3. Automatically resize and center the window if a record is found.

## 🧹 Resetting the Cache

To reset your saved window sizes, delete the hidden cache file in your configuration directory:

* **macOS/Linux**: `rm ~/.config/wezterm/.wezterm_size_cache`
* **Windows (PowerShell)**: `Remove-Item "$env:APPDATA\wezterm\.wezterm_size_cache"`

For convenience, it is highly recommended to add the following alias to your shell configuration (`.zshrc`, `.bashrc`, or `fish` config):

**macOS / Linux:**
```bash
# Add this to your ~/.zshrc or ~/.bashrc
alias wez-reset="rm -f ~/.config/wezterm/.wezterm_size_cache && echo 'Deleted WezTerm window size cache!'"
Windows (PowerShell Profile):
```
**Windows (PowerShell)**
```powershell
function wez-reset { 
    Remove-Item "$env:APPDATA\wezterm\.wezterm_size_cache" -ErrorAction SilentlyContinue
    Write-Host "Deleted WezTerm window size cache!" -ForegroundColor Green 
}
```
After adding this, you can simply type 
```bash
wez-reset
```
in your terminal to clear all saved monitor dimensions.

