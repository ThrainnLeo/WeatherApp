import SwiftUI

/// The background of a screen: the theme's gradient and, on top of it, its animated layers (clouds,
/// rain, snow, sun glow or stars). Sits behind the text, so it is faint and never takes focus (H-02).
///
/// Battery: the animation runs at the theme's own frame rate (not 60 fps) and pauses, leaving one still
/// frame, when Reduce Motion or Low Power Mode is on or the app isn't active.
struct WeatherBackground: View {
    let theme: WeatherTheme
    /// `false` draws the gradient only. Secondary screens (the day detail, the favourites sheet) use it, so
    /// only one animated background exists at a time and those screens stay calm.
    var isAnimated = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase
    @State private var lowPowerMode = ProcessInfo.processInfo.isLowPowerModeEnabled

    /// A paused `TimelineView` stops updating, so the `Canvas` keeps the one frame it last drew.
    private var isPaused: Bool {
        reduceMotion || lowPowerMode || scenePhase != .active
    }

    var body: some View {
        ZStack {
            theme.gradient
            if isAnimated {
                animatedLayers
            }
        }
        .ignoresSafeArea()
        .task {
            // Low Power Mode can be switched on or off while the screen is open.
            for await _ in NotificationCenter.default.notifications(named: .NSProcessInfoPowerStateDidChange) {
                let enabled = ProcessInfo.processInfo.isLowPowerModeEnabled
                // SwiftUI doesn't compare values, so only write when it changed.
                if lowPowerMode != enabled { lowPowerMode = enabled }
            }
        }
    }

    private var animatedLayers: some View {
        // Copied out as plain values: the `Canvas` closure isn't tied to the main actor,
        // so it shouldn't reach back into this view.
        let layers = theme.layers
        let isLight = theme.colorScheme == .light
        return TimelineView(.animation(minimumInterval: theme.frameInterval, paused: isPaused)) { timeline in
            Canvas { context, size in
                WeatherLayerRenderer.draw(
                    layers, isLight: isLight, in: &context, size: size,
                    time: timeline.date.timeIntervalSinceReferenceDate
                )
            } symbols: {
                Image(systemName: "cloud.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.white)
                    .tag(WeatherLayerRenderer.cloudSymbolID)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Flip through every theme to see its layers, without waiting for the right weather.
#Preview("All themes") {
    @Previewable @State var theme = WeatherTheme.rain
    ZStack(alignment: .bottom) {
        WeatherBackground(theme: theme)
        Picker("Theme", selection: $theme) {
            ForEach(WeatherTheme.allCases, id: \.self) { theme in
                Text(String(describing: theme)).tag(theme)
            }
        }
        .pickerStyle(.menu)
        .padding()
    }
    .preferredColorScheme(theme.colorScheme)
}
