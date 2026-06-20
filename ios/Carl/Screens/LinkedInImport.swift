import SwiftUI
import UniformTypeIdentifiers

/// Guided LinkedIn import. LinkedIn doesn't allow apps to read a profile
/// directly, so we walk the user through exporting it (Save to PDF or the data
/// export) and then read that file through the same text pipeline as a résumé.
struct LinkedInImportSheet: View {
    var onText: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showPicker = false
    @State private var processing = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 12) {
                    Text("in").carl(20, .heavy).foregroundStyle(.white)
                        .frame(width: 48, height: 48)
                        .background(CarlColor.royal, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Import from LinkedIn").carl(22, .heavy).foregroundStyle(CarlColor.navy)
                        Text("Carl reads your exported profile").carl(13, .medium).foregroundStyle(CarlColor.textSoft)
                    }
                    Spacer()
                }

                Text("LinkedIn doesn't let apps read your profile directly — so export it once and Carl will pull in your roles and skills.")
                    .carl(15, .medium).foregroundStyle(CarlColor.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: 14) {
                    step(1, "Open your LinkedIn profile.")
                    step(2, "Tap **More → Save to PDF** (fastest) — or Settings → Get a copy of your data → Profile.")
                    step(3, "Come back here and choose the file.")
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(CarlColor.screenBG, in: RoundedRectangle(cornerRadius: 18, style: .continuous))

                Button { showPicker = true } label: {
                    CarlButton(title: "Choose LinkedIn file", systemIcon: "arrow.up.doc")
                }
                .buttonStyle(.plain)

                Text("PDF or CSV. If LinkedIn gave you a .zip, unzip it and pick Profile.csv.")
                    .carl(12.5, .semibold).foregroundStyle(CarlColor.textFaint)
            }
            .padding(24)
        }
        .background(CarlColor.card)
        .presentationDetents([.medium, .large])
        .overlay {
            if processing {
                ZStack {
                    Color.black.opacity(0.06).ignoresSafeArea()
                    VStack(spacing: 12) {
                        ProgressView().tint(CarlColor.royal)
                        Text("Reading your profile…").carl(14, .semibold).foregroundStyle(CarlColor.navy)
                    }
                    .padding(24)
                    .background(CarlColor.card, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .carlCardShadow(0.1, radius: 20)
                }
            }
        }
        .fileImporter(isPresented: $showPicker,
                      allowedContentTypes: [.pdf, .plainText, .text, .commaSeparatedText]) { result in
            if case .success(let url) = result { handle(url) }
        }
    }

    private func handle(_ url: URL) {
        processing = true
        Task {
            let text = await ResumeImport.extractText(from: url)
            processing = false
            if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                dismiss()
            } else {
                onText(text)
            }
        }
    }

    private func step(_ n: Int, _ markdown: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)").carl(14, .heavy).foregroundStyle(.white)
                .frame(width: 26, height: 26).background(CarlColor.navy, in: Circle())
            Text(.init(markdown)).carl(14, .medium).foregroundStyle(CarlColor.navy)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }
}
