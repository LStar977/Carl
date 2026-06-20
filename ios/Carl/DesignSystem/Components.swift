import SwiftUI

// MARK: - Device chrome

enum StatusBarStyle { case light, dark }

/// iOS status bar (9:41 + signal/wifi/battery). `light` = white glyphs for dark
/// backgrounds, `dark` = navy glyphs for light backgrounds.
struct StatusBarView: View {
    var style: StatusBarStyle
    private var tint: Color { style == .light ? .white : CarlColor.navy }

    var body: some View {
        HStack {
            Text("9:41").carl(16, .bold).foregroundStyle(tint)
            Spacer()
            HStack(spacing: 7) {
                Image(systemName: "cellularbars").font(.system(size: 13, weight: .semibold))
                Image(systemName: "wifi").font(.system(size: 13, weight: .semibold))
                Image(systemName: "battery.75").font(.system(size: 15, weight: .regular))
            }
            .foregroundStyle(tint)
        }
        .padding(.horizontal, 34)
        .padding(.top, 18)
        .frame(height: 56, alignment: .top)
    }
}

struct HomeIndicator: View {
    var light: Bool = false
    var body: some View {
        Capsule()
            .fill(light ? Color.white.opacity(0.6) : Color.black.opacity(0.22))
            .frame(width: 135, height: 5)
            .padding(.bottom, 9)
    }
}

/// How a `PhoneFrame` renders: `.device` fills the real screen (the shipping
/// app), `.mock` draws the 402×872 framed card with fake chrome (the gallery).
enum PhoneFrameStyle { case device, mock }

private struct PhoneFrameStyleKey: EnvironmentKey {
    static let defaultValue: PhoneFrameStyle = .device
}
extension EnvironmentValues {
    var phoneFrameStyle: PhoneFrameStyle {
        get { self[PhoneFrameStyleKey.self] }
        set { self[PhoneFrameStyleKey.self] = newValue }
    }
}

/// A screen container. In `.device` mode it fills the real screen edge-to-edge
/// and uses the OS status bar / safe areas; in `.mock` mode it renders the
/// 402×872 design card with a drawn notch, status bar and home indicator.
/// Screens are authored once and work in both modes — the fixed top/bottom
/// paddings line up with the real status bar and home indicator.
struct PhoneFrame<Background: View, Content: View>: View {
    @Environment(\.phoneFrameStyle) private var frameStyle

    var chrome: StatusBarStyle = .dark
    var homeIndicatorLight: Bool = false
    var showStatusBar: Bool = true
    @ViewBuilder var background: () -> Background
    @ViewBuilder var content: () -> Content

    init(chrome: StatusBarStyle = .dark,
         homeIndicatorLight: Bool = false,
         showStatusBar: Bool = true,
         @ViewBuilder background: @escaping () -> Background,
         @ViewBuilder content: @escaping () -> Content) {
        self.chrome = chrome
        self.homeIndicatorLight = homeIndicatorLight
        self.showStatusBar = showStatusBar
        self.background = background
        self.content = content
    }

    var body: some View {
        Group {
            switch frameStyle {
            case .device: deviceBody
            case .mock:   mockBody
            }
        }
    }

    /// Full-screen: fills the device, lets the OS draw the status bar / home
    /// indicator. `chrome` drives the status-bar color via the color scheme.
    private var deviceBody: some View {
        ZStack(alignment: .topLeading) {
            background().frame(maxWidth: .infinity, maxHeight: .infinity)
            content().frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea(.container, edges: .all) // keep edge-to-edge, but let the keyboard push content up
        .preferredColorScheme(chrome == .light ? .dark : .light)
    }

    /// Design card: the 402×872 mockup with drawn chrome (gallery only).
    private var mockBody: some View {
        ZStack(alignment: .topLeading) {
            background().frame(width: 402, height: 872)
            content().frame(width: 402, height: 872, alignment: .topLeading)
        }
        .frame(width: 402, height: 872)
        .overlay(alignment: .top) {
            if showStatusBar { StatusBarView(style: chrome) }
        }
        .overlay(alignment: .top) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(CarlColor.ink)
                .frame(width: 122, height: 35)
                .padding(.top, 11)
        }
        .overlay(alignment: .bottom) { HomeIndicator(light: homeIndicatorLight) }
        .clipShape(RoundedRectangle(cornerRadius: 48, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 48, style: .continuous)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
        .shadow(color: CarlColor.navy.opacity(0.20), radius: 40, x: 0, y: 40)
    }
}

// MARK: - Building blocks

/// Filled rounded "button" used across screens (visual; not necessarily tappable).
struct CarlButton: View {
    var title: String
    var systemIcon: String? = nil
    var trailingNote: String? = nil
    var fill: Color = CarlColor.royal
    var textColor: Color = .white
    var height: CGFloat = 58
    var glow: Bool = true

