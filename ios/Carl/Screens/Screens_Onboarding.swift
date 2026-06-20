import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

// MARK: - 01 · Meet Carl

struct MeetCarlScreen: View {
    var onStart: () -> Void = {}
    var onDemo: (() -> Void)? = nil
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
                        if let onDemo {
                            Button(action: onDemo) {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.circle.fill").font(.system(size: 14, weight: .semibold))
                                    Text("Preview a demo").carl(14, .bold)
                                }
                                .foregroundStyle(.white.opacity(0.85))
                            }
                            .buttonStyle(.plain)
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
    @Environment(CarlStore.self) private var store

    private struct Msg: Identifiable { let id = UUID(); let text: String; let mine: Bool }
    private enum Field { case work, location, area, pay, jobType }
    private struct Question { let field: Field; let prompt: String; let chips: [String]; let placeholder: String? }

    private let questions: [Question] = [
        Question(field: .work, prompt: "What kind of work are you after?", chips: [], placeholder: "e.g. Product Designer"),
        Question(field: .location, prompt: "Where do you want to work?", chips: ["Remote", "Hybrid", "On-site", "Open to relocating"], placeholder: nil),
        Question(field: .area, prompt: "Which city or area?", chips: ["Remote — anywhere"], placeholder: "e.g. Toronto"),
        Question(field: .pay, prompt: "What pay are you aiming for?", chips: ["$80k+", "$100k+", "$130k+", "$160k+", "$200k+"], placeholder: nil),
        Question(field: .jobType, prompt: "And the job type?", chips: ["Full-time", "Part-time", "Contract"], placeholder: nil),
    ]

    @State private var step = 0
    @State private var messages: [Msg] = []
    @State private var draft = ""
    @FocusState private var inputFocused: Bool

    private var current: Question? { step < questions.count ? questions[step] : nil }

    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                // header
                VStack(spacing: 14) {
                    HStack(spacing: 12) {
                        CarlMark().frame(width: 34, height: 34).background(CarlColor.navy, in: Circle())
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Carl").carl(15, .bold).foregroundStyle(CarlColor.navy)
                            Text("Getting to know you").carl(12, .medium).foregroundStyle(CarlColor.textFaint)
                        }
                        Spacer()
                        Text("\(min(step + 1, questions.count)) of \(questions.count)").carl(13, .bold).foregroundStyle(CarlColor.royal)
                    }
                    GeometryReader { geo in
                        Capsule().fill(CarlColor.track)
                            .overlay(alignment: .leading) {
                                Capsule().fill(CarlColor.royal)
                                    .frame(width: geo.size.width * CGFloat(step) / CGFloat(questions.count))
                            }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 22)
                .padding(.top, 64)

                // conversation
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 14) {
                            ForEach(messages) { ChatBubble(text: $0.text, mine: $0.mine) }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 22)
                        .padding(.top, 18)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                // input area for the current question
                if let q = current {
                    inputArea(for: q)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            if messages.isEmpty { messages.append(Msg(text: questions[0].prompt, mine: false)) }
        }
    }

    @ViewBuilder
    private func inputArea(for q: Question) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if !q.chips.isEmpty {
                FlowChips(q.chips) { answer($0) }
            }
            if let placeholder = q.placeholder {
                HStack(spacing: 10) {
                    TextField(placeholder, text: $draft)
                        .carlFont(15, .medium)
                        .foregroundStyle(CarlColor.navy)
                        .focused($inputFocused)
                        .submitLabel(.send)
                        .onSubmit { answer(draft) }
                    Button {
                        answer(draft)
                    } label: {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .bold)).foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(CarlColor.royal, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 18).padding(6)
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(CarlColor.hairline, lineWidth: 1))
                .carlCardShadow(0.08)
                .onAppear { inputFocused = true }
            }
        }
    }

    private func answer(_ raw: String) {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let q = current else { return }
        apply(q.field, value)
        if !value.isEmpty { messages.append(Msg(text: value, mine: true)) }
        draft = ""
        let nextStep = step + 1
        step = nextStep
        if nextStep < questions.count {
            messages.append(Msg(text: questions[nextStep].prompt, mine: false))
        } else {
            Task { await store.savePreferences() }
            onContinue()
        }
    }

    private func apply(_ field: Field, _ value: String) {
        switch field {
        case .work:
            if !value.isEmpty { store.prefs.titles = [value] }
        case .location:
            store.prefs.locationType = ["Remote": "remote", "Hybrid": "hybrid", "On-site": "onsite"][value] ?? "any"
        case .area:
            store.prefs.location = (value.isEmpty || value.hasPrefix("Remote")) ? nil : value
        case .pay:
            let digits = value.filter(\.isNumber)
            if let n = Int(digits) { store.prefs.payFloor = n }
        case .jobType:
            store.prefs.workType = value.lowercased().replacingOccurrences(of: " ", with: "-")
        }
    }
}

