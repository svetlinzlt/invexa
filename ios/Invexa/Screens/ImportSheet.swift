import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import InvexaCore

/// Внасяне на банково извлечение от файл.
///
/// Работи с всяка банка на света и не струва нищо — това е резервният път,
/// докато автоматичното изтегляне през PSD2 не е готово.
struct ImportSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var existing: [StoredFlow]
    @Query(sort: \StoredCategoryRule.createdAt) private var learned: [StoredCategoryRule]

    @State private var isPickingFile = false
    @State private var report: ImportReport?
    @State private var chosen: Set<UUID> = []
    @State private var failure: String?

    var body: some View {
        VStack(spacing: 14) {
            Capsule()
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 4)

            CapLabel("Внасяне от файл")

            if let report {
                preview(report)
            } else {
                intro
            }
        }
        .padding(18)
        .frostedPanel(cornerRadius: 32)
        .padding(10)
        .fileImporter(
            isPresented: $isPickingFile,
            allowedContentTypes: [.commaSeparatedText, .plainText, .text],
            allowsMultipleSelection: false
        ) { result in
            load(result)
        }
    }

    private var intro: some View {
        VStack(spacing: 14) {
            Text("Избери CSV файл от банката си")
                .font(.ui(15, weight: .semibold))
                .foregroundStyle(Palette.text)

            Text("Разчитат се дата, сума и описание. Ще видиш какво е намерено, преди нещо да се запише.")
                .font(.ui(12.5))
                .foregroundStyle(Palette.textDim)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)

            if let failure {
                Text(failure)
                    .font(.ui(12))
                    .foregroundStyle(Palette.violetLift)
                    .multilineTextAlignment(.center)
            }

            Button("Избери файл") { isPickingFile = true }
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.vertical, 20)
    }

    private func preview(_ report: ImportReport) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("Намерени \(report.candidates.count)")
                    .font(.ui(14, weight: .semibold))
                    .foregroundStyle(Palette.text)
                Spacer()
                Button(chosen.count == selectable(report).count ? "Никой" : "Всички") {
                    toggleAll(report)
                }
                .font(.ui(12))
                .foregroundStyle(Palette.violet)
            }

            if !report.skipped.isEmpty {
                Text("\(report.skipped.count) реда са пропуснати: \(reasons(report))")
                    .font(.ui(11))
                    .foregroundStyle(Palette.textFaint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(report.candidates) { candidate in
                        row(candidate)
                        Divider().background(Palette.hairline)
                    }
                }
            }
            .frame(maxHeight: 240)
            .scrollIndicators(.hidden)

            Button("Запиши избраните (\(chosen.count))") { save(report) }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(chosen.isEmpty)
                .opacity(chosen.isEmpty ? 0.5 : 1)
        }
    }

    private func row(_ candidate: ImportCandidate) -> some View {
        let duplicate = isDuplicate(candidate)
        let isOn = chosen.contains(candidate.id)

        return Button {
            if isOn { chosen.remove(candidate.id) } else { chosen.insert(candidate.id) }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isOn ? Palette.violet : Palette.textFaint)

                VStack(alignment: .leading, spacing: 1) {
                    Text(candidate.merchant)
                        .font(.ui(12, weight: .medium))
                        .foregroundStyle(Palette.text)
                        .lineLimit(1)
                    Text(subtitle(candidate, duplicate: duplicate))
                        .font(.ui(9.5))
                        .foregroundStyle(duplicate ? Palette.brass : Palette.textFaint)
                }

                Spacer(minLength: 6)

                Text(candidate.amount.formatted())
                    .font(.ledger(11.5))
                    .foregroundStyle(candidate.kind == .income ? Palette.mint : Palette.text)
            }
            .padding(.vertical, 9)
        }
        .buttonStyle(.plain)
    }

    private func subtitle(_ candidate: ImportCandidate, duplicate: Bool) -> String {
        let date = candidate.date.formatted(
            .dateTime.day().month(.abbreviated).locale(Locale(identifier: "bg_BG"))
        )
        let category = candidate.kind == .expense
            ? SpendingCategory.named(candidate.suggestedCategory)?.name
            : "Приход"

        var parts = [date, category].compactMap { $0 }
        if duplicate { parts.append("вече записан") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Действия

    private var categorizer: Categorizer {
        Categorizer(rules: CategoryRule.starterSet + learned.map(\.asRule))
    }

    /// Двойният внос е най-честата грешка при работа с извлечения — файлът
    /// се сваля отново и се внася втори път. Съвпаденията се показват, но не
    /// се избират сами.
    private func isDuplicate(_ candidate: ImportCandidate) -> Bool {
        existing.contains { candidate.looksLike($0.asFlow()) }
    }

    private func selectable(_ report: ImportReport) -> [ImportCandidate] {
        report.candidates.filter { !isDuplicate($0) }
    }

    private func toggleAll(_ report: ImportReport) {
        let all = selectable(report)
        chosen = chosen.count == all.count ? [] : Set(all.map(\.id))
    }

    private func reasons(_ report: ImportReport) -> String {
        Set(report.skipped.map(\.reason.text)).sorted().joined(separator: ", ").lowercased()
    }

    private func load(_ result: Result<[URL], Error>) {
        failure = nil
        do {
            guard let url = try result.get().first else { return }

            // Файлът идва отвън и достъпът трябва да се поиска изрично.
            guard url.startAccessingSecurityScopedResource() else {
                failure = "Няма достъп до файла. Опитай да го копираш във Файлове и избери оттам."
                return
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let data = try Data(contentsOf: url)
            // Извлеченията невинаги са в UTF-8; кирилицата от по-стари
            // системи идва в Windows-1251.
            let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .windowsCP1251)
                ?? String(decoding: data, as: UTF8.self)

            let parsed = StatementImporter.read(csv: text, categorizer: categorizer)
            guard !parsed.candidates.isEmpty else {
                failure = "Във файла няма разчетими редове. Провери дали има колони за дата, сума и описание."
                return
            }

            report = parsed
            chosen = Set(selectable(parsed).map(\.id))
        } catch {
            failure = "Файлът не се отвори: \(error.localizedDescription)"
        }
    }

    private func save(_ report: ImportReport) {
        for candidate in report.candidates where chosen.contains(candidate.id) {
            context.insert(StoredFlow(candidate.asFlow()))
        }
        InvexaStore.refreshWidgets()
        dismiss()
    }
}

extension String.Encoding {
    static let windowsCP1251 = String.Encoding(
        rawValue: CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.windowsCyrillic.rawValue)
        )
    )
}
