import SwiftUI

/// A white job-match card (avatar + title + subtitle + fit badge). Reused on the
/// reveal, queue and detail screens.
struct MatchCard: View {
    var job: JobMatch
    var shadowStrength: Double = 0.22
    var body: some View {
        HStack(spacing: 13) {
            JobAvatar(letter: job.letter, color: job.avatarColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(job.title).carl(15, .bold).foregroundStyle(CarlColor.navy)
                Text(job.subtitle).carl(13, .medium).foregroundStyle(CarlColor.textSoft)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            FitBadge(text: "\(job.fit)%")
        }
        .padding(15)
        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: .black.opacity(shadowStrength * 0.4), radius: 12, y: 8)
    }
}

// MARK: - Carl is searching (immersive)

struct SearchingScreen: View {
    var body: some View {
        PhoneFrame(chrome: .light, homeIndicatorLight: true) {
            CarlColor.navyDeep
        } content: {
            VStack(spacing: 0) {
                Text("CARL IS ON IT")
                    .carl(13, .bold).tracking(2).foregroundStyle(Color(hex: 0x6E86C4))
                    .padding(.bottom, 18)
                CarlAvatar(lensInk: CarlColor.navyDeeper, showDashes: true, scans: true, rings: true)
                    .frame(width: 140, height: 132)
                    .padding(.bottom, 24)
                Text("312").carl(72, .heavy).foregroundStyle(.white)
                Text("great-fit jobs found & counting…")
                    .carl(16, .semibold).foregroundStyle(CarlColor.textOnNavyMuted)
                    .padding(.top, 6).padding(.bottom, 28)

                VStack(spacing: 2) {
                    foundRow("Northwind — Senior Product Designer", color: Color(hex: 0xE6ECF8), done: true, highlighted: true)
                    foundRow("Lumen Health — Product Designer", color: Color(hex: 0xC3CEE6), done: true)
                    foundRow("Cardinal Bank — Sr. UX Designer", color: CarlColor.textOnNavyMuted, done: false)
                }
                .padding(8)
                .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(.white.opacity(0.09), lineWidth: 1))

                Spacer()
                VStack(spacing: 10) {
                    HStack {
                        Text("Scanning 40+ job sources").carl(13, .semibold).foregroundStyle(CarlColor.textOnNavyMuted)
                        Spacer()
                        BlipDots()
                    }
                    ScanningBar(track: Color.white.opacity(0.12))
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 84).padding(.bottom, 40)
        }
    }

    private func foundRow(_ text: String, color: Color, done: Bool, highlighted: Bool = false) -> some View {
        HStack(spacing: 11) {
            if done {
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .heavy)).foregroundStyle(.white)
                    .frame(width: 24, height: 24).background(CarlColor.green, in: Circle())
            } else {
                SpinnerRing(color: CarlColor.royalSoft, size: 20)
                    .frame(width: 24, height: 24)
            }
            Text(text).carl(13.5, .semibold).foregroundStyle(color)
            Spacer()
        }
        .padding(.horizontal, 12).padding(.vertical, 11)
        .background(highlighted ? Color.white.opacity(0.05) : .clear,
                    in: RoundedRectangle(cornerRadius: 13, style: .continuous))
        .opacity(done ? 1 : 0.7)
    }
}

// MARK: - The reveal (immersive navy)

struct RevealScreen: View {
    var body: some View {
        PhoneFrame(chrome: .light, homeIndicatorLight: true) {
            CarlColor.navy
        } content: {
            ZStack(alignment: .top) {
                ConfettiBits()
                VStack(spacing: 0) {
                    CarlAvatar(eyes: .happy, showSparkle: true).frame(width: 118, height: 112)
                        .padding(.bottom, 8)
                    VStack(spacing: 10) {
                        (Text("I found ").carl(27, .heavy).foregroundColor(.white)
                         + Text("312 jobs").carl(27, .heavy).foregroundColor(CarlColor.royalSoft)
                         + Text(" worth applying to in your area.").carl(27, .heavy).foregroundColor(.white))
                            .multilineTextAlignment(.center)
                        Text("All matched to your skills, pay, and location.")
                            .carl(15, .medium).foregroundStyle(CarlColor.textOnNavyMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 8)
                    .padding(.bottom, 22)

                    VStack(spacing: 11) {
                        ForEach(SampleData.topMatches) { MatchCard(job: $0) }
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 72)

                VStack(spacing: 14) {
                    Text("+ 309 more great-fit matches waiting")
                        .carl(13, .semibold).foregroundStyle(CarlColor.textOnNavyMuted)
                    CarlButton(title: "Unlock all 312 matches", systemIcon: "lock.fill")
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .background(alignment: .bottom) {
                    LinearGradient(colors: [.clear, CarlColor.navy], startPoint: .top, endPoint: .bottom)
                        .frame(height: 200)
                }
            }
        }
    }
}

private struct ConfettiBits: View {
    var body: some View {
        ZStack {
            bit(CarlColor.royalSoft, 8, square: true).offset(x: -150, y: 100)
            bit(CarlColor.royal, 10, square: true).offset(x: 130, y: 150)
            bit(CarlColor.mint, 7, square: false).offset(x: 90, y: 124)
            bit(CarlColor.gold, 6, square: false).offset(x: -110, y: 180)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    private func bit(_ c: Color, _ s: CGFloat, square: Bool) -> some View {
        Group {
            if square { RoundedRectangle(cornerRadius: 2).fill(c).rotationEffect(.degrees(25)) }
            else { Circle().fill(c) }
        }
        .frame(width: s, height: s)
    }
}
