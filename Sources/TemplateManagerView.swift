import SwiftUI

struct TemplateManagerView: View {
    @Bindable var viewModel: ApplicationViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var editingTemplate: ChecklistTemplate?
    @State private var showingEditor = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.templates.isEmpty {
                    ContentUnavailableView("Нет шаблонов", systemImage: "square.grid.2x2", description: Text("Создайте шаблон, чтобы быстро добавлять стандартный чеклист приложению."))
                } else {
                    List {
                        ForEach(viewModel.templates) { template in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(template.name).font(.headline)
                                    Text("\(template.items.count) \(template.items.count == 1 ? "пункт" : "пунктов")")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Изменить") {
                                    editingTemplate = template
                                    showingEditor = true
                                }
                                .buttonStyle(.borderless)
                                Menu {
                                    Button("Изменить", systemImage: "pencil") {
                                        editingTemplate = template
                                        showingEditor = true
                                    }
                                    Button("Удалить шаблон", systemImage: "trash", role: .destructive) {
                                        viewModel.deleteTemplate(template)
                                    }
                                } label: {
                                    Image(systemName: "ellipsis")
                                }
                                .menuStyle(.borderlessButton)
                            }
                            .padding(.vertical, 5)
                        }
                    }
                    .listStyle(.inset)
                }
            }
            .navigationTitle("Шаблоны чеклистов")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Готово") { dismiss() }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        editingTemplate = nil
                        showingEditor = true
                    } label: {
                        Label("Новый шаблон", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor, onDismiss: { editingTemplate = nil }) {
                TemplateEditorSheet(template: editingTemplate) { name, drafts in
                    let values = drafts.map { (title: $0.title, link: $0.link) }
                    viewModel.saveTemplate(name: name, items: values, editing: editingTemplate)
                    showingEditor = false
                }
            }
        }
        .frame(minWidth: 560, minHeight: 420)
    }
}

private struct TemplateEditorSheet: View {
    let template: ChecklistTemplate?
    let onSave: (String, [ChecklistItemDraft]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var items: [ChecklistItemDraft] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(template == nil ? "Новый шаблон" : "Изменить шаблон")
                .font(.title2.weight(.semibold))
            TextField("Название типа чеклиста", text: $name)
                .textFieldStyle(.roundedBorder)
            HStack {
                Text("Пункты")
                    .font(.headline)
                Spacer()
                Button { items.append(ChecklistItemDraft()) } label: {
                    Label("Добавить пункт", systemImage: "plus")
                }
            }
            if items.isEmpty {
                ContentUnavailableView("Добавьте пункты", systemImage: "list.bullet", description: Text("Пункты этого шаблона будут копироваться в новые приложения."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 9) {
                        ForEach($items) { $item in
                            HStack(spacing: 9) {
                                VStack(spacing: 6) {
                                    TextField("Название пункта", text: $item.title)
                                    TextField("Ссылка в названии (необязательно)", text: $item.link, prompt: Text("https://…"))
                                        .font(.caption)
                                }
                                Button(role: .destructive) {
                                    items.removeAll { $0.id == item.id }
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.borderless)
                            }
                            .padding(10)
                            .background(.background, in: RoundedRectangle(cornerRadius: 9))
                            .overlay(RoundedRectangle(cornerRadius: 9).strokeBorder(.quaternary, lineWidth: 1))
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
            HStack {
                Spacer()
                Button("Отмена", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Сохранить") {
                    onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), items.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 580, height: 540)
        .onAppear {
            guard let template else { return }
            name = template.name
            items = template.items.sorted { $0.sortOrder < $1.sortOrder }.map {
                ChecklistItemDraft(title: $0.title, link: $0.link)
            }
        }
    }
}
