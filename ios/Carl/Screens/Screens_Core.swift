import SwiftUI

// MARK: - 13 · Review & apply queue

struct QueueScreen: View {
    var selectedTab: Binding<CarlTab> = .constant(.queue)
    var onOpenDetail: () -> Void = {}
    @Environment(CarlStore.self) private var store
    @State private var showPaywall = false
    @State private var editingItem: QueueItem?

    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                // header
                VStack(spacing: 14) {
                    HStack {
                        Text("Carl's queue").carl(26, .heavy).foregroundStyle(CarlColor.navy)
                        Spacer()
                        HStack(spacing: 6) {
                            Circle().fill(CarlColor.royal).frame(width: 8, height: 8)
                            Text("\(store.credits) credits").carl(13, .heavy).foregroundStyle(CarlColor.royal)
                        }
                        .padding(.horizontal, 13).padding(.vertical, 7)
                        .background(CarlColor.tintFill, in: Capsule())
                        .overlay(Capsule().stroke(Color(hex: 0xD5E1FB), lineWidth: 1))
                    }
                    HStack(spacing: 8) {
                        tab("Ready · \(store.queue.count)", selected: true)
                        tab("Submitted", selected: false)
                        tab("Responses", selected: false)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 13) {
                        if store.queue.isEmpty {
                            if store.loadingQueue { loadingState } else { emptyState }
                        } else {
                            HStack(spacing: 10) {
                                CarlMark(eyes: .happy).frame(width: 30, height: 29)
                                Text("I've prepped \(store.queue.count) applications. Skim them and hit submit — takes 2 minutes.")
                                    .carl(13.5, .bold).foregroundStyle(CarlColor.greenDeep)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            .padding(.horizontal, 14).padding(.vertical, 11)
                            .background(CarlColor.greenBG, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                            ForEach(Array(store.queue.enumerated()), id: \.element.id) { idx, item in
                                if idx == 0 {
                                    expandedCard(item)
                                } else {
                                    collapsedCard(item)
                                        .contentShape(Rectangle())
                                        .onTapGesture(perform: onOpenDetail)
                                }
                            }
                            Button { Task { await store.findMoreJobs() } } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise").font(.system(size: 13, weight: .bold))
                                    Text(store.busy ? "Finding…" : "Find more jobs").carl(14, .bold)
                                }
                                .foregroundStyle(CarlColor.royal)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(CarlColor.hairlineCool, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .disabled(store.busy)
                            .padding(.top, 4)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 190)
                }
                .refreshable { await store.loadQueue() }
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 0) {
                    if !store.queue.isEmpty {
                        Button {
                            if store.credits <= 0 { showPaywall = true }
                            else { Task { await store.confirmAll() } }
                        } label: {
                            CarlButton(title: "Confirm all \(store.queue.count)",
                                       trailingNote: "· uses \(min(store.queue.count, store.credits)) credits",
                                       fill: CarlColor.navy, height: 54, glow: false)
                        }
                        .buttonStyle(.plain)
                        .shadow(color: CarlColor.navy.opacity(0.26), radius: 10, y: 10)
                        .padding(.horizontal, 22).padding(.bottom, 12).padding(.top, 14)
                        .background(alignment: .bottom) {
                            LinearGradient(colors: [CarlColor.screenBG.opacity(0), CarlColor.screenBG],
                                           startPoint: .top, endPoint: .bottom)
                        }
                    }
                    CarlTabBar(selected: selectedTab, queueBadge: store.queue.count)
                }
            }
        }
        .task { await store.loadQueue() }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallScreen(onPurchase: { showPaywall = false })
                .environment(store)
        }
        .sheet(item: $editingItem) { item in
            DraftEditSheet(item: item).environment(store)
        }
    }

    private var loadingState: some View {
        ProgressView().tint(CarlColor.royal)
            .frame(maxWidth: .infinity)
            .padding(.top, 90)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            CarlAvatar(eyes: .happy, showDashes: true).frame(width: 110, height: 104)
            Text("You're all caught up").carl(20, .heavy).foregroundStyle(CarlColor.navy)
            Text("Carl scans for fresh roles automatically — or pull some in right now.")
                .carl(14, .medium).foregroundStyle(CarlColor.textSoft).multilineTextAlignment(.center)
            Button { Task { await store.findMoreJobs() } } label: {
                CarlButton(title: store.busy ? "Finding jobs…" : "Find jobs", systemIcon: "magnifyingglass").frame(width: 220)
            }
            .buttonStyle(.plain)
            .disabled(store.busy)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity).padding(.top, 60)
    }

    private func tab(_ title: String, selected: Bool) -> some View {
        Text(title)
            .carl(13.5, selected ? .bold : .semibold)
            .foregroundStyle(selected ? .white : CarlColor.textSoft)
            .padding(.horizontal, 15).padding(.vertical, 9)
            .background(selected ? CarlColor.navy : CarlColor.card,
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(selected ? .clear : CarlColor.hairlineCool, lineWidth: 1))
    }

    private func expandedCard(_ item: QueueItem) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                JobAvatar(letter: item.letter, color: CarlColor.named(item.avatarColor))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).carl(15.5, .bold).foregroundStyle(CarlColor.navy)
                    Text("\(item.company) · \(item.detail)").carl(12.5, .medium).foregroundStyle(CarlColor.textSoft)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 6) {
                    FitBadge(text: "\(item.fit)% fit")
                    ApplyTierBadge(tier: item.tier)
                }
            }
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 12, weight: .semibold)).foregroundStyle(CarlColor.royal)
                Text("Why Carl picked this: \(item.reasons.first ?? "strong fit").")
                    .carl(12, .semibold).foregroundStyle(CarlColor.textMuted)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11).padding(.vertical, 8)
            .background(CarlColor.screenBG, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 9) {
                HStack(spacing: 7) {
                    Image(systemName: "doc.text").font(.system(size: 13, weight: .semibold)).foregroundStyle(CarlColor.royal)
                    Text("Carl drafted your application").carl(13, .heavy).foregroundStyle(CarlColor.navy)
                }
                draftBox(label: "Cover note", text: "\"\(store.draftEdits[item.matchId] ?? item.draft.coverNote)\"")
                if let qa = item.draft.answers.first {
                    draftBox(label: qa.question, text: "\"\(qa.answer)\"")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle().fill(CarlColor.hairlineCool).frame(height: 1)
            }

            tailorRow(item)

            HStack(spacing: 10) {
                Button { editingItem = item } label: {
                    Image(systemName: "pencil").font(.system(size: 16, weight: .semibold)).foregroundStyle(CarlColor.royal)
                        .frame(width: 52, height: 48)
                        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(CarlColor.border, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                Button {
                    let cost = item.tailored == true ? 2 : 1
                    if store.credits < cost { showPaywall = true }
                    else { Task { await store.confirm(item.matchId) } }
                } label: {
                    CarlButton(title: item.tier == "A" ? "Confirm & submit" : "Review & send",
                               trailingNote: item.tailored == true ? "· 2 credits" : "· 1 credit", height: 48, glow: false)
                        .shadow(color: CarlColor.royal.opacity(0.3), radius: 8, y: 8)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
        }
        .padding(16)
        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: 0xD5E1FB), lineWidth: 1.5))
        .carlCardShadow(0.08, radius: 20, y: 6)
        .contextMenu { blockButton(item) }
    }

    @ViewBuilder private func blockButton(_ item: QueueItem) -> some View {
        Button(role: .destructive) {
            Task { await store.block(item.company) }
        } label: {
            Label("Don't apply to \(item.company)", systemImage: "hand.raised.fill")
        }
    }

    /// Premium "tailor my résumé to this job" affordance (+1 credit on submit).
    @ViewBuilder private func tailorRow(_ item: QueueItem) -> some View {
        if item.tailored == true {
            HStack(spacing: 7) {
                Image(systemName: "sparkles").font(.system(size: 13, weight: .semibold)).foregroundStyle(CarlColor.greenDeep)
                Text("Résumé tailored to this job").carl(12.5, .bold).foregroundStyle(CarlColor.greenDeep)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 11).padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(CarlColor.greenBG, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .padding(.top, 10)
        } else {
            Button { Task { await store.tailorResume(item.matchId) } } label: {
                HStack(spacing: 7) {
                    if store.tailoring.contains(item.matchId) {
                        SpinnerRing(size: 14)
                    } else {
                        Image(systemName: "sparkles").font(.system(size: 13, weight: .semibold)).foregroundStyle(CarlColor.royal)
                    }
                    Text("Tailor my résumé to this job").carl(12.5, .bold).foregroundStyle(CarlColor.royal)
                    Spacer(minLength: 0)
                    Text("+1 credit").carl(11, .bold).foregroundStyle(CarlColor.textFaint)
                }
                .padding(.horizontal, 11).padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(CarlColor.tintFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(hex: 0xD5E1FB), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
    }

    private func draftBox(label: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label.uppercased()).carl(11, .bold).foregroundStyle(CarlColor.textFaint).tracking(0.5)
            Text(text).carl(12.5, .regular).foregroundStyle(CarlColor.textBody).lineSpacing(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 13).padding(.vertical, 11)
        .background(CarlColor.tintFillAlt, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }

    private func collapsedCard(_ item: QueueItem) -> some View {
        VStack(spacing: 13) {
            HStack(spacing: 12) {
                JobAvatar(letter: item.letter, color: CarlColor.named(item.avatarColor))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.title).carl(15.5, .bold).foregroundStyle(CarlColor.navy)
                    Text("\(item.company) · \(item.detail)").carl(12.5, .medium).foregroundStyle(CarlColor.textSoft)
                }
                Spacer(minLength: 6)
                VStack(alignment: .trailing, spacing: 6) {
                    FitBadge(text: "\(item.fit)% fit")
                    ApplyTierBadge(tier: item.tier)
                }
            }
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy)).foregroundStyle(CarlColor.green)
                    Text("Application drafted · tap to review").carl(12.5, .semibold).foregroundStyle(CarlColor.textMuted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: 0xC2C9D6))
            }
        }
        .padding(16)
        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .carlCardShadow(0.06)
        .contextMenu { blockButton(item) }
    }
}

