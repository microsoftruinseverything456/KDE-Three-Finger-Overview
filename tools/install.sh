#!/bin/bash
# Install or upgrade Three Finger Overview and turn it on.
#   tools/install.sh [--no-enable]
set -euo pipefail

ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ENABLE=$([ "${1:-}" = "--no-enable" ] && echo 0 || echo 1)
effects() { qdbus6 org.kde.KWin /Effects org.kde.kwin.Effects."$@" 2>/dev/null || true; }

if kpackagetool6 --type=KWin/Effect --show threefingeroverview >/dev/null 2>&1; then
    kpackagetool6 --type=KWin/Effect --upgrade "$ROOT/package"
else
    kpackagetool6 --type=KWin/Effect --install "$ROOT/package"
fi
if [ "$ENABLE" = 1 ]; then
    kwriteconfig6 --file kwinrc --group Plugins --key threefingeroverviewEnabled true
fi

if qdbus6 org.kde.KWin /KWin >/dev/null 2>&1; then
    qdbus6 org.kde.KWin /KWin org.kde.KWin.reconfigure
    # Reloading the effect runs the new code.
    if [ "$ENABLE" = 1 ] || [ "$(effects isEffectLoaded threefingeroverview)" = true ]; then
        effects unloadEffect threefingeroverview >/dev/null
        effects loadEffect threefingeroverview >/dev/null
    fi
    if [ "$(effects isEffectLoaded threefingeroverview)" = true ]; then
        echo "Three Finger Overview is running the version just installed."
    elif [ "$ENABLE" = 1 ]; then
        echo "KWin finds a new effect only when it starts: log out and back in once."
    fi
fi
