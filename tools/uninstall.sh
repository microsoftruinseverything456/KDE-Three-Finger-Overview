#!/bin/bash
# Turn off and remove Three Finger Overview.
set -euo pipefail

kwriteconfig6 --file kwinrc --group Plugins --key threefingeroverviewEnabled false
if qdbus6 org.kde.KWin /KWin >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects.unloadEffect threefingeroverview >/dev/null 2>&1 || true
    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure
fi
kpackagetool6 --type=KWin/Effect --remove threefingeroverview
echo "Removed. Any changed settings stay in ~/.config/kwinrc under [Effect-threefingeroverview]."
