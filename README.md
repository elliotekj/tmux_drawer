# Tmux Drawer

A Tmux (2.9+) plugin that adds a toggleable drawer to Tmux windows. The drawer
appears on the right side of your active window and can be easily toggled
on/off while preserving its contents.

The plugin works for me and my workflow, though its use of hidden windows means
that you might hit some unexpected windows when navigating through a session if
you don't use something more precise than `prefix + arrow`. I'll happily accept
PRs to improve this, and will revisit it if this gains any traction outside of
my own use.

## Features

- Customizable drawer width (default is 20% of the window width)
- Drawer state is preserved when hidden
- Drawer is window-specific

## Installation

### Using TPM (Tmux Plugin Manager)

Add this line to your `~/.tmux.conf`:

```tmux
set -g @plugin 'elliotekj/tmux_drawer'
```

Then press `prefix + I` to install the plugin.

### Manual Installation

Clone the repository:

```bash
git clone https://github.com/elliotekj/tmux_drawer ~/.tmux/plugins/tmux_drawer
```

## Configuration

### Setting up a Keybinding

The plugin does not set up any default keybindings. You must add your own
keybinding to your Tmux config. For example:

```tmux
bind-key T run-shell "~/.tmux/plugins/tmux_drawer/tmux_drawer.tmux"
```

### Customizing Drawer Width

You can specify a custom width for the drawer by adjusting your keybinding in `~/.tmux.conf`:

```tmux
# Set drawer width to 30% of window
bind-key T run-shell "~/.tmux/plugins/tmux_drawer/tmux_drawer.tmux '' 30"
```

## License

Tmux Drawer is released under the [`Apache License
2.0`](https://github.com/elliotekj/tmux_drawer/blob/main/LICENSE).

## About

This plugin was written by [Elliot Jackson](https://elliotekj.com).

- Blog: [https://elliotekj.com](https://elliotekj.com)
- Email: elliot@elliotekj.com