/// A simple wrapping row of tappable chips.
private struct FlowChips: View {
    let labels: [String]
    let onTap: (String) -> Void
    init(_ labels: [String], onTap: @escaping (String) -> Void) { self.labels = labels; self.onTap = onTap }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            ForEach(rows(), id: \.self) { row in
                HStack(spacing: 9) {
                    ForEach(row, id: \.self) { label in
                        Button { onTap(label) } label: { Chip(label) }
                            .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    /// Greedy two/three-per-row wrap based on label length.
    private func rows() -> [[String]] {
        var out: [[String]] = []
        var row: [String] = []
        var width = 0
        for label in labels {
            let w = label.count + 6
            if width + w > 34, !row.isEmpty { out.append(row); row = []; width = 0 }
            row.append(label); width += w
        }
        if !row.isEmpty { out.append(row) }
        return out
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
    @Environment(CarlStore.self) private var store
    @State private var showFileImporter = false
    @State private var showLinkedIn = false
    @State private var showBuilder = false
    @State private var photoItem: PhotosPickerItem?
    @State private var processing = false

    var body: some View {
        PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                CarlMessageRow(message: "Last thing — drop your resume so I know your superpowers.")
                    .padding(.bottom, 26)

                // upload dropzone → Files / iCloud document picker
                Button {
                    showFileImporter = true
                } label: {
                    VStack(spacing: 14) {
                        Image(systemName: "arrow.up.to.line")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(CarlColor.royal)
                            .frame(width: 62, height: 62)
                            .background(CarlColor.tintFill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        Text("Upload from Files or iCloud").carl(18, .bold).foregroundStyle(CarlColor.navy)
                        Text("PDF or text file").carl(13, .medium).foregroundStyle(CarlColor.textFaint)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 34).padding(.horizontal, 24)
                    .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [7, 6]))
                            .foregroundStyle(Color(hex: 0xB9C5E0))
                    )
                }
                .buttonStyle(.plain)
                .padding(.bottom, 18)

                VStack(spacing: 12) {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        OptionRow(iconColor: CarlColor.navy, system: "camera",
                                  title: "Take a photo of it", subtitle: "Carl reads paper resumes too")
                    }
                    .buttonStyle(.plain)
                    Button { showLinkedIn = true } label: {
                        OptionRow(iconColor: CarlColor.royal, monogram: "in",
                                  title: "Import from LinkedIn", subtitle: "Export your profile, Carl reads it")
                    }
                    .buttonStyle(.plain)
                }

                Button { showBuilder = true } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles").font(.system(size: 13, weight: .semibold))
                        Text("Don't have a résumé? Create one").carl(14, .bold)
                    }
                    .foregroundStyle(CarlColor.royal)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                }
                .buttonStyle(.plain)

                if store.demo {
                    Button { finish("") } label: {
                        Text("Skip — use a sample résumé (demo)").carl(13, .bold).foregroundStyle(CarlColor.textSoft)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
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
            .overlay {
                if processing {
                    ZStack {
                        Color.black.opacity(0.06).ignoresSafeArea()
                        VStack(spacing: 12) {
                            ProgressView().tint(CarlColor.royal)
                            Text("Reading your file…").carl(14, .semibold).foregroundStyle(CarlColor.navy)
                        }
                        .padding(24)
                        .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .carlCardShadow(0.1, radius: 20)
                    }
                }
            }
        }
        .fileImporter(isPresented: $showFileImporter, allowedContentTypes: [.pdf, .plainText, .text]) { result in
            if case .success(let url) = result { handleFile(url) }
        }
        .onChange(of: photoItem) { _, item in handlePhoto(item) }
        .sheet(isPresented: $showLinkedIn) {
            LinkedInImportSheet(onText: { text in
                showLinkedIn = false
                finish(text)
            })
        }
        .sheet(isPresented: $showBuilder) {
            ResumeBuilderScreen(onDone: { showBuilder = false; onContinue() })
                .environment(store)
        }
    }

    private func handleFile(_ url: URL) {
        processing = true
        Task {
            let text = await ResumeImport.extractText(from: url)
            finish(text)
        }
    }

