import SwiftUI

// MARK: - 01 · Meet Carl

struct MeetCarlScreen: View {
    var onStart: () -> Void = {}
    var body: some View {
        PhoneFrame(chrome: .light, homeIndicatorLight: true) {
            CarlColor.navy
        } content: {
            ZStack {
                // faint brand bars in the background
                Group {
                    bar(width: 96, opacity: 0.20).offset(x: -150, y: -300)
                    bar(width: 62, opacity: 0.13).offset(x: -120, y: -268)
                    bar(width: 96, opacity: 0.14).offset(x: 160, y: 200)
                }

                VStack(spacing: 0) {
                    Spacer(minLength: 56)
                    VStack(spacing: 26) {
                        CarlAvatar(showDashes: true)
                            .frame(width: 200, height: 190)
                        CarlSpeechCard {
                            Text("Hi, I'm Carl — and I'm going to find you a job.")
                                .carl(21, .bold)
                                .foregroundStyle(CarlColor.navy)
                                .multilineTextAlignment(.center)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: 312)
                        .overlay(alignment: .top) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(.white)
                                .frame(width: 16, height: 16)
                                .rotationEffect(.degrees(45))
                                .offset(y: -7)
                        }
                        Text("Tell me what you want. I'll search, match, and apply — while you do literally anything else.")
                            .carl(15, .medium)
                            .foregroundStyle(.white.opacity(0.72))
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .frame(maxWidth: 300)
                    }
                    .padding(.horizontal, 32)
                    Spacer()
                    VStack(spacing: 16) {
                        Button(action: onStart) { CarlButton(title: "Let's find me a job") }
                            .buttonStyle(.plain)
                        HStack(spacing: 5) {
                            Text("Already with Carl?").carl(14, .medium).foregroundStyle(.white.opacity(0.6))
                            Text("Log in").carl(14, .bold).foregroundStyle(.white)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 42)
                }
            }
        }
    }

    private func bar(width: CGFloat, opacity: Double) -> some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(CarlColor.royal.opacity(opacity))
            .frame(width: width, height: 11)
    }
}

// MARK: - 02 · Carl interviews you

struct InterviewScreen: View {
    var onContinue: () -> Void = {}
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                // header
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        CarlMark()
                            .frame(width: 34, height: 34)
                            .background(CarlColor.navy, in: Circle())
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Carl").carl(15, .bold).foregroundStyle(CarlColor.navy)
                            Text("Getting to know you").carl(12, .medium).foregroundStyle(CarlColor.textFaint)
                        }
                        Spacer()
                        Text("3 of 8").carl(13, .bold).foregroundStyle(CarlColor.royal)
                    }
                    GeometryReader { geo in
                        Capsule().fill(CarlColor.track)
                            .overlay(alignment: .leading) {
                                Capsule().fill(CarlColor.royal).frame(width: geo.size.width * 0.38)
                            }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)

                // conversation
                VStack(alignment: .leading, spacing: 14) {
                    ChatBubble(text: "What kind of work are you after?", mine: false)
                    ChatBubble(text: "Product Designer — mid to senior", mine: true)
                    ChatBubble(text: "Love it — great field right now. Where do you want to work?", mine: false)
                    VStack(alignment: .leading, spacing: 9) {
                        HStack(spacing: 9) {
                            Chip("Remote", selected: true)
                            Chip("Hybrid")
                            Chip("On-site")
                        }
                        Chip("Open to relocating")
                    }
                    .padding(.top, 2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 22)
                .padding(.top, 18)

                Spacer()

                // input bar
                HStack(spacing: 10) {
                    Text("Or type your own…").carl(15, .medium).foregroundStyle(CarlColor.textGhost)
                    Spacer()
                    Image(systemName: "arrow.right")
                        .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(CarlColor.royal, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                }
                .padding(.leading, 18).padding(6)
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(CarlColor.hairline, lineWidth: 1))
                .carlCardShadow(0.08)
                .contentShape(Rectangle())
                .onTapGesture(perform: onContinue)
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
    }
}

