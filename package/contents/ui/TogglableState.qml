/*
    Three Finger Overview: a QML copy of KWin's EffectTogglableState
    (src/effect/effecttogglablestate.cpp in KWin 6.8.1), which tracks one view
    being swiped open or closed.

    SPDX-FileCopyrightText: 2023 Aleix Pol Gonzalez <aleixpol@kde.org>
    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQml

QtObject {
    id: state

    enum Status {
        Inactive,
        Activating,
        Deactivating,
        Active,
        Stopped
    }

    property int status: TogglableState.Status.Inactive
    property bool inProgress: false
    property real partialActivationFactor: 0
    property real threshold: 0.5

    // Returns false when the swipe can't start, e.g. another full screen effect is
    // running, like EffectTogglableState's activeFullScreenEffect() check.
    property var canStart: () => true

    // Emitted for each status change, right away, like the C++ statusChanged.
    signal statusSet(int status)

    function setStatus(newStatus) {
        if (status !== newStatus) {
            status = newStatus;
            statusSet(newStatus);
        }
    }

    function activate() {
        inProgress = false;
        partialActivationFactor = 1;
        setStatus(TogglableState.Status.Active);
    }

    function deactivate() {
        inProgress = false;
        partialActivationFactor = 0;
        setStatus(TogglableState.Status.Inactive);
    }

    function stop() {
        inProgress = false;
        partialActivationFactor = 0;
        setStatus(TogglableState.Status.Stopped);
    }

    function toggle() {
        if (status !== TogglableState.Status.Active) {
            activate();
        } else {
            deactivate();
        }
    }

    // Progress of the swipe that opens the view.
    function setProgress(progress) {
        if (status !== TogglableState.Status.Inactive && status !== TogglableState.Status.Activating) {
            return;
        }
        if (status === TogglableState.Status.Inactive && !canStart()) {
            return;
        }
        setStatus(TogglableState.Status.Activating);
        inProgress = true;
        partialActivationFactor = progress;
    }

    // Progress of the swipe that closes the view.
    function setRegress(regress) {
        if (status !== TogglableState.Status.Active && status !== TogglableState.Status.Deactivating) {
            return;
        }
        setStatus(TogglableState.Status.Deactivating);
        inProgress = true;
        partialActivationFactor = 1 - regress;
    }

    // The opening swipe ended, by lifting the fingers or by turning around.
    function activateReleased() {
        if (status === TogglableState.Status.Activating) {
            if (partialActivationFactor > threshold) {
                activate();
            } else {
                deactivate();
            }
        }
    }

    function deactivateReleased() {
        if (status === TogglableState.Status.Deactivating) {
            if (partialActivationFactor < 1 - threshold) {
                deactivate();
            } else {
                activate();
            }
        }
    }
}
