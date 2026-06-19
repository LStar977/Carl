import SwiftUI

/// Tabs in the main app shell.
enum CarlTab { case home, queue, activity, profile }

/// App entry: boots a session, runs onboarding, then the main tab shell.
struct RootView: View {
    @State private var store = CarlStore()
    @State private var signedIn = false

    var body: some View {
        Group {
            if signedIn {
                MainTabView()
            } else {
                OnboardingFlow(onFinished: { withAnimation(.easeInOut) { signedIn = true } })
            }
        }
        .environment(store)
        .task { await store.boot() }
    }
}

// MARK: - Onboarding flow

struct OnboardingFlow: View {
    var onFinished: () -> Void
    @Environment(CarlStore.self) private var store
    @State private var step = 0

    var body: some View {
        Group {
            switch step {
            case 0: MeetCarlScreen(onStart: next)
            case 1: InterviewScreen(onContinue: next)
            case 2: ResumeUploadScreen(onContinue: { run { await store.parseResume() } })
            case 3: ReadingResumeScreen(onDone: next)
            case 4: ConfirmScreen(onConfirm: { run { await store.runSearch() } })
            case 5: SearchingScreen(onDone: next)
            case 6: RevealScreen(onUnlock: next)
            default: PaywallScreen(onPurchase: {
                Task { await store.loadQueue(); await store.loadDashboard() }
                onFinished()
            })
            }
        }
        .id(step)
        .transition(.opacity)
    }

    /// Kick off a backend call and advance immediately (the next screen's
    /// animation covers the latency; data is read when it lands).
    private func run(_ work: @escaping () async -> Void) {
        Task { await work() }
        next()
    }
    private func next() { withAnimation(.easeInOut) { step += 1 } }
}

// MARK: - Main tab shell

struct MainTabView: View {
    @Environment(CarlStore.self) private var store
    @State private var tab: CarlTab = .home
    @State private var showDetail = false

    var body: some View {
        ZStack {
            Group {
                switch tab {
                case .home:     DashboardScreen(selectedTab: $tab, onOpenDetail: openDetail)
                case .queue:    QueueScreen(selectedTab: $tab, onOpenDetail: openDetail)
                case .activity: ActivityScreen(selectedTab: $tab, onOpenDetail: openDetail)
                case .profile:  SettingsScreen(selectedTab: $tab)
                }
            }
            if showDetail {
                ApplicationDetailScreen(onBack: { withAnimation(.easeInOut) { showDetail = false } })
                    .transition(.move(edge: .trailing))
                    .zIndex(1)
            }
        }
        .task { await store.loadDashboard(); await store.loadQueue() }
    }

    private func openDetail() { withAnimation(.easeInOut) { showDetail = true } }
}

// MARK: - Shared functional tab bar

struct CarlTabBar: View {
    @Binding var selected: CarlTab
    var queueBadge: Int = 0

    var body: some View {
        HStack {
            item(.home, "house.fill", "Home")
            Spacer()
            item(.queue, "tray.fill", "Queue", badge: queueBadge > 0 ? "\(queueBadge)" : nil)
            Spacer()
            item(.activity, "chart.line.uptrend.xyaxis", "Activity")
            Spacer()
            item(.profile, "person", "Profile")
        }
        .padding(.horizontal, 30)
        .padding(.top, 12)
        .frame(height: 84, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.94))
        .overlay(alignment: .top) { Rectangle().fill(CarlColor.hairline).frame(height: 1) }
    }

    private func item(_ t: CarlTab, _ icon: String, _ label: String, badge: String? = nil) -> some View {
        let active = selected == t
        return Button {
            selected = t
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 20, weight: .regular))
                    .overlay(alignment: .topTrailing) {
                        if let badge {
                            Text(badge).carl(10, .heavy).foregroundStyle(.white)
                                .padding(.horizontal, 4).frame(minWidth: 16, minHeight: 16)
                                .background(CarlColor.red, in: Capsule())
                                .offset(x: 12, y: -8)
                        }
                    }
                Text(label).carl(10.5, active ? .bold : .semibold)
            }
            .foregroundStyle(active ? CarlColor.royal : CarlColor.textGhost)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Activity tab

struct ActivityScreen: View {
    var selectedTab: Binding<CarlTab> = .constant(.activity)
    var onOpenDetail: () -> Void = {}
    @Environment(CarlStore.self) private var store

    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                Text("Activity").carl(26, .heavy).foregroundStyle(CarlColor.navy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22).padding(.top, 64).padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    let items = store.dashboard?.activity ?? []
                    VStack(spacing: 0) {
                        if items.isEmpty {
                            Text("Nothing yet — confirm a few applications and they'll show up here.")
                                .carl(14, .medium).foregroundStyle(CarlColor.textSoft)
                                .multilineTextAlignment(.center)
                                .padding(.vertical, 40)
                        }
                        ForEach(Array(items.enumerated()), id: \.element.id) { idx, item in
                            Button(action: onOpenDetail) {
                                HStack(spacing: 12) {
                                    Circle().fill(dotColor(item.dot)).frame(width: 8, height: 8)
                                    Text(item.text).carl(13.5, .semibold).foregroundStyle(CarlColor.navy)
                                    Spacer()
                                    Text(item.ts).carl(11.5, .semibold).foregroundStyle(CarlColor.textGhost)
                                    Image(systemName: "chevron.right").font(.system(size: 11, weight: .semibold))
                                        .foregroundStyle(Color(hex: 0xC2C9D6))
                                }
                                .padding(.vertical, 14)
                            }
                            .buttonStyle(.plain)
                            if idx < items.count - 1 { Divider().overlay(CarlColor.hairline) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .carlCardShadow(0.05, radius: 12)
                    .padding(.horizontal, 22)
                    .padding(.bottom, 100)
                }
            }
            .overlay(alignment: .bottom) { CarlTabBar(selected: selectedTab, queueBadge: store.queue.count) }
        }
        .task { await store.loadDashboard() }
    }

    private func dotColor(_ s: String) -> Color {
        switch s { case "green": return CarlColor.green; default: return CarlColor.royal }
    }
}
