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

// MARK: - 06 · Searching · Variation A (immersive)

struct SearchingAScreen: View {
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

// MARK: - 07 · Searching · Variation B (sources checklist)

struct SearchingBScreen: View {
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                VStack(spacing: 14) {
                    CarlAvatar(showDashes: true, scans: true).frame(width: 96, height: 90)
                    VStack(spacing: 4) {
                        Text("Searching for your matches").carl(22, .heavy).foregroundStyle(CarlColor.navy)
                        Text("Hang tight — this is the fun part").carl(14, .medium).foregroundStyle(CarlColor.textSoft)
                    }
                }
                .padding(.bottom, 24)

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("312").carl(46, .heavy).foregroundStyle(.white)
                        Text("matches & counting").carl(13, .semibold).foregroundStyle(CarlColor.textOnNavyMuted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("88%").carl(26, .heavy).foregroundStyle(CarlColor.royalSoft)
                        Text("avg fit score").carl(12, .semibold).foregroundStyle(CarlColor.textOnNavyMuted)
                    }
                }
                .padding(22)
                .background(CarlColor.navy, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .shadow(color: CarlColor.navy.opacity(0.28), radius: 16, y: 12)
                .padding(.bottom, 18)

                VStack(spacing: 0) {
                    sourceRow("in", CarlColor.royal, "LinkedIn Jobs", status: .found("142 found"))
                    Divider().overlay(CarlColor.hairline)
                    sourceRow("G", CarlColor.greenhouse, "Greenhouse", status: .found("86 found"))
                    Divider().overlay(CarlColor.hairline)
                    sourceRow("L", CarlColor.lever, "Lever", status: .found("54 found"))
                    Divider().overlay(CarlColor.hairline)
                    sourceRow("A", CarlColor.ashby, "Ashby", status: .scanning)
                }
                .padding(.horizontal, 18)
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                .carlCardShadow(0.06, radius: 20, y: 6)

                Spacer()
                ScanningBar()
            }
            .padding(.horizontal, 24)
            .padding(.top, 74).padding(.bottom, 40)
        }
    }

    private enum SourceStatus { case found(String), scanning }

    private func sourceRow(_ mono: String, _ color: Color, _ name: String, status: SourceStatus) -> some View {
        HStack(spacing: 13) {
            Text(mono).carl(13, .heavy).foregroundStyle(.white)
                .frame(width: 30, height: 30)
                .background(color, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(name).carl(15, .semibold).foregroundStyle(CarlColor.navy)
            Spacer()
            switch status {
            case .found(let n): Text(n).carl(13, .bold).foregroundStyle(CarlColor.green)
            case .scanning:
                HStack(spacing: 7) {
                    SpinnerRing(size: 16)
                    Text("scanning").carl(13, .semibold).foregroundStyle(CarlColor.textFaint)
                }
            }
        }
        .padding(.vertical, 14)
    }
}

// MARK: - 08 · The reveal · Variation A (immersive navy)

struct RevealAScreen: View {
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

// MARK: - 09 · The reveal · Variation B (light, number-forward)

struct RevealBScreen: View {
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                VStack(spacing: 6) {
                    CarlAvatar(eyes: .happy, showSparkle: true).frame(width: 88, height: 84)
                    Text("312").carl(64, .heavy).foregroundStyle(.white)
                    Text("jobs worth applying to in your area")
                        .carl(16, .semibold).foregroundStyle(CarlColor.textOnNavySoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 26)
                .background(
                    LinearGradient(colors: [CarlColor.royal, CarlColor.navy],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 28, style: .continuous)
                )
                .shadow(color: CarlColor.royal.opacity(0.28), radius: 16, y: 12)
                .padding(.bottom, 18)

                Text("Your top matches").carl(15, .bold).foregroundStyle(CarlColor.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4).padding(.bottom, 12)

                VStack(spacing: 11) {
                    ForEach(SampleData.topMatches) { MatchCard(job: $0, shadowStrength: 0.06) }
                }

                Spacer()
                VStack(spacing: 12) {
                    CarlButton(title: "See all 312 matches", systemIcon: "lock.fill", glow: true)
                    Text("Carl can start applying as soon as you're ready")
                        .carl(13, .semibold).foregroundStyle(CarlColor.textFaint)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 72).padding(.bottom, 40)
        }
    }
}