// MARK: - 14 · Dashboard / progress

struct DashboardScreen: View {
    var selectedTab: Binding<CarlTab> = .constant(.home)
    var onOpenDetail: () -> Void = {}
    @Environment(CarlStore.self) private var store
    @State private var appliedShown = 0
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(store.firstName.isEmpty ? "Good morning" : "Good morning, \(store.firstName)")
                                    .carl(14, .semibold).foregroundStyle(CarlColor.textFaint)
                                Text("Carl's been busy").carl(22, .heavy).foregroundStyle(CarlColor.navy)
                            }
                            Spacer()
                            CarlMark(eyes: .happy, showHighlight: false)
                                .frame(width: 32, height: 32)
                                .frame(width: 44, height: 44)
                                .background(CarlColor.navy, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        }

                        // hero
                        ZStack(alignment: .topTrailing) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Today").carl(14, .semibold).foregroundStyle(CarlColor.textOnNavySoft)
                                CountUp(value: Double(appliedShown), prefix: "Carl applied to ", suffix: " jobs")
                                    .carlFont(40, .heavy).foregroundStyle(.white)
                                    .padding(.top, 4)
                                    .padding(.trailing, 60) // clear the mascot in the corner
                                    .fixedSize(horizontal: false, vertical: true)
                                    .onAppear {
                                        if let v = store.dashboard?.appliedToday {
                                            withAnimation(.easeOut(duration: 1.3)) { appliedShown = v }
                                        }
                                    }
                                    .onChange(of: store.dashboard?.appliedToday ?? 0) { _, v in
                                        withAnimation(.easeOut(duration: 1.3)) { appliedShown = v }
                                    }
                                Text("Nice work resting while Carl hustled.")
                                    .carl(13.5, .medium).foregroundStyle(CarlColor.textOnNavySoft)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            CarlAvatar(eyes: .happy, showSparkle: true).frame(width: 62, height: 59)
                        }
                        .padding(22)
                        .background(
                            LinearGradient(colors: [CarlColor.royal, CarlColor.navy],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                        .shadow(color: CarlColor.royal.opacity(0.26), radius: 14, y: 12)

                        HStack(spacing: 10) {
                            statCard("\(store.dashboard?.totalApplied ?? 0)", "Applied", CarlColor.navy)
                            statCard("\(store.dashboard?.autoApplied ?? 0)", "Auto-applied", CarlColor.royal)
                            statCard(store.dashboard.map { $0.avgFit > 0 ? "\($0.avgFit)%" : "—" } ?? "—", "Avg fit", CarlColor.green)
                        }

                        HStack {
                            Text("Recent activity").carl(15, .heavy).foregroundStyle(CarlColor.navy)
                            Spacer()
                            Text("See all").carl(13, .bold).foregroundStyle(CarlColor.royal)
                        }

                        let acts = Array((store.dashboard?.activity ?? []).prefix(3))
                        VStack(spacing: 0) {
                            if acts.isEmpty {
                                activityRow(CarlColor.textGhost, "No activity yet — confirm a few to get going", "")
                            }
                            ForEach(Array(acts.enumerated()), id: \.element.id) { idx, a in
                                activityRow(a.dot == "green" ? CarlColor.green : CarlColor.royal, a.text, a.ts)
                                if idx < acts.count - 1 { Divider().overlay(CarlColor.hairline) }
                            }
                        }
                        .padding(.horizontal, 16)
                        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .carlCardShadow(0.05, radius: 12)
                        .contentShape(Rectangle())
                        .onTapGesture(perform: onOpenDetail)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 64)
                    .padding(.bottom, 100)
                    .redacted(reason: store.dashboard == nil ? .placeholder : [])
                }
                .refreshable { await store.loadDashboard() }
            }
            .overlay(alignment: .bottom) { CarlTabBar(selected: selectedTab, queueBadge: store.queue.count) }
        }
        .task { await store.loadDashboard(); await store.loadProfile() }
    }

    private func statCard(_ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).carl(24, .heavy).foregroundStyle(color)
            Text(label).carl(11.5, .semibold).foregroundStyle(CarlColor.textFaint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .carlCardShadow(0.05, radius: 12)
    }

    private func activityRow(_ dot: Color, _ text: String, _ time: String) -> some View {
        HStack(spacing: 12) {
            Circle().fill(dot).frame(width: 8, height: 8)
            Text(text).carl(13.5, .semibold).foregroundStyle(CarlColor.navy)
            Spacer()
            Text(time).carl(11.5, .semibold).foregroundStyle(CarlColor.textGhost)
        }
        .padding(.vertical, 12)
    }
}