private struct ChatBubble: View {
    var text: String
    var mine: Bool
    var body: some View {
        Text(text)
            .carl(15, mine ? .semibold : .medium)
            .foregroundStyle(mine ? .white : CarlColor.navy)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16).padding(.vertical, 13)
            .background(
                UnevenRoundedRectangle(
                    topLeadingRadius: 20,
                    bottomLeadingRadius: mine ? 20 : 6,
                    bottomTrailingRadius: mine ? 6 : 20,
                    topTrailingRadius: 20, style: .continuous
                )
                .fill(mine ? CarlColor.royal : CarlColor.card)
            )
            .shadow(color: mine ? .clear : CarlColor.navy.opacity(0.06), radius: 6, y: 3)
            .frame(maxWidth: 300, alignment: mine ? .trailing : .leading)
            .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
    }
}

private struct Chip: View {
    var label: String
    var selected: Bool = false
    init(_ label: String, selected: Bool = false) { self.label = label; self.selected = selected }
    var body: some View {
        Text(label)
            .carl(14, selected ? .bold : .semibold)
            .foregroundStyle(selected ? .white : CarlColor.navy)
            .padding(.horizontal, 15).padding(.vertical, 11)
            .background(selected ? CarlColor.royal : CarlColor.card,
                        in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 13)
                    .stroke(selected ? Color.clear : CarlColor.border, lineWidth: 1.5)
            )
            .shadow(color: selected ? CarlColor.royal.opacity(0.28) : .clear, radius: 6, y: 4)
    }
}

// MARK: - 03 · Resume upload

struct ResumeUploadScreen: View {
    var onContinue: () -> Void = {}
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                CarlMessageRow(message: "Last thing — drop your resume so I know your superpowers.")
                    .padding(.bottom, 26)

                // upload dropzone
                VStack(spacing: 14) {
                    Image(systemName: "arrow.up.to.line")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(CarlColor.royal)
                        .frame(width: 62, height: 62)
                        .background(CarlColor.tintFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    Text("Upload from Files or iCloud").carl(18, .bold).foregroundStyle(CarlColor.navy)
                    Text("PDF, DOC, or a clear photo").carl(13, .medium).foregroundStyle(CarlColor.textFaint)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34).padding(.horizontal, 24)
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [7, 6]))
                        .foregroundStyle(Color(hex: 0xB9C5E0))
                )
                .contentShape(Rectangle())
                .onTapGesture(perform: onContinue)
                .padding(.bottom, 18)

                VStack(spacing: 12) {
                    OptionRow(iconColor: CarlColor.navy, system: "camera",
                              title: "Take a photo of it", subtitle: "Carl reads paper resumes too")
                        .onTapGesture(perform: onContinue)
                    OptionRow(iconColor: CarlColor.royal, monogram: "in",
                              title: "Import from LinkedIn", subtitle: "Pull your profile in one tap")
                        .onTapGesture(perform: onContinue)
                }

                Spacer()
                HStack(spacing: 7) {
                    Image(systemName: "lock.fill").font(.system(size: 12))
                    Text("Your resume stays private. Carl never shares it.")
                        .carl(13, .semibold)
                }
                .foregroundStyle(CarlColor.textFaint)
            }
            .padding(.horizontal, 24)
            .padding(.top, 78).padding(.bottom, 40)
        }
    }
}

private struct OptionRow: View {
    var iconColor: Color
    var system: String? = nil
    var monogram: String? = nil
    var title: String
    var subtitle: String
    var body: some View {
        HStack(spacing: 14) {
            Group {
                if let monogram {
                    Text(monogram).carl(18, .heavy).foregroundStyle(.white)
                } else if let system {
                    Image(systemName: system).font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                }
            }
            .frame(width: 40, height: 40)
            .background(iconColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).carl(15, .bold).foregroundStyle(CarlColor.navy)
                Text(subtitle).carl(12, .medium).foregroundStyle(CarlColor.textFaint)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color(hex: 0xC2C9D6))
        }
        .padding(16)
        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .carlCardShadow(0.05, radius: 10, y: 2)
    }
}

// MARK: - 04 · Carl reads your resume

