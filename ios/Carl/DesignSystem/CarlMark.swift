import SwiftUI

/// The Carl brand mark, recreated from the Claude Design SVG: a navy "C"/magnifier
/// lens with eyes, a royal-blue briefcase, a magnifier handle, and motion dashes.
/// Drawn in the original 120×116 coordinate space and scaled to fit.
struct CarlMark: View {
    enum Eyes { case open, happy }

    var eyes: Eyes = .open
    /// Lens fill (the dark ring + handle). Defaults to navy; on dark screens the
    /// design uses a deeper navy so the lens reads against the background.
    var lensInk: Color = CarlColor.navy
    var handleInk: Color = CarlColor.navyDeeper
    var showDashes: Bool = false
    var dashColor: Color = CarlColor.royalSoft
    var dashMaxOpacity: Double = 0.9
    var showSparkle: Bool = false
    var showHighlight: Bool = true
    /// Horizontal eye shift, used by the "scanning" animation.
    var eyeShift: CGFloat = 0
    var dashPulse: Double = 1

    var body: some View {
        Canvas { ctx, size in
            let s = min(size.width / 120, size.height / 116)
            ctx.scaleBy(x: s, y: s)

            // Motion dashes (left of the lens)
            if showDashes {
                let dashes: [(CGFloat, CGFloat, CGFloat, Double)] = [
                    (2, 44, 13, 0.4), (6, 55, 10, 0.65), (10, 66, 7, 1.0)
                ]
                for (x, y, w, op) in dashes {
                    let rect = CGRect(x: x, y: y, width: w, height: 5.5)
                    ctx.fill(
                        Path(roundedRect: rect, cornerRadius: 2.75),
                        with: .color(dashColor.opacity(min(op, dashMaxOpacity) * dashPulse))
                    )
                }
            }

            // Sparkle (reveal / celebration)
            if showSparkle {
                var star = Path()
                star.move(to: CGPoint(x: 97, y: 16))
                star.addLine(to: CGPoint(x: 99.2, y: 21.5))
                star.addLine(to: CGPoint(x: 104.7, y: 23.7))
                star.addLine(to: CGPoint(x: 99.2, y: 25.9))
                star.addLine(to: CGPoint(x: 97, y: 31.4))
                star.addLine(to: CGPoint(x: 94.8, y: 25.9))
                star.addLine(to: CGPoint(x: 89.3, y: 23.7))
                star.addLine(to: CGPoint(x: 94.8, y: 21.5))
                star.closeSubpath()
                ctx.fill(star, with: .color(CarlColor.gold))
            }

            // Magnifier handle (rotated 45° about 89.5,94)
            var handleCtx = ctx
            handleCtx.translateBy(x: 89.5, y: 94)
            handleCtx.rotate(by: .degrees(45))
            handleCtx.translateBy(x: -89.5, y: -94)
            handleCtx.fill(
                Path(roundedRect: CGRect(x: 83, y: 74, width: 13, height: 40), cornerRadius: 6.5),
                with: .color(handleInk)
            )

            // Lens
            ctx.fill(Path(ellipseIn: CGRect(x: 15, y: 12, width: 80, height: 80)), with: .color(lensInk))
            ctx.fill(Path(ellipseIn: CGRect(x: 23.5, y: 20.5, width: 63, height: 63)), with: .color(CarlColor.faceCream))

            // Top glass highlight
            if showHighlight {
                var hl = Path()
                hl.move(to: CGPoint(x: 40, y: 33))
                hl.addQuadCurve(to: CGPoint(x: 70, y: 30), control: CGPoint(x: 55, y: 26))
                ctx.stroke(hl, with: .color(.white.opacity(0.9)),
                           style: StrokeStyle(lineWidth: 5, lineCap: .round))
            }

            // Eyes
            switch eyes {
            case .open:
                ctx.fill(Path(ellipseIn: CGRect(x: 41.5 + eyeShift, y: 42.5, width: 11, height: 11)), with: .color(CarlColor.navy))
                ctx.fill(Path(ellipseIn: CGRect(x: 59.5 + eyeShift, y: 42.5, width: 11, height: 11)), with: .color(CarlColor.navy))
                ctx.fill(Path(ellipseIn: CGRect(x: 46.9 + eyeShift, y: 44.5, width: 3.4, height: 3.4)), with: .color(.white))
                ctx.fill(Path(ellipseIn: CGRect(x: 64.9 + eyeShift, y: 44.5, width: 3.4, height: 3.4)), with: .color(.white))
            case .happy:
                var left = Path()
                left.move(to: CGPoint(x: 42, y: 49))
                left.addQuadCurve(to: CGPoint(x: 53, y: 49), control: CGPoint(x: 47.5, y: 43))
                var right = Path()
                right.move(to: CGPoint(x: 59, y: 49))
                right.addQuadCurve(to: CGPoint(x: 70, y: 49), control: CGPoint(x: 64.5, y: 43))
                let style = StrokeStyle(lineWidth: 4.2, lineCap: .round)
                ctx.stroke(left, with: .color(CarlColor.navy), style: style)
                ctx.stroke(right, with: .color(CarlColor.navy), style: style)
            }

            // Briefcase
            ctx.fill(Path(roundedRect: CGRect(x: 44, y: 62, width: 22, height: 15), cornerRadius: 3.5), with: .color(CarlColor.royal))
            ctx.stroke(
                Path(roundedRect: CGRect(x: 51.5, y: 58.5, width: 7, height: 5), cornerRadius: 2),
                with: .color(CarlColor.royal), lineWidth: 2.4
            )
            ctx.fill(Path(CGRect(x: 44, y: 67.4, width: 22, height: 2.4)), with: .color(handleInk.opacity(0.22)))
            ctx.fill(Path(roundedRect: CGRect(x: 53, y: 66.4, width: 4, height: 4.6), cornerRadius: 1), with: .color(CarlColor.faceCream))
        }
        .aspectRatio(120.0 / 116.0, contentMode: .fit)
    }
}