// MARK: - 15 · Application detail / tracking

/// Edit the drafted cover note before sending. Saved to the store and applied
/// when the application is confirmed.
struct DraftEditSheet: View {
    let item: QueueItem
    @Environment(CarlStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var text: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 10) {
                Text("\(item.title) · \(item.company)").carl(13, .semibold).foregroundStyle(CarlColor.textSoft)
                TextEditor(text: $text)
                    .carlFont(14, .regular).foregroundStyle(CarlColor.textBody)
                    .scrollContentBackground(.hidden)
                    .padding(12)
                    .background(CarlColor.tintFillAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .frame(minHeight: 240)
                Text("Carl will send exactly this. Edits are saved for this application.")
                    .carl(12, .medium).foregroundStyle(CarlColor.textFaint)
                Spacer()
            }
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(CarlColor.screenBG)
            .navigationTitle("Edit cover note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { store.draftEdits[item.matchId] = text; dismiss() }.bold()
                }
            }
        }
        .onAppear { text = store.draftEdits[item.matchId] ?? item.draft.coverNote }
    }
}

struct ApplicationDetailScreen: View {
    var onBack: () -> Void = {}
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // header card
                    VStack(spacing: 14) {
                        HStack(spacing: 13) {
                            JobAvatar(letter: "N", color: CarlColor.navy, size: 52, corner: 15, fontSize: 20)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Senior Product Designer").carl(17, .heavy).foregroundStyle(CarlColor.navy)
                                Text("Northwind · Remote · $145–170k").carl(13, .medium).foregroundStyle(CarlColor.textSoft)
                            }
                            Spacer(minLength: 0)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill").font(.system(size: 14)).foregroundStyle(CarlColor.green)
                            Text("Applied by Carl").carl(13, .bold).foregroundStyle(CarlColor.greenDeep)
                            Spacer()
                        }
                        .padding(.horizontal, 13).padding(.vertical, 9)
                        .background(CarlColor.greenBG, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .padding(18)
                    .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .carlCardShadow(0.07, radius: 20, y: 6)

                    // what happens next (replies go straight to the user's email)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("What happens next").carl(14, .heavy).foregroundStyle(CarlColor.navy)
                        HStack(spacing: 11) {
                            Image(systemName: "envelope.fill").font(.system(size: 15, weight: .semibold)).foregroundStyle(CarlColor.royal)
                                .frame(width: 34, height: 34)
                                .background(CarlColor.tintFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                            Text("Employers reply directly to your email — watch your inbox for interview requests.")
                                .carl(13, .medium).foregroundStyle(CarlColor.textSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .carlCardShadow(0.07, radius: 20, y: 6)

                    // what carl submitted
                    VStack(spacing: 0) {
                        HStack(spacing: 8) {
                            CarlMark().frame(width: 26, height: 25)
                            Text("What Carl submitted").carl(14, .heavy).foregroundStyle(CarlColor.navy)
                            Spacer()
                        }
                        .padding(.bottom, 14)
                        submittedRow("doc.text", "Cover note")
                        Divider().overlay(CarlColor.hairline)
                        submittedRow("questionmark.circle", "3 screening answers")
                        Divider().overlay(CarlColor.hairline)
                        submittedRow("doc.richtext", "Your résumé")
                    }
                    .padding(18)
                    .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .carlCardShadow(0.07, radius: 20, y: 6)

                    Text("Submitted by Carl · 2 days ago")
                        .carl(13, .semibold).foregroundStyle(CarlColor.textFaint)
                }
                .padding(.horizontal, 22)
                .padding(.top, 96).padding(.bottom, 40)
            }
            .overlay(alignment: .topLeading) {
                Button(action: onBack) {
                    Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundStyle(CarlColor.navy)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.top, 50).padding(.leading, 14)
            }
        }
    }

