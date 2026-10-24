/*
    Three Finger Overview: a copy of Plasma's Overview that opens with three
    finger touchpad swipes and follows the fingers, like the four finger
    swipes do with Plasma's own Overview.

    The gesture handling below is a QML port of OverviewEffect
    (src/plugins/overview/overvieweffect.cpp in KWin 6.8.1).

    SPDX-FileCopyrightText: 2021 Vlad Zahorodnii <vlad.zahorodnii@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

// Plasma's Overview registers its swipes in C++ with a fixed four fingers, and
// scripts can only read its progress, not drive it. So this effect is its own
// Overview: Overview.qml, DesktopBar.qml and DesktopView.qml are Plasma's QML,
// and this file supplies what Plasma's C++ side gives them.

import QtQuick
import QtQml
import org.kde.kirigami as Kirigami
import org.kde.kwin

SceneEffect {
    id: effect

    delegate: Component {
        Overview {}
    }

    // Read by Overview.qml, named as on Plasma's OverviewEffect.
    readonly property int animationDuration: Kirigami.Units.longDuration * 1.5
    // Plasma's Overview defaults.
    readonly property bool ignoreMinimized: false
    readonly property bool filterWindows: true
    readonly property bool organizedGrid: true
    readonly property real gestureThreshold: 0.1
    readonly property real overviewPartialActivationFactor: overviewState.partialActivationFactor
    readonly property bool overviewGestureInProgress: overviewState.inProgress
    readonly property real transitionPartialActivationFactor: transitionState.partialActivationFactor
    readonly property bool transitionGestureInProgress: transitionState.inProgress
    readonly property real gridPartialActivationFactor: gridState.partialActivationFactor
    readonly property bool gridGestureInProgress: gridState.inProgress
    property string searchText: ""

    // Plasma's Overview follows desktop switching swipes made while it's open,
    // using offsets that only its C++ side receives. Here the switch animates
    // once it happens instead.
    signal desktopOffsetChanged(var screen)
    function desktopOffsetForScreen(screen) {
        return Qt.point(0, 0);
    }

    function deactivate() {
        shutdownTimer.restart();
        overviewState.deactivate();
    }

    // Whether the views are on screen. Setting visible starts the effect only when
    // no other full screen effect (Plasma's Overview, the desktop slide, ...) is
    // running.
    property bool running: false
    onActivated: running = true
    onDeactivated: running = false

    function start() {
        shutdownTimer.stop();
        if (!running) {
            visible = true;
            if (!running) {
                visible = false;
            }
        }
        return running;
    }

    Timer {
        id: shutdownTimer
        interval: effect.animationDuration
        onTriggered: {
            if (overviewState.status === TogglableState.Status.Inactive) {
                effect.visible = false;
            }
        }
    }

    // Inactive to Overview.
    TogglableState {
        id: overviewState
        threshold: effect.gestureThreshold
        canStart: effect.start
        onStatusSet: (status) => {
            if (status === TogglableState.Status.Activating || status === TogglableState.Status.Active) {
                effect.searchText = "";
                effect.start();
                gridState.stop();
            }
            if (status === TogglableState.Status.Active) {
                transitionState.deactivate();
            }
            if (status === TogglableState.Status.Inactive || status === TogglableState.Status.Deactivating) {
                transitionState.stop();
            }
            if (status === TogglableState.Status.Inactive) {
                gridState.deactivate();
                effect.deactivate();
            }
        }
    }

    // Overview to Grid View.
    TogglableState {
        id: transitionState
        threshold: effect.gestureThreshold
        status: TogglableState.Status.Stopped
        onStatusSet: (status) => {
            if (status === TogglableState.Status.Activating || status === TogglableState.Status.Active) {
                overviewState.stop();
            }
            if (status === TogglableState.Status.Inactive) {
                overviewState.activate();
            }
            if (status === TogglableState.Status.Active) {
                gridState.activate();
            }
            if (status === TogglableState.Status.Inactive || status === TogglableState.Status.Deactivating) {
                gridState.stop();
            }
        }
    }

    // Inactive to Grid View.
    TogglableState {
        id: gridState
        threshold: effect.gestureThreshold
        canStart: effect.start
        onStatusSet: (status) => {
            if (status === TogglableState.Status.Activating || status === TogglableState.Status.Active) {
                effect.searchText = "";
                effect.start();
                overviewState.stop();
            }
            if (status === TogglableState.Status.Inactive) {
                overviewState.deactivate();
                effect.deactivate();
            }
            if (status === TogglableState.Status.Active) {
                transitionState.activate();
            }
            if (status === TogglableState.Status.Inactive || status === TogglableState.Status.Deactivating) {
                transitionState.stop();
            }
        }
    }

    // Each state gets a swipe that opens it and the opposite one that closes it,
    // as EffectTogglableGesture::addTouchpadSwipeGesture does.
    readonly property var gestures: [
        { state: overviewState, direction: SwipeGestureHandler.Direction.Up, opens: true },
        { state: overviewState, direction: SwipeGestureHandler.Direction.Down, opens: false },
        { state: transitionState, direction: SwipeGestureHandler.Direction.Up, opens: true },
        { state: transitionState, direction: SwipeGestureHandler.Direction.Down, opens: false },
        { state: gridState, direction: SwipeGestureHandler.Direction.Down, opens: true },
        { state: gridState, direction: SwipeGestureHandler.Direction.Up, opens: false },
    ]

    // With more than one row of desktops, KWin already uses three finger swipes
    // up and down to switch rows, so the swipes are only added with one row.
    Instantiator {
        model: Workspace.desktopGridHeight === 1 ? effect.gestures : []
        delegate: SwipeGestureHandler {
            required property var modelData
            deviceType: SwipeGestureHandler.Device.Touchpad
            direction: modelData.direction
            fingerCount: 3
            onProgressChanged: {
                if (modelData.opens) {
                    modelData.state.setProgress(progress);
                } else {
                    modelData.state.setRegress(progress);
                }
            }
            onActivated: released()
            onCancelled: released()
            function released() {
                if (modelData.opens) {
                    modelData.state.activateReleased();
                } else {
                    modelData.state.deactivateReleased();
                }
            }
        }
    }

}
