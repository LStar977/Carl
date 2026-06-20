import SwiftUI

// MARK: - 17 · All caught up

struct AllCaughtUpScreen: View {
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            ZStack {
                VStack(spacing: 0) {
                    CarlAvatar(eyes: .happy, showDashes: true).frame(width: 150, height: 142)
                        .padding(.bottom, 8)
                    VStack(spacing: 10) {
                        Text("You're all caught up").carl(26, .heavy).foregroundStyle(CarlColor.navy)
                        Text("I've sent everything worth sending for now. Go live your life — I'll keep scanning and ping you the moment a great new match lands.")
                            .carl(15, .medium).foregroundStyle(CarlColor.textSoft)
                            .multilineTextAlignment(.center).lineSpacing(3)
                    }
                    .padding(.bottom, 24)

                    HStack(spacing: 0) {
                        miniStat("47", "applied today", CarlColor.navy)
                        Rectangle().fill(CarlColor.hairline).frame(width: 1)
                        miniStat("14", "reviewed", CarlColor.green)
                        Rectangle().fill(CarlColor.hairline).frame(width: 1)
                        miniStat("0", "need you", CarlColor.textFaint)
                    }
                    .frame(height: 60)
                    .padding(18)
                    .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .carlCardShadow(0.07, radius: 20, y: 6)
                    .padding(.bottom, 22)

                    HStack(spacing: 8) {
                        Text("Carl's still watching 40+ sources").carl(13, .semibold).foregroundStyle(CarlColor.textFaint)
                        BlipDots(size: 5)
                    }
                }
                .padding(.horizontal, 36)

                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        CarlSecondaryButton(title: "See submitted")
                        CarlButton(title: "Tweak preferences", fill: CarlColor.navy, height: 52, glow: false)
                    }
                    .padding(.horizontal, 24).padding(.bottom, 40)
                }
            }
        }
    }

    private func miniStat(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(spacing: 3) {
            Text(value).carl(22, .heavy).foregroundStyle(color)
            Text(label).carl(11.5, .semibold).foregroundStyle(CarlColor.textFaint)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 18 · Push notification (lock screen)

struct PushNotificationScreen: View {
    var body: some View {
        PhoneFrame(chrome: .light, homeIndicatorLight: true) {
            LinearGradient(colors: [CarlColor.navy, CarlColor.navyDeeper, CarlColor.navyDeep],
                           startPoint: .topLeading, endPoint: .bottomTrailing)
        } content: {
            VStack(spacing: 0) {
                // clock
                VStack(spacing: 4) {
                    Image(systemName: "lock.fill").font(.system(size: 18)).foregroundStyle(.white.opacity(0.8))
                        .padding(.bottom, 14)
                    Text("9:41").carl(78, .bold).foregroundStyle(.white)
                    Text("Monday, June 16").carl(17, .semibold).foregroundStyle(.white.opacity(0.8))
                }
                .padding(.top, 78)

                VStack(spacing: 10) {
                    notification(time: "now", strong: true,
                                 title: "Carl applied to 12 jobs today 🎉",
                                 body: "3 are 95%+ fits. Tap to review before they go out.",
                                 eyes: .happy)
                    notification(time: "2h ago", strong: false,
                                 title: "Northwind viewed your application 👀",
                                 body: "Senior Product Designer · a good sign.",
                                 eyes: .open)
                }
                .padding(.horizontal, 14)
                .padding(.top, 36)

                Spacer()
                HStack {
                    lockButton("flashlight.off.fill")
                    Spacer()
                    lockButton("camera.fill")
                }
                .padding(.horizontal, 44).padding(.bottom, 42)
            }
        }
    }

    private func notification(time: String, strong: Bool, title: String, body: String, eyes: CarlMark.Eyes) -> some View {
        HStack(alignment: .top, spacing: 12) {
            CarlMark(eyes: eyes, showHighlight: false)
                .frame(width: 30, height: 30)
                .frame(width: 42, height: 42)
                .background(CarlColor.navy, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("CARL").carl(13.5, .heavy).foregroundStyle(.white)
                    Spacer()
                    Text(time).carl(12, .semibold).foregroundStyle(.white.opacity(0.6))
                }
                Text(title).carl(14.5, .bold).foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(body).carl(13, .medium).foregroundStyle(.white.opacity(0.82))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .background(.white.opacity(strong ? 0.14 : 0.1), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 22).stroke(.white.opacity(strong ? 0.18 : 0.14), lineWidth: 0.5))
    }

    private func lockButton(_ icon: String) -> some View {
        Image(systemName: icon).font(.system(size: 20, weight: .medium)).foregroundStyle(.white)
            .frame(width: 52, height: 52)
            .background(.white.opacity(0.16), in: Circle())
    }
}