    private func submittedRow(_ icon: String, _ title: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: icon).font(.system(size: 15, weight: .semibold)).foregroundStyle(CarlColor.royal)
                .frame(width: 34, height: 34)
                .background(CarlColor.tintFill, in: RoundedRectangle(cornerRadius: 9, style: .continuous))
            Text(title).carl(13.5, .bold).foregroundStyle(CarlColor.navy)
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: 0xC2C9D6))
        }
        .padding(.vertical, 12)
    }
}

// MARK: - 16 · Settings / profile

struct SettingsScreen: View {
    var selectedTab: Binding<CarlTab> = .constant(.profile)
    @Environment(CarlStore.self) private var store
    @State private var carlTalks = true
    @State private var showPaywall = false
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.settingsBG
        } content: {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    HStack(spacing: 14) {
                        CarlMark(eyes: .happy, showHighlight: false)
                            .frame(width: 44, height: 44)
                            .frame(width: 60, height: 60)
                            .background(CarlColor.navy, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.displayName).carl(22, .heavy).foregroundStyle(CarlColor.navy)
                            Text(store.roleSummary).carl(13.5, .medium).foregroundStyle(CarlColor.textSoft)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 6)

                    // credits
                    HStack {
                        HStack(spacing: 11) {
                            Circle().fill(CarlColor.royal).frame(width: 9, height: 9)
                                .frame(width: 38, height: 38)
                                .background(CarlColor.tintFill, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                            VStack(alignment: .leading, spacing: 3) {
                                Text("\(store.credits) credits").carl(18, .heavy).foregroundStyle(CarlColor.navy)
                                Text("≈ \(store.credits) applications left").carl(12, .semibold).foregroundStyle(CarlColor.textFaint)
                            }
                        }
                        Spacer()
                        Button { showPaywall = true } label: {
                            Text("Buy more").carl(13.5, .bold).foregroundStyle(.white)
                                .padding(.horizontal, 16).frame(height: 38)
                                .background(CarlColor.royal, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 18).padding(.vertical, 16)
                    .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .carlCardShadow(0.05, radius: 12)

                    settingsGroup("Resume & preferences") {
                        SettingsRow(color: CarlColor.royal, title: "Edit resume")
                        Divider().overlay(CarlColor.hairline).padding(.leading, 58)
                        SettingsRow(color: CarlColor.greenhouse, title: "Job preferences", value: "Design · Remote")
                        Divider().overlay(CarlColor.hairline).padding(.leading, 58)
                        SettingsRow(color: CarlColor.lever, title: "Pay floor", value: "$130k")
                    }

                    settingsGroup("Won't apply to") {
                        if store.blockedCompanies.isEmpty {
                            Text("Long-press a job in the queue to block a company — e.g. your current employer. Carl never applies there.")
                                .carl(13, .medium).foregroundStyle(CarlColor.textSoft)
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16).padding(.vertical, 14)
                        } else {
                            ForEach(Array(store.blockedCompanies.enumerated()), id: \.offset) { idx, company in
                                if idx > 0 { Divider().overlay(CarlColor.hairline).padding(.leading, 58) }
                                HStack(spacing: 12) {
                                    Image(systemName: "hand.raised.fill").font(.system(size: 13, weight: .semibold)).foregroundStyle(CarlColor.red)
                                        .frame(width: 30, height: 30)
                                        .background(CarlColor.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
                                    Text(company).carl(15, .semibold).foregroundStyle(CarlColor.navy)
                                    Spacer()
                                    Button { Task { await store.unblock(company) } } label: {
                                        Image(systemName: "xmark.circle.fill").font(.system(size: 18)).foregroundStyle(CarlColor.textFaint)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 16).padding(.vertical, 12)
                            }
                        }
                    }

                    settingsGroup("Carl") {
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 8).fill(CarlColor.navy).frame(width: 30, height: 30)
                            Text("Carl talks to me").carl(15, .semibold).foregroundStyle(CarlColor.navy)
                            Spacer()
                            Toggle("", isOn: $carlTalks).labelsHidden().tint(CarlColor.royal)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        Divider().overlay(CarlColor.hairline).padding(.leading, 58)
                        SettingsRow(color: CarlColor.royal, title: "Daily apply limit", value: "50 / day")
                    }

                    settingsGroup("Account") {
                        SettingsRow(color: CarlColor.ashby, title: "Notifications")
                        Divider().overlay(CarlColor.hairline).padding(.leading, 58)
                        SettingsRow(color: CarlColor.slate, title: "Privacy & data")
                        Divider().overlay(CarlColor.hairline).padding(.leading, 58)
                        SettingsRow(color: CarlColor.red, title: "Purchase history", titleColor: CarlColor.red)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 74).padding(.bottom, 100)
            }
            .overlay(alignment: .bottom) { CarlTabBar(selected: selectedTab, queueBadge: store.queue.count) }
        }
        .task { await store.refreshCredits(); await store.loadProfile() }
        .fullScreenCover(isPresented: $showPaywall) {
            PaywallScreen(onPurchase: { showPaywall = false })
                .environment(store)
        }
    }

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased()).carl(12, .bold).foregroundStyle(CarlColor.textFaint).tracking(0.6)
                .padding(.leading, 10)
            VStack(spacing: 0) { content() }
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .carlCardShadow(0.05, radius: 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsRow: View {
    var color: Color
    var title: String
    var value: String? = nil
    var titleColor: Color = CarlColor.navy
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 8).fill(color).frame(width: 30, height: 30)
            Text(title).carl(15, .semibold).foregroundStyle(titleColor)
            Spacer()
            if let value { Text(value).carl(13, .semibold).foregroundStyle(CarlColor.textFaint) }
            Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Color(hex: 0xC2C9D6))
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}
