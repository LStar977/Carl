import SwiftUI

// MARK: - 13 · Review & apply queue

struct QueueScreen: View {
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
                            Text("102 credits").carl(13, .heavy).foregroundStyle(CarlColor.royal)
                        }
                        .padding(.horizontal, 13).padding(.vertical, 7)
                        .background(CarlColor.tintFill, in: Capsule())
                        .overlay(Capsule().stroke(Color(hex: 0xD5E1FB), lineWidth: 1))
                    }
                    HStack(spacing: 8) {
                        tab("Ready · 14", selected: true)
                        tab("Submitted · 204", selected: false)
                        tab("Responses · 19", selected: false)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)
                .padding(.bottom, 12)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 13) {
                        HStack(spacing: 10) {
                            CarlMark(eyes: .happy).frame(width: 30, height: 29)
                            Text("I've prepped 14 applications. Skim them and hit submit — takes 2 minutes.")
                                .carl(13.5, .bold).foregroundStyle(CarlColor.greenDeep)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 14).padding(.vertical, 11)
                        .background(CarlColor.greenBG, in: RoundedRectangle(cornerRadius: 13, style: .continuous))

                        expandedCard
                        collapsedCard
                        fadedCard
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 110)
                }
            }
            .overlay(alignment: .bottom) {
                CarlButton(title: "Confirm all 14", trailingNote: "· uses 14 credits",
                           fill: CarlColor.navy, height: 54, glow: false)
                    .shadow(color: CarlColor.navy.opacity(0.26), radius: 10, y: 10)
                    .padding(.horizontal, 22).padding(.bottom, 30).padding(.top, 14)
                    .background(alignment: .bottom) {
                        LinearGradient(colors: [CarlColor.screenBG.opacity(0), CarlColor.screenBG],
                                       startPoint: .top, endPoint: .bottom)
                    }
            }
        }
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

    private var expandedCard: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                JobAvatar(letter: "N", color: CarlColor.navy)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Senior Product Designer").carl(15.5, .bold).foregroundStyle(CarlColor.navy)
                    Text("Northwind · Remote · $145–170k").carl(12.5, .medium).foregroundStyle(CarlColor.textSoft)
                }
                Spacer(minLength: 6)
                FitBadge(text: "96% fit")
            }
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass").font(.system(size: 12, weight: .semibold)).foregroundStyle(CarlColor.royal)
                Text("Why Carl picked this: skills + 6 yrs match, pay in range, remote.")
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
                draftBox(label: "Cover note",
                         text: "\"Northwind's systems-led design culture is exactly where I do my best work. Over 6 years I've shipped design systems that…\"")
                draftBox(label: "Why do you want this role?",
                         text: "\"I want to own a design system end-to-end with a team that values craft…\"")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .overlay(alignment: .top) {
                Rectangle().fill(CarlColor.hairlineCool).frame(height: 1)
            }

            HStack(spacing: 10) {
                Image(systemName: "pencil").font(.system(size: 16, weight: .semibold)).foregroundStyle(CarlColor.royal)
                    .frame(width: 52, height: 48)
                    .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(CarlColor.border, lineWidth: 1.5))
                CarlButton(title: "Confirm & submit", trailingNote: "· 1 credit", height: 48, glow: false)
                    .shadow(color: CarlColor.royal.opacity(0.3), radius: 8, y: 8)
            }
            .padding(.top, 14)
        }
        .padding(16)
        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color(hex: 0xD5E1FB), lineWidth: 1.5))
        .carlCardShadow(0.08, radius: 20, y: 6)
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

    private var collapsedCard: some View {
        VStack(spacing: 13) {
            HStack(spacing: 12) {
                JobAvatar(letter: "L", color: CarlColor.greenhouse)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Product Designer").carl(15.5, .bold).foregroundStyle(CarlColor.navy)
                    Text("Lumen Health · SF Hybrid · $130–155k").carl(12.5, .medium).foregroundStyle(CarlColor.textSoft)
                }
                Spacer(minLength: 6)
                FitBadge(text: "94% fit")
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
    }

    private var fadedCard: some View {
        HStack(spacing: 12) {
            JobAvatar(letter: "V", color: CarlColor.lever)
            VStack(alignment: .leading, spacing: 2) {
                Text("Staff Product Designer").carl(15.5, .bold).foregroundStyle(CarlColor.navy)
                Text("Vela Robotics · Austin · $170–200k").carl(12.5, .medium).foregroundStyle(CarlColor.textSoft)
            }
            Spacer(minLength: 6)
        }
        .padding(16)
        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .carlCardShadow(0.06)
        .opacity(0.6)
    }
}

// MARK: - 14 · Dashboard / progress

