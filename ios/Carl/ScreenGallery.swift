import SwiftUI

/// Scales the fixed 402×872 phone mockup to fit whatever space is available,
/// keeping it centered — so screens look right on any device in the simulator.
struct ScaledPhone<Content: View>: View {
    @ViewBuilder var content: () -> Content
    var body: some View {
        GeometryReader { geo in
            let scale = min(geo.size.width / 402, geo.size.height / 872)
            content()
                .frame(width: 402, height: 872)
                .scaleEffect(scale)
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct GalleryEntry: Identifiable {
    let id = UUID()
    let label: String
    let view: AnyView
}

private struct GallerySection: Identifiable {
    let id = UUID()
    let title: String
    let entries: [GalleryEntry]
}

struct ScreenGallery: View {
    private let sections: [GallerySection] = [
        GallerySection(title: "Onboarding — the first hello", entries: [
            GalleryEntry(label: "01 · Meet Carl", view: AnyView(MeetCarlScreen())),
            GalleryEntry(label: "02 · Carl interviews you", view: AnyView(InterviewScreen())),
            GalleryEntry(label: "03 · Resume upload", view: AnyView(ResumeUploadScreen())),
            GalleryEntry(label: "04 · Carl reads your resume", view: AnyView(ReadingResumeScreen())),
            GalleryEntry(label: "05 · Confirm what Carl learned", view: AnyView(ConfirmScreen()))
        ]),
        GallerySection(title: "The magic moment — search & reveal", entries: [
            GalleryEntry(label: "06 · Carl is searching", view: AnyView(SearchingScreen())),
            GalleryEntry(label: "07 · The reveal", view: AnyView(RevealScreen()))
        ]),
        GallerySection(title: "Paywall — credit packs", entries: [
            GalleryEntry(label: "08 · Paywall", view: AnyView(PaywallScreen())),
            GalleryEntry(label: "09 · Buy more credits", view: AnyView(BuyMoreScreen()))
        ]),
        GallerySection(title: "The core product", entries: [
            GalleryEntry(label: "10 · Review & apply queue", view: AnyView(QueueScreen())),
            GalleryEntry(label: "11 · Dashboard / progress", view: AnyView(DashboardScreen())),
            GalleryEntry(label: "12 · Application detail", view: AnyView(ApplicationDetailScreen())),
            GalleryEntry(label: "13 · Settings / profile", view: AnyView(SettingsScreen()))
        ]),
        GallerySection(title: "Supporting states", entries: [
            GalleryEntry(label: "14 · All caught up", view: AnyView(AllCaughtUpScreen())),
            GalleryEntry(label: "15 · Push notification", view: AnyView(PushNotificationScreen()))
        ])
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    header
                    NavigationLink {
                        HeroFlow()
                            .navigationTitle("Hero flow")
                            .navigationBarTitleDisplayMode(.inline)
                    } label: {
                        heroFlowCard
                    }
                    .buttonStyle(.plain)

                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title.uppercased())
                                .carl(12, .bold)
                                .foregroundStyle(CarlColor.textFaint)
                                .tracking(1.2)
                            VStack(spacing: 0) {
                                ForEach(Array(section.entries.enumerated()), id: \.element.id) { idx, entry in
                                    NavigationLink {
                                        ScaledPhone { entry.view }
                                            .ignoresSafeArea()
                                            .background(CarlColor.canvas)
                                            .navigationTitle(entry.label)
                                            .navigationBarTitleDisplayMode(.inline)
                                    } label: {
                                        HStack {
                                            Text(entry.label).carl(16, .semibold)
                                                .foregroundStyle(CarlColor.navy)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundStyle(CarlColor.textGhost)
                                        }
                                        .padding(.vertical, 15).padding(.horizontal, 16)
                                    }
                                    .buttonStyle(.plain)
                                    if idx < section.entries.count - 1 {
                                        Divider().overlay(CarlColor.hairline).padding(.leading, 16)
                                    }
                                }
                            }
                            .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }
                }
                .padding(20)
            }
            .background(CarlColor.canvas)
            .navigationTitle("Carl")
        }
        .environment(\.phoneFrameStyle, .mock)
        .environment(CarlStore.sample)
    }

    private var header: some View {
        HStack(spacing: 14) {
            CarlMark()
                .frame(width: 40, height: 40)
                .background(CarlColor.navy, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text("Carl").carl(26, .heavy).foregroundStyle(CarlColor.navy)
                Text("15 screens · iOS · Plus Jakarta Sans")
                    .carl(13, .medium).foregroundStyle(CarlColor.textMuted)
            }
        }
    }

    private var heroFlowCard: some View {
        HStack(spacing: 14) {
            CarlAvatar(showDashes: true, floats: false)
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 3) {
                Text("Run the hero flow").carl(17, .bold).foregroundStyle(.white)
                Text("Welcome → Interview → Searching → Reveal → Paywall")
                    .carl(12, .medium).foregroundStyle(CarlColor.textOnNavySoft)
            }
            Spacer()
            Image(systemName: "play.fill").foregroundStyle(.white)
        }
        .padding(18)
        .background(
            LinearGradient(colors: [CarlColor.royal, CarlColor.navy],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }
}

/// A swipeable, connected walk-through of the core journey.
struct HeroFlow: View {
    private let pages: [AnyView] = [
        AnyView(MeetCarlScreen()), AnyView(InterviewScreen()), AnyView(ResumeUploadScreen()),
        AnyView(ReadingResumeScreen()), AnyView(ConfirmScreen()), AnyView(SearchingScreen()),
        AnyView(RevealScreen()), AnyView(PaywallScreen()), AnyView(QueueScreen()),
        AnyView(DashboardScreen())
    ]
    var body: some View {
        TabView {
            ForEach(0..<pages.count, id: \.self) { i in
                ScaledPhone { pages[i] }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .always))
        .background(CarlColor.canvas)
        .ignoresSafeArea()
    }
}

#Preview { ScreenGallery() }
