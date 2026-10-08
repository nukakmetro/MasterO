import SwiftUI

struct TemplateManagerView: View {
    @Bindable var viewModel: ApplicationViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var editingTemplate: ChecklistTemplate?
    @State private var showingEditor = false
    @State private var showingImporter = false
    @State private var showingExporter = false
    @State private var exportDocument = TemplateJSONDocument(data: Data())
    @State private var exportFileName = "CheckTuk-шаблоны"
    @State private var fileFeedback: String?

    private var palette: MasterOPalette { MasterOPalette(isDark: colorScheme == .dark) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("БИБЛИОТЕКА")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.4)
                        .foregroundStyle(.tint)
                    Text("Шаблоны чеклистов")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                    Text("Соберите типовые списки и используйте их для новых приложений.")
                        .font(.system(size: 11))
                        .foregroundStyle(palette.secondaryText)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(palette.secondaryText)
                        .frame(width: 30, height: 30)
                        .background(palette.insetSurface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Закрыть")
            }

            if viewModel.templates.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 25, weight: .light))
                        .foregroundStyle(.tint)
                    Text("Шаблонов пока нет")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(palette.primaryText)
                    Text("Создайте первый набор пунктов для будущих приложений.")
                        .font(.system(size: 11))
                        .foregroundStyle(palette.secondaryText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(palette.border, lineWidth: 1))
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(viewModel.templates) { template in
                            templateCard(template)
                        }
                    }
                }
            }

            HStack(spacing: 8) {
                Text("\(viewModel.templates.count) шаблонов")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                Spacer()
                Button { showingImporter = true } label: {
                    Label("Импорт", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(TemplateQuietButtonStyle(palette: palette))
                Button {
                    beginExport(viewModel.templates, fileName: "CheckTuk-шаблоны")
                } label: {
                    Label("Экспорт", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(TemplateQuietButtonStyle(palette: palette))
                Button {
                    editingTemplate = nil
                    showingEditor = true
                } label: {
                    Label("Новый шаблон", systemImage: "plus")
                }
                .buttonStyle(TemplateAccentButtonStyle())
            }
        }
        .padding(25)
        .frame(width: 680, height: 570)
        .background(palette.canvas)
        .fileImporter(isPresented: $showingImporter, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            guard case .success(let urls) = result, let url = urls.first else {
                if case .failure(let error) = result { fileFeedback = "Не удалось открыть файл: \(error.localizedDescription)" }
                return
            }
            importTemplates(from: url)
        }
        .fileExporter(
            isPresented: $showingExporter,
            document: exportDocument,
            contentType: .json,
            defaultFilename: exportFileName
        ) { result in
            switch result {
            case .success: fileFeedback = "Шаблоны сохранены в JSON-файл."
            case .failure(let error): fileFeedback = "Не удалось экспортировать шаблоны: \(error.localizedDescription)"
            }
        }
        .alert("Обмен шаблонами", isPresented: Binding(
            get: { fileFeedback != nil },
            set: { if !$0 { fileFeedback = nil } }
        )) {
            Button("ОК") { fileFeedback = nil }
        } message: {
            Text(fileFeedback ?? "")
        }
        .sheet(isPresented: $showingEditor, onDismiss: { editingTemplate = nil }) {
            TemplateEditorSheet(template: editingTemplate) { name, drafts in
                let values = drafts.map { (title: $0.title, link: $0.link) }
                viewModel.saveTemplate(name: name, items: values, editing: editingTemplate)
                showingEditor = false
            }
        }
    }

    private func beginExport(_ templates: [ChecklistTemplate], fileName: String) {
        guard !templates.isEmpty else {
            fileFeedback = "Нет шаблонов для экспорта."
            return
        }
        guard let data = viewModel.exportTemplates(templates) else {
            fileFeedback = viewModel.errorMessage ?? "Не удалось подготовить файл экспорта."
            return
        }
        exportDocument = TemplateJSONDocument(data: data)
        exportFileName = fileName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if exportFileName.isEmpty { exportFileName = "CheckTuk-шаблоны" }
        showingExporter = true
    }

    private func importTemplates(from url: URL) {
        let hasAccess = url.startAccessingSecurityScopedResource()
        defer { if hasAccess { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            if let count = viewModel.importTemplates(from: data) {
                fileFeedback = "Импортировано шаблонов: \(count). Совпадающие названия получили пометку «импорт»."
            } else {
                fileFeedback = viewModel.errorMessage ?? "Не удалось импортировать шаблоны."
            }
        } catch {
            fileFeedback = "Не удалось прочитать файл: \(error.localizedDescription)"
        }
    }

    private func templateCard(_ template: ChecklistTemplate) -> some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.accentColor.opacity(0.11))
                Image(systemName: "checklist")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.tint)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.primaryText)
                Text("\(template.items.count) пунктов · создан \(template.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 10))
                    .foregroundStyle(palette.secondaryText)
                if let preview = template.items.sorted(by: { $0.sortOrder < $1.sortOrder }).prefix(2).map(\.title).joined(separator: " · ").nilIfEmpty {
                    Text(preview)
                        .font(.system(size: 9))
                        .foregroundStyle(palette.secondaryText.opacity(0.82))
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 5)
            Button {
                editingTemplate = template
                showingEditor = true
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(palette.secondaryText)
                    .frame(width: 29, height: 29)
                    .background(palette.insetSurface, in: Circle())
            }
            .buttonStyle(.plain)
            .help("Изменить шаблон")

            Menu {
                Button("Изменить", systemImage: "pencil") {
                    editingTemplate = template
                    showingEditor = true
                }
                Button("Экспортировать шаблон", systemImage: "square.and.arrow.up") {
                    beginExport([template], fileName: template.name)
                }
                Button("Удалить шаблон", systemImage: "trash", role: .destructive) {
                    viewModel.deleteTemplate(template)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.secondaryText)
                    .frame(width: 26, height: 29)
            }
            .menuStyle(.borderlessButton)
        }
        .padding(12)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 15, style: .continuous).stroke(palette.border, lineWidth: 1))
    }
}

