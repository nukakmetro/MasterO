import AppKit
import SwiftData
import SwiftUI

struct TipsWindowView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Bindable var settings: AppearanceSettingsViewModel
    @State private var viewModel = TipsViewModel()
    @State private var searchText = ""
    @State private var isSelecting = false
    @State private var selectedTipIDs = Set<UUID>()
    @State private var editingTip: TipNote?
    @State private var showingEditor = false
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var showingDeleteConfirmation = false
    @State private var exportDocument = TipJSONDocument(data: Data())
    @State private var exportFileName = "CheckTuk-подсказки"
    @State private var fileFeedback: String?
    @State private var copiedTipID: UUID?

    private var palette: MasterOPalette { MasterOPalette(isDark: colorScheme == .dark) }
    private var visibleTips: [TipNote] {
        searchText.isEmpty ? viewModel.tips : viewModel.tips.filter { $0.text.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Rectangle().fill(palette.border).frame(height: 1)
            if visibleTips.isEmpty { emptyState }
            else {
                ScrollView {
                    LazyVStack(spacing: 8) { ForEach(visibleTips) { tip in tipCard(tip) } }
                        .padding(14)
                }
            }
            footer
        }
        .frame(minWidth: 520, minHeight: 400)
        .background(palette.canvas)
        .task { viewModel.connect(to: modelContext) }
        .sheet(isPresented: $showingEditor, onDismiss: { editingTip = nil }) {
            TipEditorSheet(tip: editingTip, palette: palette) { text in
                viewModel.save(text, editing: editingTip)
                showingEditor = false
            }
        }
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            guard case .success(let urls) = result, let url = urls.first else {
                if case .failure(let error) = result { fileFeedback = "Не удалось открыть файл: \(error.localizedDescription)" }
                return
            }
            importTips(from: url)
        }
        .fileExporter(isPresented: $showingExporter, document: exportDocument, contentType: .json, defaultFilename: exportFileName) { result in
            switch result {
            case .success: fileFeedback = "Подсказки сохранены в JSON-файл."
            case .failure(let error): fileFeedback = "Не удалось экспортировать подсказки: \(error.localizedDescription)"
            }
        }
        .confirmationDialog("Удалить выбранные подсказки?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Удалить \(selectedTipIDs.count)", role: .destructive) {
                viewModel.delete(ids: selectedTipIDs)
                selectedTipIDs.removeAll()
                isSelecting = false
            }
            Button("Отмена", role: .cancel) { }
        } message: {
            Text("Это действие нельзя отменить.")
        }
        .alert("Обмен подсказками", isPresented: Binding(
            get: { fileFeedback != nil || viewModel.errorMessage != nil },
            set: { if !$0 { fileFeedback = nil; viewModel.errorMessage = nil } }
        )) {
            Button("ОК") { fileFeedback = nil; viewModel.errorMessage = nil }
        } message: {
            Text(fileFeedback ?? viewModel.errorMessage ?? "")
        }
        .preferredColorScheme(settings.theme.colorScheme)
        .tint(settings.accentColor)
        .environment(\.font, settings.baseFont)
    }

    private var header: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 11, style: .continuous).fill(settings.accentColor.opacity(0.13))
                Image(systemName: "lightbulb.fill").font(.system(size: 14, weight: .medium)).foregroundStyle(settings.accentColor)
            }
            .frame(width: 35, height: 35)
            VStack(alignment: .leading, spacing: 2) {
                Text("Подсказки").font(.system(size: 18, weight: .bold, design: .rounded)).foregroundStyle(palette.primaryText)
            }
            Spacer(minLength: 2)
            searchField.frame(width: 105)
            Button { showingImporter = true } label: { Image(systemName: "square.and.arrow.down") }
                .buttonStyle(TipsIconButtonStyle(palette: palette)).help("Импортировать подсказки из JSON")
            Button {
                isSelecting.toggle()
                if !isSelecting { selectedTipIDs.removeAll() }
            } label: { Image(systemName: isSelecting ? "xmark" : "checkmark.circle") }
                .buttonStyle(TipsIconButtonStyle(palette: palette)).help(isSelecting ? "Завершить выбор" : "Выбрать подсказки")
            Button { editingTip = nil; showingEditor = true } label: {
                Label("Добавить", systemImage: "plus")
                    .font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
                    .padding(.horizontal, 10).frame(height: 31)
                    .background(settings.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14).padding(.vertical, 12)
    }

    private var searchField: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass").font(.system(size: 11)).foregroundStyle(palette.secondaryText)
            TextField("Найти", text: $searchText).textFieldStyle(.plain).font(.system(size: 11)).foregroundStyle(palette.primaryText)
        }
        .padding(.horizontal, 8).frame(height: 30)
        .background(palette.insetSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(palette.border, lineWidth: 1))
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: searchText.isEmpty ? "text.bubble" : "magnifyingglass")
                .font(.system(size: 27, weight: .light)).foregroundStyle(settings.accentColor)
            Text(searchText.isEmpty ? "Подсказок пока нет" : "Ничего не найдено")
                .font(.system(size: 15, weight: .semibold, design: .rounded)).foregroundStyle(palette.primaryText)
            Text(searchText.isEmpty ? "Добавьте текст, который пригодится при подготовке приложений." : "Попробуйте изменить запрос.")
                .font(.system(size: 11)).foregroundStyle(palette.secondaryText).multilineTextAlignment(.center)
            if searchText.isEmpty {
                Button("Добавить подсказку") { editingTip = nil; showingEditor = true }
                    .font(.system(size: 11, weight: .semibold)).buttonStyle(.plain).foregroundStyle(settings.accentColor).padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity).padding(30)
    }

    private var footer: some View {
        HStack(spacing: 9) {
            if isSelecting {
                Button {
                    let visibleIDs = Set(visibleTips.map(\.id))
                    if visibleIDs.isSubset(of: selectedTipIDs) { selectedTipIDs.subtract(visibleIDs) }
                    else { selectedTipIDs.formUnion(visibleTips.map(\.id)) }
                } label: {
                    Text(Set(visibleTips.map(\.id)).isSubset(of: selectedTipIDs) ? "Снять выбор" : "Выбрать все")
                }
                    .buttonStyle(TipsTextButtonStyle(palette: palette))
                Text("Выбрано: \(selectedTipIDs.count)").font(.system(size: 10, weight: .medium)).foregroundStyle(palette.secondaryText)
                Spacer()
                Button {
                    beginExport(viewModel.tips.filter { selectedTipIDs.contains($0.id) })
                } label: {
                    Label("Экспортировать", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(TipsTextButtonStyle(palette: palette))
                .disabled(selectedTipIDs.isEmpty)
                Button { if !selectedTipIDs.isEmpty { showingDeleteConfirmation = true } } label: {
                    Label("Удалить выбранные", systemImage: "trash")
                }
                .buttonStyle(TipsDangerButtonStyle(isEnabled: !selectedTipIDs.isEmpty)).disabled(selectedTipIDs.isEmpty)
            } else {
                Text("\(viewModel.tips.count) подсказок").font(.system(size: 10, weight: .medium)).foregroundStyle(palette.secondaryText)
                Spacer()
                Button { beginExport(viewModel.tips) } label: { Label("Экспортировать всё", systemImage: "square.and.arrow.up") }
                    .buttonStyle(TipsTextButtonStyle(palette: palette))
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 9).background(palette.surface.opacity(0.75))
        .overlay(alignment: .top) { Rectangle().fill(palette.border).frame(height: 1) }
    }

    private func tipCard(_ tip: TipNote) -> some View {
        let isSelected = selectedTipIDs.contains(tip.id)
        return HStack(alignment: .top, spacing: 13) {
            if isSelecting {
                Button {
                    if isSelected { selectedTipIDs.remove(tip.id) } else { selectedTipIDs.insert(tip.id) }
                } label: {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(isSelected ? settings.accentColor : palette.secondaryText).frame(width: 25, height: 25)
                }
                .buttonStyle(.plain).accessibilityLabel(isSelected ? "Убрать из выбранного" : "Выбрать подсказку")
            }
            VStack(alignment: .leading, spacing: 7) {
                Text(tip.text).font(.system(size: 11)).foregroundStyle(palette.primaryText)
                    .textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 7) {
                    Text(tip.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 9, weight: .medium)).foregroundStyle(palette.secondaryText)
                    Spacer()
                    Button {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(tip.text, forType: .string)
                        copiedTipID = tip.id
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) { if copiedTipID == tip.id { copiedTipID = nil } }
                    } label: { Label(copiedTipID == tip.id ? "Скопировано" : "Копировать", systemImage: copiedTipID == tip.id ? "checkmark" : "doc.on.doc") }
                        .buttonStyle(TipsTextButtonStyle(palette: palette))
                    Button { editingTip = tip; showingEditor = true } label: { Label("Изменить", systemImage: "pencil") }
                        .buttonStyle(TipsTextButtonStyle(palette: palette))
                }
            }
        }
        .padding(10)
        .background(isSelected ? settings.accentColor.opacity(0.08) : palette.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(isSelected ? settings.accentColor.opacity(0.45) : palette.border, lineWidth: 1))
        .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .onTapGesture {
            guard isSelecting else { return }
            if isSelected { selectedTipIDs.remove(tip.id) } else { selectedTipIDs.insert(tip.id) }
        }
    }

    private func beginExport(_ tips: [TipNote]) {
        guard !tips.isEmpty else { fileFeedback = "Нет подсказок для экспорта."; return }
        guard let data = viewModel.exportTips(tips) else { fileFeedback = viewModel.errorMessage ?? "Не удалось подготовить файл экспорта."; return }
        exportDocument = TipJSONDocument(data: data)
        exportFileName = "CheckTuk-подсказки"
        showingExporter = true
    }

    private func importTips(from url: URL) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            if let count = viewModel.importTips(from: data) {
                selectedTipIDs.removeAll(); isSelecting = false
                fileFeedback = "Добавлено подсказок: \(count). Импортированные тексты добавлены к существующим."
            } else { fileFeedback = viewModel.errorMessage ?? "Не удалось импортировать подсказки." }
        } catch { fileFeedback = "Не удалось прочитать файл: \(error.localizedDescription)" }
    }
}