/// A floating, optionally pulsing Carl avatar used on hero/searching/reading screens.
struct CarlAvatar: View {
    var eyes: CarlMark.Eyes = .open
    var lensInk: Color = CarlColor.navy
    var handleInk: Color = CarlColor.navyDeeper
    var showDashes: Bool = false
    var showSparkle: Bool = false
    var floats: Bool = true
    var scans: Bool = false
    var rings: Bool = false
    var ringColor: Color = CarlColor.royal

    @State private var floatUp = false
    @State private var scanShift: CGFloat = 0
    @State private var dashPulse: Double = 1
    @State private var ring1 = false
    @State private var ring2 = false

    var body: some View {
        ZStack {
            if rings {
                ringView(active: ring1)
                ringView(active: ring2)
            }
            CarlMark(
                eyes: eyes,
                lensInk: lensInk,
                handleInk: handleInk,
                showDashes: showDashes,
                showSparkle: showSparkle,
                eyeShift: scanShift,
                dashPulse: dashPulse
            )
            .offset(y: floatUp ? -6 : 0)
        }
        .onAppear {
            if floats {
                withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) { floatUp = true }
            }
            if scans {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) { scanShift = 3 }
            }
            if showDashes {
                withAnimation(.easeInOut(duration: 0.55).repeatForever(autoreverses: true)) { dashPulse = 0.45 }
            }
            if rings {
                withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false)) { ring1 = true }
                withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: false).delay(1)) { ring2 = true }
            }
        }
    }

    private func ringView(active: Bool) -> some View {
        Circle()
            .stroke(ringColor, lineWidth: 2)
            .frame(width: 120, height: 120)
            .scaleEffect(active ? 1.7 : 0.5)
            .opacity(active ? 0 : 0.55)
    }
}