private struct TemplateEditorSheet: View {
    let template: ChecklistTemplate?
    let onSave: (String, [ChecklistItemDraft]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var name = ""
    @State private var items: [ChecklistItemDraft] = []

    private var palette: MasterOPalette { MasterOPalette(isDark: colorScheme == .dark) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template == nil ? "СОЗДАНИЕ" : "ИЗМЕНЕНИЕ")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.tint)
                    Text(template == nil ? "Новый шаблон" : "Редактировать шаблон")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                    Text("Этот список будет копироваться в новые приложения.")
                        .font(.system(size: 10))
                        .foregroundStyle(palette.secondaryText)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(palette.secondaryText)
                        .frame(width: 28, height: 28)
                        .background(palette.insetSurface, in: Circle())
                }
                .buttonStyle(.plain)
            }

            TextField("Название типа чеклиста", text: $name)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .padding(12)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(palette.border, lineWidth: 1))

            HStack {
                Text("ПУНКТЫ")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.1)
                    .foregroundStyle(palette.secondaryText)
                Spacer()
                Button { items.append(ChecklistItemDraft()) } label: {
                    Label("Добавить пункт", systemImage: "plus")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.tint)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach($items) { $item in
                        HStack(spacing: 10) {
                            Image(systemName: "circle")
                                .font(.system(size: 17))
                                .foregroundStyle(palette.secondaryText)
                            VStack(spacing: 6) {
                                TextField("Название пункта", text: $item.title)
                                    .font(.system(size: 11, weight: .medium))
                                TextField("Ссылка в названии · необязательно", text: $item.link, prompt: Text("https://…"))
                                    .font(.system(size: 9))
                                    .foregroundStyle(palette.secondaryText)
                            }
                            Button { items.removeAll { $0.id == item.id } } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(palette.secondaryText)
                                    .frame(width: 26, height: 26)
                                    .background(palette.insetSurface, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(10)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(palette.border, lineWidth: 1))
                    }
                }
            }

            HStack {
                Spacer()
                Button("Отмена") { dismiss() }
                    .foregroundStyle(palette.secondaryText)
                    .buttonStyle(.plain)
                    .padding(.trailing, 8)
                Button {
                    onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), items.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                } label: {
                    Label("Сохранить шаблон", systemImage: "checkmark")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 13)
                        .padding(.vertical, 8)
                        .background(Color.accentColor, in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 580, height: 570)
        .background(palette.canvas)
        .onAppear {
            guard let template else { return }
            name = template.name
            items = template.items.sorted { $0.sortOrder < $1.sortOrder }.map {
                ChecklistItemDraft(title: $0.title, link: $0.link)
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}

private struct TemplateAccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.8 : 1), in: Capsule())
    }
}

private struct TemplateQuietButtonStyle: ButtonStyle {
    let palette: MasterOPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(palette.primaryText)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(palette.surface.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule())
            .overlay(Capsule().stroke(palette.border, lineWidth: 1))
    }
}
