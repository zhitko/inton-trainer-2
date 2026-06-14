pragma Singleton
import QtQuick 6.8

QtObject {
    // Design dimensions the UI was built for
    readonly property int designWidth: 640
    readonly property int designHeight: 950

    // Available screen real estate from the primary screen.
    // Qt.application.screens[0] is safe to use from a QtObject singleton.
    readonly property real screenWidth: Qt.application.screens.length > 0 ? Qt.application.screens[0].desktopAvailableWidth : designWidth
    readonly property real screenHeight: Qt.application.screens.length > 0 ? Qt.application.screens[0].desktopAvailableHeight : designHeight

    // Scale factor: shrink to fit if the screen is smaller than the design size,
    // but never enlarge beyond 1.0 (keeps the UI crisp on larger screens).
    readonly property real factor: Math.min(1.0, Math.min((screenWidth - 100) / designWidth, (screenHeight - 100) / designHeight))

    // Font size multiplier from user settings (1.0 = Normal, 1.5 = Big, 2.0 = Large).
    // Updated from Main.qml via Binding so all QML fs() calls react reactively.
    property double fontScale: 1.0

    // Convenience helpers -------------------------------------------------

    // Scale a design-space length (px, dp …)
    function px(value) {
        return Math.round(value * factor)
    }

    // Scale a font pixel size (minimum 8 px to stay legible).
    // Applies both the layout scale factor AND the user font size multiplier.
    function fs(pixelSize) {
        return Math.max(8, Math.round(pixelSize * factor * fontScale))
    }

    // Legacy alias kept for backward compat (layout scale only, no font scale)
    function font(pixelSize) {
        return Math.max(8, Math.round(pixelSize * factor))
    }
}
