pragma Singleton
import QtQuick 6.8
import QtQuick.Controls.Material 6.8

Item {
    Item {
        id: lightTheme
        readonly property color primary: "#415F91"
        readonly property color surfaceTint: "#415F91"
        readonly property color colorOnPrimary: "#FFFFFF"
        readonly property color primaryContainer: "#D6E3FF"
        readonly property color colorOnPrimaryContainer: "#284777"
        readonly property color secondary: "#565F71"
        readonly property color colorOnSecondary: "#FFFFFF"
        readonly property color secondaryContainer: "#DAE2F9"
        readonly property color colorOnSecondaryContainer: "#3E4759"
        readonly property color tertiary: "#705575"
        readonly property color colorOnTertiary: "#FFFFFF"
        readonly property color tertiaryContainer: "#FAD8FD"
        readonly property color colorOnTertiaryContainer: "#573E5C"
        readonly property color error: "#BA1A1A"
        readonly property color colorOnError: "#FFFFFF"
        readonly property color errorContainer: "#FFDAD6"
        readonly property color colorOnErrorContainer: "#93000A"
        readonly property color background: "#F9F9FF"
        readonly property color colorOnBackground: "#191C20"
        readonly property color surface: "#F9F9FF"
        readonly property color colorOnSurface: "#191C20"
        readonly property color surfaceVariant: "#E0E2EC"
        readonly property color colorOnSurfaceVariant: "#44474E"
        readonly property color outline: "#74777F"
        readonly property color outlineVariant: "#C4C6D0"
        readonly property color shadow: "#000000"
        readonly property color scrim: "#000000"
        readonly property color inverseSurface: "#2E3036"
        readonly property color inverseOnSurface: "#F0F0F7"
        readonly property color inversePrimary: "#AAC7FF"
        readonly property color primaryFixed: "#D6E3FF"
        readonly property color colorOnPrimaryFixed: "#001B3E"
        readonly property color primaryFixedDim: "#AAC7FF"
        readonly property color colorOnPrimaryFixedVariant: "#284777"
        readonly property color secondaryFixed: "#DAE2F9"
        readonly property color colorOnSecondaryFixed: "#131C2B"
        readonly property color secondaryFixedDim: "#BEC6DC"
        readonly property color colorOnSecondaryFixedVariant: "#3E4759"
        readonly property color tertiaryFixed: "#FAD8FD"
        readonly property color colorOnTertiaryFixed: "#28132E"
        readonly property color tertiaryFixedDim: "#DDBCE0"
        readonly property color colorOnTertiaryFixedVariant: "#573E5C"
        readonly property color surfaceDim: "#D9D9E0"
        readonly property color surfaceBright: "#F9F9FF"
        readonly property color surfaceContainerLowest: "#FFFFFF"
        readonly property color surfaceContainerLow: "#F3F3FA"
        readonly property color surfaceContainer: "#EDEDF4"
        readonly property color surfaceContainerHigh: "#E7E8EE"
        readonly property color surfaceContainerHighest: "#E2E2E9"
    }

    Item {
        id: darkTheme
        readonly property color primary: "#AAC7FF"
        readonly property color surfaceTint: "#AAC7FF"
        readonly property color colorOnPrimary: "#0A305F"
        readonly property color primaryContainer: "#284777"
        readonly property color colorOnPrimaryContainer: "#D6E3FF"
        readonly property color secondary: "#BEC6DC"
        readonly property color colorOnSecondary: "#283141"
        readonly property color secondaryContainer: "#3E4759"
        readonly property color colorOnSecondaryContainer: "#DAE2F9"
        readonly property color tertiary: "#DDBCE0"
        readonly property color colorOnTertiary: "#3F2844"
        readonly property color tertiaryContainer: "#573E5C"
        readonly property color colorOnTertiaryContainer: "#FAD8FD"
        readonly property color error: "#FFB4AB"
        readonly property color colorOnError: "#690005"
        readonly property color errorContainer: "#93000A"
        readonly property color colorOnErrorContainer: "#FFDAD6"
        readonly property color background: "#111318"
        readonly property color colorOnBackground: "#E2E2E9"
        readonly property color surface: "#111318"
        readonly property color colorOnSurface: "#E2E2E9"
        readonly property color surfaceVariant: "#44474E"
        readonly property color colorOnSurfaceVariant: "#C4C6D0"
        readonly property color outline: "#8E9099"
        readonly property color outlineVariant: "#44474E"
        readonly property color shadow: "#000000"
        readonly property color scrim: "#000000"
        readonly property color inverseSurface: "#E2E2E9"
        readonly property color inverseOnSurface: "#2E3036"
        readonly property color inversePrimary: "#415F91"
        readonly property color primaryFixed: "#D6E3FF"
        readonly property color colorOnPrimaryFixed: "#001B3E"
        readonly property color primaryFixedDim: "#AAC7FF"
        readonly property color colorOnPrimaryFixedVariant: "#284777"
        readonly property color secondaryFixed: "#DAE2F9"
        readonly property color colorOnSecondaryFixed: "#131C2B"
        readonly property color secondaryFixedDim: "#BEC6DC"
        readonly property color colorOnSecondaryFixedVariant: "#3E4759"
        readonly property color tertiaryFixed: "#FAD8FD"
        readonly property color colorOnTertiaryFixed: "#28132E"
        readonly property color tertiaryFixedDim: "#DDBCE0"
        readonly property color colorOnTertiaryFixedVariant: "#573E5C"
        readonly property color surfaceDim: "#111318"
        readonly property color surfaceBright: "#37393E"
        readonly property color surfaceContainerLowest: "#0C0E13"
        readonly property color surfaceContainerLow: "#191C20"
        readonly property color surfaceContainer: "#1D2024"
        readonly property color surfaceContainerHigh: "#282A2F"
        readonly property color surfaceContainerHighest: "#33353A"
    }

    // Helper functions to get colors based on theme
    function primary(theme) {
        return theme === Material.Dark ? darkTheme.primary : lightTheme.primary;
    }
    function onPrimary(theme) {
        return theme === Material.Dark ? darkTheme.colorOnPrimary : lightTheme.colorOnPrimary;
    }
    function primaryContainer(theme) {
        return theme === Material.Dark ? darkTheme.primaryContainer : lightTheme.primaryContainer;
    }
    function onPrimaryContainer(theme) {
        return theme === Material.Dark ? darkTheme.colorOnPrimaryContainer : lightTheme.colorOnPrimaryContainer;
    }

    function secondary(theme) {
        return theme === Material.Dark ? darkTheme.secondary : lightTheme.secondary;
    }
    function onSecondary(theme) {
        return theme === Material.Dark ? darkTheme.colorOnSecondary : lightTheme.colorOnSecondary;
    }
    function secondaryContainer(theme) {
        return theme === Material.Dark ? darkTheme.secondaryContainer : lightTheme.secondaryContainer;
    }
    function onSecondaryContainer(theme) {
        return theme === Material.Dark ? darkTheme.colorOnSecondaryContainer : lightTheme.colorOnSecondaryContainer;
    }

    function tertiary(theme) {
        return theme === Material.Dark ? darkTheme.tertiary : lightTheme.tertiary;
    }
    function onTertiary(theme) {
        return theme === Material.Dark ? darkTheme.colorOnTertiary : lightTheme.colorOnTertiary;
    }
    function tertiaryContainer(theme) {
        return theme === Material.Dark ? darkTheme.tertiaryContainer : lightTheme.tertiaryContainer;
    }
    function onTertiaryContainer(theme) {
        return theme === Material.Dark ? darkTheme.colorOnTertiaryContainer : lightTheme.colorOnTertiaryContainer;
    }

    function error(theme) {
        return theme === Material.Dark ? darkTheme.error : lightTheme.error;
    }
    function onError(theme) {
        return theme === Material.Dark ? darkTheme.colorOnError : lightTheme.colorOnError;
    }
    function errorContainer(theme) {
        return theme === Material.Dark ? darkTheme.errorContainer : lightTheme.errorContainer;
    }
    function onErrorContainer(theme) {
        return theme === Material.Dark ? darkTheme.colorOnErrorContainer : lightTheme.colorOnErrorContainer;
    }

    function background(theme) {
        return theme === Material.Dark ? darkTheme.background : lightTheme.background;
    }
    function onBackground(theme) {
        return theme === Material.Dark ? darkTheme.colorOnBackground : lightTheme.colorOnBackground;
    }

    function surface(theme) {
        return theme === Material.Dark ? darkTheme.surface : lightTheme.surface;
    }
    function onSurface(theme) {
        return theme === Material.Dark ? darkTheme.colorOnSurface : lightTheme.colorOnSurface;
    }
    function surfaceVariant(theme) {
        return theme === Material.Dark ? darkTheme.surfaceVariant : lightTheme.surfaceVariant;
    }
    function onSurfaceVariant(theme) {
        return theme === Material.Dark ? darkTheme.colorOnSurfaceVariant : lightTheme.colorOnSurfaceVariant;
    }

    function outline(theme) {
        return theme === Material.Dark ? darkTheme.outline : lightTheme.outline;
    }
    function outlineVariant(theme) {
        return theme === Material.Dark ? darkTheme.outlineVariant : lightTheme.outlineVariant;
    }

    function shadow(theme) {
        return theme === Material.Dark ? darkTheme.shadow : lightTheme.shadow;
    }
    function scrim(theme) {
        return theme === Material.Dark ? darkTheme.scrim : lightTheme.scrim;
    }

    function inverseSurface(theme) {
        return theme === Material.Dark ? darkTheme.inverseSurface : lightTheme.inverseSurface;
    }
    function inverseOnSurface(theme) {
        return theme === Material.Dark ? darkTheme.inverseOnSurface : lightTheme.inverseOnSurface;
    }
    function inversePrimary(theme) {
        return theme === Material.Dark ? darkTheme.inversePrimary : lightTheme.inversePrimary;
    }

    function primaryFixed(theme) {
        return theme === Material.Dark ? darkTheme.primaryFixed : lightTheme.primaryFixed;
    }
    function onPrimaryFixed(theme) {
        return theme === Material.Dark ? darkTheme.colorOnPrimaryFixed : lightTheme.colorOnPrimaryFixed;
    }
    function primaryFixedDim(theme) {
        return theme === Material.Dark ? darkTheme.primaryFixedDim : lightTheme.primaryFixedDim;
    }
    function onPrimaryFixedVariant(theme) {
        return theme === Material.Dark ? darkTheme.colorOnPrimaryFixedVariant : lightTheme.colorOnPrimaryFixedVariant;
    }

    function secondaryFixed(theme) {
        return theme === Material.Dark ? darkTheme.secondaryFixed : lightTheme.secondaryFixed;
    }
    function onSecondaryFixed(theme) {
        return theme === Material.Dark ? darkTheme.colorOnSecondaryFixed : lightTheme.colorOnSecondaryFixed;
    }
    function secondaryFixedDim(theme) {
        return theme === Material.Dark ? darkTheme.secondaryFixedDim : lightTheme.secondaryFixedDim;
    }
    function onSecondaryFixedVariant(theme) {
        return theme === Material.Dark ? darkTheme.colorOnSecondaryFixedVariant : lightTheme.colorOnSecondaryFixedVariant;
    }

    function tertiaryFixed(theme) {
        return theme === Material.Dark ? darkTheme.tertiaryFixed : lightTheme.tertiaryFixed;
    }
    function onTertiaryFixed(theme) {
        return theme === Material.Dark ? darkTheme.colorOnTertiaryFixed : lightTheme.colorOnTertiaryFixed;
    }
    function tertiaryFixedDim(theme) {
        return theme === Material.Dark ? darkTheme.tertiaryFixedDim : lightTheme.tertiaryFixedDim;
    }
    function onTertiaryFixedVariant(theme) {
        return theme === Material.Dark ? darkTheme.colorOnTertiaryFixedVariant : lightTheme.colorOnTertiaryFixedVariant;
    }

    function surfaceDim(theme) {
        return theme === Material.Dark ? darkTheme.surfaceDim : lightTheme.surfaceDim;
    }
    function surfaceBright(theme) {
        return theme === Material.Dark ? darkTheme.surfaceBright : lightTheme.surfaceBright;
    }
    function surfaceContainerLowest(theme) {
        return theme === Material.Dark ? darkTheme.surfaceContainerLowest : lightTheme.surfaceContainerLowest;
    }
    function surfaceContainerLow(theme) {
        return theme === Material.Dark ? darkTheme.surfaceContainerLow : lightTheme.surfaceContainerLow;
    }
    function surfaceContainer(theme) {
        return theme === Material.Dark ? darkTheme.surfaceContainer : lightTheme.surfaceContainer;
    }
    function surfaceContainerHigh(theme) {
        return theme === Material.Dark ? darkTheme.surfaceContainerHigh : lightTheme.surfaceContainerHigh;
    }
    function surfaceContainerHighest(theme) {
        return theme === Material.Dark ? darkTheme.surfaceContainerHighest : lightTheme.surfaceContainerHighest;
    }

    // Compatibility helpers
    function accent(theme) {
        return secondary(theme);
    }
    function foreground(theme) {
        return onSurface(theme);
    }
}
