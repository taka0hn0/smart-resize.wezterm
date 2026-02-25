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

You can load this plugin directly from your `wezterm.lua` configuration file using WezTerm's built-in plugin manager. 

Add the following to your configuration:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- 1. Import the plugin
local smart_resize = wezterm.plugin.require("[https://github.com/taka0hn0/wez-smart-resize](https://github.com/taka0hn0/wez-smart-resize)")

-- 2. Apply it to your config
smart_resize.apply_to_config(config)

return config
```


## ⌨️ Usage & Configuration

By default, the plugin registers the `CMD|SHIFT + S` shortcut to save your current window size. A toast notification will appear in the top right corner confirming the new default.

### Customizing the Shortcut

If you prefer a different keybinding (which is especially useful if you are syncing your dotfiles across macOS and Linux environments), you can pass an options table when applying the configuration:

```lua
smart_resize.apply_to_config(config, {
  key = 'S',
  mods = 'CTRL|SHIFT'
})
```

## 🧹 Resetting the Cache

If you want to reset your saved window size and return to the default auto-calculated dimensions, you simply need to delete the hidden cache file (`~/.config/wezterm/.wezterm_size_cache`).

It is highly recommended to add the following alias to your shell configuration (e.g., `.zshrc`):

```bash
alias wez-reset="rm -f ~/.config/wezterm/.wezterm_size_cache && echo 'WezTerm size cache removed!'"
```

Run `wez-reset` in your terminal to instantly clear the cached dimensions.