struct DashboardScreen: View {
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Good morning, Alex").carl(14, .semibold).foregroundStyle(CarlColor.textFaint)
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
                                Text("Carl applied to 47 jobs").carl(44, .heavy).foregroundStyle(.white)
                                    .padding(.top, 4)
                                Text("Nice work resting while Carl hustled.")
                                    .carl(13.5, .medium).foregroundStyle(CarlColor.textOnNavySoft)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            CarlAvatar(eyes: .happy, showSparkle: true).frame(width: 80, height: 76)
                        }
                        .padding(22)
                        .background(
                            LinearGradient(colors: [CarlColor.royal, CarlColor.navy],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
                        )
                        .shadow(color: CarlColor.royal.opacity(0.26), radius: 14, y: 12)

                        HStack(spacing: 10) {
                            statCard("218", "Applied", CarlColor.navy)
                            statCard("19", "Responses", CarlColor.royal)
                            statCard("4", "Interviews", CarlColor.green)
                        }

                        HStack {
                            Text("Recent activity").carl(15, .heavy).foregroundStyle(CarlColor.navy)
                            Spacer()
                            Text("See all").carl(13, .bold).foregroundStyle(CarlColor.royal)
                        }

                        VStack(spacing: 0) {
                            activityRow(CarlColor.green, "Acme replied to your application", "1h")
                            Divider().overlay(CarlColor.hairline)
                            activityRow(CarlColor.royal, "Applied to Senior Designer · Acme", "2h")
                            Divider().overlay(CarlColor.hairline)
                            activityRow(CarlColor.royal, "Applied to Product Designer · Lumen", "2h")
                        }
                        .padding(.horizontal, 16)
                        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .carlCardShadow(0.05, radius: 12)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 64)
                    .padding(.bottom, 100)
                }
            }
            .overlay(alignment: .bottom) { tabBar }
        }
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

    private var tabBar: some View {
        HStack {
            tabItem("house.fill", "Home", active: true)
            Spacer()
            tabItem("tray.fill", "Queue", active: false, badge: "14")
            Spacer()
            tabItem("chart.line.uptrend.xyaxis", "Activity", active: false)
            Spacer()
            tabItem("person", "Profile", active: false)
        }
        .padding(.horizontal, 30)
        .padding(.top, 12)
        .frame(height: 84, alignment: .top)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.94))
        .overlay(alignment: .top) { Rectangle().fill(CarlColor.hairline).frame(height: 1) }
    }

    private func tabItem(_ icon: String, _ label: String, active: Bool, badge: String? = nil) -> some View {
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
}

// MARK: - 15 · Application detail / tracking

struct ApplicationDetailScreen: View {
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
                            Circle().fill(CarlColor.royal).frame(width: 9, height: 9)
                            Text("Viewed by recruiter · 4h ago").carl(13, .bold).foregroundStyle(CarlColor.royal)
                            Spacer()
                        }
                        .padding(.horizontal, 13).padding(.vertical, 9)
                        .background(CarlColor.tintFill, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    }
                    .padding(18)
                    .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .carlCardShadow(0.07, radius: 20, y: 6)

                    // status stepper
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Status").carl(14, .heavy).foregroundStyle(CarlColor.navy)
                        HStack(spacing: 0) {
                            step("Applied", state: .done)
                            connector(filled: true)
                            step("Viewed", state: .current)
                            connector(filled: false)
                            step("Responded", state: .todo)
                            connector(filled: false)
                            step("Interview", state: .todo)
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
                        submittedRow("doc.richtext", "Resume · Alex_Rivera.pdf")
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
                Image(systemName: "chevron.left").font(.system(size: 18, weight: .bold)).foregroundStyle(CarlColor.navy)
                    .padding(.top, 60).padding(.leading, 22)
            }
        }
    }

    private enum StepState { case done, current, todo }

    private func step(_ label: String, state: StepState) -> some View {
        VStack(spacing: 7) {
            Group {
                switch state {
                case .done:
                    Image(systemName: "checkmark").font(.system(size: 12, weight: .heavy)).foregroundStyle(.white)
                        .frame(width: 26, height: 26).background(CarlColor.green, in: Circle())
                case .current:
                    Circle().fill(CarlColor.royal).frame(width: 26, height: 26)
                        .overlay(Circle().fill(.white).frame(width: 8, height: 8))
                        .overlay(Circle().stroke(CarlColor.royal.opacity(0.18), lineWidth: 4).frame(width: 30, height: 30))
                case .todo:
                    Circle().fill(.white).frame(width: 26, height: 26)
                        .overlay(Circle().stroke(CarlColor.track, lineWidth: 2))
                }
            }
            Text(label).carl(10.5, state == .todo ? .semibold : .bold)
                .foregroundStyle(state == .done ? CarlColor.green : state == .current ? CarlColor.royal : CarlColor.textGhost)
        }
        .frame(maxWidth: .infinity)
    }

    private func connector(filled: Bool) -> some View {
        Rectangle().fill(filled ? CarlColor.green : CarlColor.track)
            .frame(width: 18, height: 2)
            .offset(y: -10)
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
    @State private var carlTalks = true
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
                            Text("Alex Rivera").carl(22, .heavy).foregroundStyle(CarlColor.navy)
                            Text("Senior Product Designer · 6 yrs").carl(13.5, .medium).foregroundStyle(CarlColor.textSoft)
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
                                Text("102 credits").carl(18, .heavy).foregroundStyle(CarlColor.navy)
                                Text("≈ 102 applications left").carl(12, .semibold).foregroundStyle(CarlColor.textFaint)
                            }
                        }
                        Spacer()
                        Text("Buy more").carl(13.5, .bold).foregroundStyle(.white)
                            .padding(.horizontal, 16).frame(height: 38)
                            .background(CarlColor.royal, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                .padding(.top, 74).padding(.bottom, 30)
            }
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
