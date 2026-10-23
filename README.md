# Three Finger Overview

A KWin effect for KDE Plasma 6. With it, swiping three fingers up or down on
a touchpad opens Overview and Grid View, which Plasma normally does with four.
The view follows your fingers as you swipe, so a slow swipe brings Overview
in slowly, and letting go part way snaps it open or closed.

| Swipe on the touchpad | From the desktop | In Overview      | In Grid View        |
| --------------------- | ---------------- | ---------------- | ------------------- |
| Up                    | Opens Overview   | Goes to Grid View | Closes it if opened by swiping down |
| Down                  | Opens Grid View  | Closes Overview  | Goes back to Overview if opened from it |
| Left / right          | Switches desktop (Plasma already allows three) | | |

Four finger swipes, Meta+W, Meta+G and hot corners keep opening Plasma's own
Overview as before.

## Install

Plasma 6.8, on Wayland.

```bash
bash tools/install.sh      # install or upgrade, and turn it on
bash tools/uninstall.sh    # remove
```

It starts right away, no logout needed. `tools/install.sh --no-enable`
installs it without turning it on.

Or install `dist/threefingeroverview-<version>.kwineffect` from System
Settings › Window Management › Desktop Effects › Get New… (or Install from
File…), then tick Three Finger Overview under Window Management and click
Apply. If it doesn't appear in the list, log out and back in once.

## Settings

The configure button next to the effect has the same window options as
Plasma's Overview: show only windows matching the search, leave out minimized
windows, and arrange windows in Grid View. They're separate from Overview's
own settings, with the same defaults.

## How it works

Plasma's Overview registers its swipes in compiled code with a fixed four
fingers, and no script can change that or move its animation. So this effect
is its own copy of Overview: `Overview.qml`, `DesktopBar.qml` and
`DesktopView.qml` are Plasma's Overview screens from KWin 6.8.1, and
`main.qml` recreates the C++ side around them. It listens for three finger
swipes and feeds their progress into the same gesture states Overview uses
(`TogglableState.qml` is a QML copy of KWin's), so the screens move exactly
as Plasma's do.

## Limitations

- It's a copy of Overview as of Plasma 6.8.1. If a later Plasma changes how
  Overview looks or behaves, the three finger version keeps the old design
  until this effect is updated. It uses KWin's private QML parts (the window
  layout), which a Plasma update could also break.
- With desktops arranged in more than one row, Plasma already uses three
  finger swipes up and down to switch rows. The effect then leaves those
  swipes alone, and Overview needs four fingers. With one row it works again.
- While the three finger Overview is open, switching desktops with a swipe
  animates once the switch happens, instead of following your fingers.
- Search results come from KRunner with its default setup rather than
  Overview's own.
- Swipes made while another full screen effect is running (such as the
  desktop switch slide) are ignored, as in stock Plasma. With the
  [Activate Overview During Desktop Switch](../Activate%20Overview%20During%20Desktop%20Switch)
  script (1.0.4 or later) also installed, a swipe during a desktop slide ends
  the slide and opens Overview.

## Development

```bash
bash tools/package.sh      # dist/threefingeroverview-<version>.kwineffect
```

The effect is in `package/contents/ui/`. The `.kwineffect` file is what the
KDE Store and Get New… install from.

## License

GPL-2.0-or-later, see [LICENSE](LICENSE). The Overview screens and gesture
logic are copied from KWin (GPL-2.0-or-later) and keep their original
copyright notices.