    private func handlePhoto(_ item: PhotosPickerItem?) {
        guard let item else { return }
        processing = true
        Task {
            var text = ""
            if let data = try? await item.loadTransferable(type: Data.self), let img = UIImage(data: data) {
                text = await ResumeImport.ocr(img)
            }
            finish(text)
        }
    }

    private func finish(_ text: String) {
        processing = false
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        store.resumeText = trimmed.isEmpty ? nil : trimmed
        onContinue()
    }
}

/// Guided "build my résumé from scratch" flow ($14.99 one-time unlock).
struct ResumeBuilderScreen: View {
    var onDone: () -> Void = {}
    @Environment(CarlStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var role = ""
    @State private var years = ""
    @State private var skills = ""
    @State private var experience = ""
    @State private var working = false

    private var canBuild: Bool {
        !role.trimmingCharacters(in: .whitespaces).isEmpty
            && experience.trimmingCharacters(in: .whitespaces).count > 20
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        CarlMark(eyes: .happy).frame(width: 34, height: 34).background(CarlColor.navy, in: Circle())
                        Text("Let's build your résumé").carl(18, .heavy).foregroundStyle(CarlColor.navy)
                    }
                    Text("Tell me about yourself in your own words — I'll turn it into a polished résumé.")
                        .carl(13.5, .medium).foregroundStyle(CarlColor.textSoft).fixedSize(horizontal: false, vertical: true)

                    field("Full name", text: $name)
                    field("Target role (e.g. Product Designer)", text: $role)
                    field("Years of experience", text: $years, keyboard: .numberPad)
                    field("Top skills (comma separated)", text: $skills)

                    Text("YOUR EXPERIENCE").carl(11, .bold).foregroundStyle(CarlColor.textFaint).tracking(0.5).padding(.top, 4)
                    TextEditor(text: $experience)
                        .carlFont(14, .regular).foregroundStyle(CarlColor.textBody)
                        .scrollContentBackground(.hidden)
                        .padding(12).frame(minHeight: 160)
                        .background(CarlColor.tintFillAlt, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    Text("Jobs, what you did, results, education — rough notes are fine.")
                        .carl(12, .medium).foregroundStyle(CarlColor.textFaint)

                    Button {
                        Task {
                            working = true
                            if !store.hasResumeBuilder, await store.buyResumeBuilder() == false { working = false; return }
                            let ok = await store.buildResume(ResumeBuildInput(name: name, role: role, years: years, skills: skills, experience: experience))
                            working = false
                            if ok { onDone() }
                        }
                    } label: {
                        HStack(spacing: 8) {
                            if working { ProgressView().tint(.white) }
                            Text(store.hasResumeBuilder ? "Create my résumé" : "Create my résumé · $14.99").carl(17, .bold)
                        }
                        .foregroundStyle(.white).frame(maxWidth: .infinity).frame(height: 56)
                        .background(canBuild ? CarlColor.royal : CarlColor.textFaint,
                                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canBuild || working)
                    .padding(.top, 6)
                }
                .padding(20)
            }
            .background(CarlColor.screenBG)
            .navigationTitle("Résumé builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
        }
    }

