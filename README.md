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

A lightweight WezTerm plugin that intelligently manages your terminal window size. It automatically resizes the window based on your monitor's resolution and allows you to manually save your preferred dimensions without causing startup flickering.

## ✨ Features

- **Smart Auto-Scaling**: Automatically calculates the optimal window size (80% width, 85% height) and centers it on your screen upon initial launch or when connecting to a new monitor. No more hardcoding initial rows and columns in your wezterm.lua!
- **Flicker-Free Startup:** By caching your exact column and row counts, subsequent WezTerm sessions open instantly at the correct size, completely eliminating jarring resizing animations.
- **Save Your Preference:** Manually adjust the window size, hit a customizable shortcut, and set it as your new permanent default.

## 🚀 Installation

Add the following to your `wezterm.lua`:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 1. Import the plugin
local smart_resize = wezterm.plugin.require("https://github.com/taka0hn0/wez-smart-resize")

-- 2. Apply it to your config
smart_resize.apply_to_config(config)

return config
```

## 💻 OS Compatibility

This plugin is designed to work across all major operating systems:

| OS | Default Shortcut | Cache Location |
| :--- | :--- | :--- |
| **macOS** | `Cmd + Shift + S` | `~/.config/wezterm/.wezterm_size_cache` |
| **Linux** | `Ctrl + Shift + S` | `~/.config/wezterm/.wezterm_size_cache` |
| **Windows** | `Ctrl + Shift + S` | `%APPDATA%\wezterm\.wezterm_size_cache` |

> [!NOTE]
> **Linux Users:** If you are using a **Tiling Window Manager** (like i3, Sway, or Hyprland), your window manager may override the plugin's attempts to resize or center the window.

## ⌨️ Usage & Configuration

By default, the plugin registers a shortcut to save your current window size:
- **macOS**: `Cmd + Shift + S`
- **Windows/Linux**: `Ctrl + Shift + S`


A toast notification will appear confirming the new default.

### Customizing the Shortcut

If you prefer a different keybinding, you can pass an options table:

```lua
smart_resize.apply_to_config(config, {
  key = 'S',
  mods = 'ALT|SHIFT'
})
```

## 🧹 Resetting the Cache

If you want to reset your saved window size and return to the default auto-calculated dimensions, you simply need to delete the hidden cache file `.wezterm_size_cache` located in your WezTerm configuration directory:

- **macOS/Linux**: `~/.config/wezterm/.wezterm_size_cache`
- **Windows**: `%APPDATA%\wezterm\.wezterm_size_cache` (or wherever your `wezterm.lua` is located)

It is highly recommended to add an alias to your shell configuration:

**macOS/Linux (`.zshrc` or `.bashrc`):**
```bash
alias wez-reset="rm -f ~/.config/wezterm/.wezterm_size_cache && echo 'WezTerm size cache removed!'"
```

**Windows (PowerShell):**
```powershell
function wez-reset { Remove-Item "$env:APPDATA\wezterm\.wezterm_size_cache"; Write-Host "WezTerm size cache removed!" }
```