    var body: some View {
        HStack(spacing: 8) {
            if let systemIcon { Image(systemName: systemIcon).font(.system(size: 16, weight: .semibold)) }
            Text(title).carl(17, .bold)
            if let trailingNote {
                Text(trailingNote).carl(12, .semibold).opacity(0.82)
            }
        }
        .foregroundStyle(textColor)
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: glow ? fill.opacity(0.4) : .clear, radius: 14, x: 0, y: 12)
    }
}

struct CarlSecondaryButton: View {
    var title: String
    var height: CGFloat = 52
    var body: some View {
        Text(title)
            .carl(16, .bold)
            .foregroundStyle(CarlColor.navy)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(CarlColor.border, lineWidth: 1.5)
            )
    }
}

/// Rounded-square company/avatar tile with a single initial.
struct JobAvatar: View {
    var letter: String
    var color: Color
    var size: CGFloat = 46
    var corner: CGFloat = 13
    var fontSize: CGFloat = 18
    var body: some View {
        Text(letter)
            .carl(fontSize, .heavy)
            .foregroundStyle(.white)
            .frame(width: size, height: size)
            .background(color, in: RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

struct FitBadge: View {
    var text: String
    var body: some View {
        Text(text)
            .carl(12, .bold)
            .foregroundStyle(CarlColor.greenDeep)
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(CarlColor.greenBG, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

/// Shows how Carl will apply: `A` = auto-submitted via an official channel,
/// anything else = Carl prepares it and you tap to send.
struct ApplyTierBadge: View {
    let tier: String
    private var isAuto: Bool { tier == "A" }
    private var tint: Color { isAuto ? CarlColor.royal : CarlColor.ashby }
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isAuto ? "bolt.fill" : "hand.tap.fill")
                .font(.system(size: 9, weight: .bold))
            Text(isAuto ? "Auto-apply" : "1-tap apply").carl(10.5, .bold)
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 8).padding(.vertical, 4)
        .background(tint.opacity(0.12), in: Capsule())
    }
}

/// A speech bubble tail + card, used for Carl's chat messages.
struct CarlSpeechCard<Content: View>: View {
    var background: Color = .white
    var cornerStyle: RoundedCornerStyle = .standard
    @ViewBuilder var content: () -> Content

    enum RoundedCornerStyle { case standard, chatLeading }

    var body: some View {
        content()
            .padding(.horizontal, 16).padding(.vertical, 13)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 20, bottomLeadingRadius: cornerStyle == .chatLeading ? 6 : 20,
                    bottomTrailingRadius: 20, topTrailingRadius: 20, style: .continuous
                )
                .fill(background)
            )
            .shadow(color: CarlColor.navy.opacity(0.06), radius: 6, x: 0, y: 3)
    }
}

/// Small "Carl said…" header row (avatar + message) used on several screens.
struct CarlMessageRow: View {
    var message: String
    var avatarSize: CGFloat = 44
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            CarlMark()
                .frame(width: avatarSize, height: avatarSize)
                .background(CarlColor.navy, in: Circle())
            CarlSpeechCard(cornerStyle: .chatLeading) {
                Text(message).carl(16, .semibold).foregroundStyle(CarlColor.navy)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Animated three-dot "working" indicator.
struct BlipDots: View {
    var color: Color = CarlColor.royal
    var size: CGFloat = 6
    @State private var phase = false
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { i in
                Circle().fill(color)
                    .frame(width: size, height: size)
                    .opacity(phase ? 1 : 0.3)
                    .animation(.easeInOut(duration: 0.5).repeatForever().delay(Double(i) * 0.2), value: phase)
            }
        }
        .onAppear { phase = true }
    }
}

/// Indeterminate progress bar that eases back and forth.
struct ScanningBar: View {
    var track: Color = CarlColor.track
    var fill: Color = CarlColor.royal
    @State private var wide = false
    var body: some View {
        GeometryReader { geo in
            Capsule().fill(track)
                .overlay(alignment: .leading) {
                    Capsule().fill(fill)
                        .frame(width: geo.size.width * (wide ? 0.74 : 0.12))
                }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { wide = true }
        }
    }
}

/// Small spinning ring (used for "scanning" rows).
struct SpinnerRing: View {
    var color: Color = CarlColor.royal
    var size: CGFloat = 16
    @State private var spin = false
    var body: some View {
        Circle()
            .trim(from: 0, to: 0.75)
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: size, height: size)
            .rotationEffect(.degrees(spin ? 360 : 0))
            .onAppear { withAnimation(.linear(duration: 0.9).repeatForever(autoreverses: false)) { spin = true } }
    }
}

extension View {
    /// Standard soft card shadow.
    func carlCardShadow(_ strength: Double = 0.06, radius: CGFloat = 16, y: CGFloat = 4) -> some View {
        shadow(color: CarlColor.navy.opacity(strength), radius: radius, x: 0, y: y)
    }
}
