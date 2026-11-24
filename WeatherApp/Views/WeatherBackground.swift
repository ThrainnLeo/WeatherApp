import SwiftUI

/// The background of a screen: the theme's gradient and, on top of it, its animated layers (clouds,
/// rain, snow, sun glow or stars). Sits behind the text, so it is faint and never takes focus (H-02).
///
/// This view decides nothing about *when* to move: the screen that owns it passes `isPaused`
/// (Reduce Motion, Low Power Mode, app not active, something covering the screen). So it holds no
/// state and no task, and a gradient-only background costs nothing beyond the gradient.
///
/// Battery: the animation runs at the theme's own frame rate (not 60 fps), and a paused `TimelineView`
/// stops updating and leaves one still frame.
struct WeatherBackground: View {
    /// The `UserDefaults` key of the "Animated background" setting, shared by the settings screen
    /// and the screen that decides `isAnimated`.
    static let animatedKey = "animatedBackground"

    let theme: WeatherTheme
    /// `false` draws the gradient only. Secondary screens (the day detail, the favourites sheet) use it, so
    /// only one animated background exists at a time and those screens stay calm.
    var isAnimated = true
    /// `true` freezes the layers on the frame they are showing.
    var isPaused = false

    var body: some View {
        ZStack {
            theme.gradient
            if isAnimated {
                animatedLayers
            }
        }
        .ignoresSafeArea()
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