    private func field(_ placeholder: String, text: Binding<String>, keyboard: UIKeyboardType = .default) -> some View {
        TextField(placeholder, text: text)
            .carlFont(15, .semibold).foregroundStyle(CarlColor.navy)
            .keyboardType(keyboard)
            .padding(.horizontal, 14).padding(.vertical, 13)
            .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(CarlColor.border, lineWidth: 1))
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
    @Environment(CarlStore.self) private var store
    var body: some View {
        @Bindable var store = store
        return PhoneFrame(chrome: .dark) {
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
                    detailRow(label: "Target role", value: store.parsed?.targetRole ?? "Senior Product Designer")
                    Divider().overlay(CarlColor.hairline)
                    detailRow(label: "Experience", value: "\(store.parsed?.years ?? 6) years · \(store.parsed?.seniority ?? "Senior")")
                    Divider().overlay(CarlColor.hairline)
                    VStack(alignment: .leading, spacing: 10) {
                        Text("TOP SKILLS").carl(12, .semibold).foregroundStyle(CarlColor.textFaint).tracking(0.5)
                        let skills = store.parsed?.skills ?? ["Figma", "Design Systems", "Prototyping", "UX Research"]
                        HStack(spacing: 8) {
                            ForEach(skills.prefix(3), id: \.self) { SkillTag($0) }
                        }
                        HStack(spacing: 8) {
                            ForEach(Array(skills.dropFirst(3).prefix(2)), id: \.self) { SkillTag($0) }
                            if skills.count > 5 { SkillTag("+\(skills.count - 5) more", muted: true) }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
                }
                .padding(.horizontal, 20)
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .carlCardShadow(0.07, radius: 24, y: 8)
                .padding(.bottom, 14)

                VStack(alignment: .leading, spacing: 11) {
                    Text("HOW EMPLOYERS REACH YOU").carl(12, .semibold)
                        .foregroundStyle(CarlColor.textFaint).tracking(0.5)
                    contactField(icon: "envelope.fill", placeholder: "you@email.com",
                                 text: $store.contact.email, keyboard: .emailAddress)
                    contactField(icon: "phone.fill", placeholder: "Phone (optional)",
                                 text: $store.contact.phone, keyboard: .phonePad)
                    Text("I'll put these on every application, so interview replies come straight to you.")
                        .carl(12, .medium).foregroundStyle(CarlColor.textSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .carlCardShadow(0.06, radius: 18, y: 6)

                Spacer()
                VStack(spacing: 12) {
                    Button(action: { Task { await store.saveContact() }; onConfirm() }) {
                        CarlButton(title: "Yep, that's me — start searching")
                    }
                    .buttonStyle(.plain)
                    .disabled(!store.contact.email.contains("@"))
                    .opacity(store.contact.email.contains("@") ? 1 : 0.5)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 74).padding(.bottom, 40)
        }
    }

    private func contactField(icon: String, placeholder: String,
                              text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CarlColor.royal).frame(width: 22)
            TextField(placeholder, text: text)
                .carlFont(16, .semibold).foregroundStyle(CarlColor.navy)
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(CarlColor.screenBG, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(CarlColor.border, lineWidth: 1))
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

// MARK: 05b · Screening questions

/// Captures the standard application screening answers (work authorization,
/// sponsorship, relocation, salary, notice) so Carl can fill them in for real.
struct EligibilityScreen: View {
    var onContinue: () -> Void = {}
    @Environment(CarlStore.self) private var store
    var body: some View {
        @Bindable var store = store
        return PhoneFrame(chrome: .dark) {
            CarlColor.screenBG
        } content: {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    CarlMark().frame(width: 40, height: 40).background(CarlColor.navy, in: Circle())
                    Text("A few quick questions").carl(20, .heavy).foregroundStyle(CarlColor.navy)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 6)
                Text("Employers ask these on most applications. I'll answer them for you each time.")
                    .carl(14, .medium).foregroundStyle(CarlColor.textSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 18)

                VStack(spacing: 0) {
                    toggleRow("Authorized to work where I'm applying", $store.eligibility.authorized)
                    Divider().overlay(CarlColor.hairline)
                    toggleRow("I need visa sponsorship", $store.eligibility.needsSponsorship)
                    Divider().overlay(CarlColor.hairline)
                    toggleRow("Open to relocating", $store.eligibility.willingToRelocate)
                }
                .padding(.horizontal, 16)
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .carlCardShadow(0.06, radius: 18, y: 6)
                .padding(.bottom, 14)

                VStack(spacing: 12) {
                    fieldRow(icon: "dollarsign.circle.fill", placeholder: "Salary expectation (e.g. $130k+)",
                             text: $store.eligibility.salaryExpectation)
                    fieldRow(icon: "calendar", placeholder: "Notice period (e.g. 2 weeks)",
                             text: $store.eligibility.noticePeriod)
                }
                .padding(16)
                .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .carlCardShadow(0.06, radius: 18, y: 6)

                Spacer()
                Button(action: onContinue) { CarlButton(title: "Looks good — find my jobs") }
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 74).padding(.bottom, 40)
        }
    }

    private func toggleRow(_ label: String, _ value: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Text(label).carl(15, .semibold).foregroundStyle(CarlColor.navy)
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            Toggle("", isOn: value).labelsHidden().tint(CarlColor.royal)
        }
        .padding(.vertical, 14)
    }

    private func fieldRow(icon: String, placeholder: String, text: Binding<String>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold))
                .foregroundStyle(CarlColor.royal).frame(width: 22)
            TextField(placeholder, text: text)
                .carlFont(15, .semibold).foregroundStyle(CarlColor.navy)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
        .background(CarlColor.screenBG, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(CarlColor.border, lineWidth: 1))
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