private struct TipEditorSheet: View {
    let tip: TipNote?
    let palette: MasterOPalette
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var text: String

    init(tip: TipNote?, palette: MasterOPalette, onSave: @escaping (String) -> Void) {
        self.tip = tip; self.palette = palette; self.onSave = onSave
        _text = State(initialValue: tip?.text ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text(tip == nil ? "Новая подсказка" : "Редактирование подсказки")
                    .font(.system(size: 20, weight: .bold, design: .rounded)).foregroundStyle(palette.primaryText)
                Text("Введите текст, который можно будет быстро скопировать.")
                    .font(.system(size: 11)).foregroundStyle(palette.secondaryText)
            }
            TextEditor(text: $text).font(.system(size: 12)).scrollContentBackground(.hidden).padding(9)
                .background(palette.insetSurface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(palette.border, lineWidth: 1))
            HStack {
                Button("Отмена") { dismiss() }.buttonStyle(TipsTextButtonStyle(palette: palette))
                Spacer()
                Button("Сохранить") { onSave(text) }.buttonStyle(TipsAccentButtonStyle())
                    .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(18).frame(width: 480, height: 340).background(palette.canvas)
    }
}

private struct TipsIconButtonStyle: ButtonStyle {
    let palette: MasterOPalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 12, weight: .semibold)).foregroundStyle(palette.secondaryText)
            .frame(width: 33, height: 33)
            .background(configuration.isPressed ? palette.border : palette.insetSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(palette.border, lineWidth: 1))
    }
}

private struct TipsTextButtonStyle: ButtonStyle {
    let palette: MasterOPalette
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 10, weight: .semibold)).foregroundStyle(palette.secondaryText)
            .padding(.horizontal, 9).padding(.vertical, 6)
            .background(configuration.isPressed ? palette.border : palette.insetSurface, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

private struct TipsAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 11, weight: .semibold)).foregroundStyle(.white)
            .padding(.horizontal, 14).padding(.vertical, 8)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
    }
}

private struct TipsDangerButtonStyle: ButtonStyle {
    let isEnabled: Bool
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.system(size: 10, weight: .semibold)).foregroundStyle(isEnabled ? .white : .secondary)
            .padding(.horizontal, 11).padding(.vertical, 7)
            .background(isEnabled ? Color.red.opacity(configuration.isPressed ? 0.72 : 0.88) : Color.gray.opacity(0.14), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