struct ReadingResumeScreen: View {
    var onDone: () -> Void = {}
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 30) {
                CarlAvatar(eyes: .open, showDashes: true, scans: true, rings: true)
                    .frame(width: 150, height: 142)
                VStack(spacing: 10) {
                    Text("Carl is reading your resume…")
                        .carl(22, .heavy).foregroundStyle(CarlColor.navy)
                        .multilineTextAlignment(.center)
                    Text("Spotting your strengths and best-fit roles")
                        .carl(15, .medium).foregroundStyle(CarlColor.textSoft)
                }
                VStack(alignment: .leading, spacing: 13) {
                    ShimmerLine(widthFraction: 0.62)
                    ShimmerLine(widthFraction: 0.90, delay: 0.2)
                    ShimmerLine(widthFraction: 0.78, delay: 0.4)
                    ShimmerLine(widthFraction: 0.84, delay: 0.6)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .carlCardShadow(0.08, radius: 24, y: 8)
            }
            .padding(.horizontal, 36)
            .frame(maxHeight: .infinity)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) { onDone() }
            }
        }
    }
}

private struct ShimmerLine: View {
    var widthFraction: CGFloat
    var delay: Double = 0
    @State private var on = false
    var body: some View {
        GeometryReader { geo in
            Capsule()
                .fill(Color(hex: 0xDCE6FB))
                .frame(width: geo.size.width * widthFraction, height: 11)
                .opacity(on ? 1 : 0.45)
                .animation(.easeInOut(duration: 0.7).repeatForever().delay(delay), value: on)
        }
        .frame(height: 11)
        .onAppear { on = true }
    }
}

// MARK: - 05 · Confirm what Carl learned

struct ConfirmScreen: View {
    var onConfirm: () -> Void = {}
    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    CarlMark().frame(width: 40, height: 40).background(CarlColor.navy, in: Circle())
                    Text("Here's what I picked up").carl(20, .heavy).foregroundStyle(CarlColor.navy)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 20)

                VStack(spacing: 0) {
                    detailRow(label: "Target role", value: "Senior Product Designer")
                    Divider().overlay(CarlColor.hairline)
                    detailRow(label: "Experience", value: "6 years · Senior")
                    Divider().overlay(CarlColor.hairline)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TOP SKILLS").carl(12, .semibold).foregroundStyle(CarlColor.textFaint).tracking(0.5)
                        HStack(spacing: 8) {
                            SkillTag("Figma")
                            SkillTag("Design Systems")
                            SkillTag("Prototyping")
                        }
                        HStack(spacing: 8) {
                            SkillTag("UX Research")
                            SkillTag("+4 more", muted: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 20)
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .carlCardShadow(0.07, radius: 24, y: 8)
                .padding(.bottom, 18)

                HStack(spacing: 9) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 11, weight: .heavy)).foregroundStyle(.white)
                        .frame(width: 22, height: 22).background(CarlColor.green, in: Circle())
                    Text("Looks strong. You can fix anything that's off before I start.")
                        .carl(13, .semibold).foregroundStyle(CarlColor.greenDeep)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16).padding(.vertical, 13)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CarlColor.greenBG, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Spacer()
                VStack(spacing: 12) {
                    Button(action: onConfirm) { CarlButton(title: "Yep, that's me — start searching") }
                        .buttonStyle(.plain)
                    CarlSecondaryButton(title: "Edit details")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 74).padding(.bottom, 40)
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(label.uppercased()).carl(12, .semibold).foregroundStyle(CarlColor.textFaint).tracking(0.5)
                Text(value).carl(17, .bold).foregroundStyle(CarlColor.navy)
            }
            Spacer()
            Image(systemName: "pencil")
                .font(.system(size: 14, weight: .semibold)).foregroundStyle(CarlColor.royal)
                .frame(width: 32, height: 32)
                .background(CarlColor.tintFill, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .padding(.vertical, 16)
    }
}

private struct SkillTag: View {
    var text: String
    var muted: Bool
    init(_ text: String, muted: Bool = false) { self.text = text; self.muted = muted }
    var body: some View {
        Text(text)
            .carl(13, .bold)
            .foregroundStyle(muted ? CarlColor.textSoft : CarlColor.royal)
            .padding(.horizontal, 13).padding(.vertical, 8)
            .background(muted ? Color(hex: 0xF0F2F7) : CarlColor.tintFill,
                        in: RoundedRectangle(cornerRadius: 11, style: .continuous))
    }
}
