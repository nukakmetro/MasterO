import SwiftUI

struct NewApplicationSheet: View {
    let templates: [ChecklistTemplate]
    let onCreate: (String, String, ChecklistTemplate?) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var link = ""
    @State private var selectedTemplateID: UUID?

    private var selectedTemplate: ChecklistTemplate? {
        templates.first { $0.id == selectedTemplateID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Новое приложение")
                .font(.title2.weight(.semibold))

            Form {
                TextField("Название", text: $name)
                TextField("Ссылка приложения", text: $link, prompt: Text("https://…"))
                Picker("Тип чеклиста", selection: $selectedTemplateID) {
                    Text("Без шаблона").tag(Optional<UUID>.none)
                    ForEach(templates) { template in
                        Text(template.name).tag(Optional(template.id))
                    }
                }
            }
            .formStyle(.grouped)

            HStack {
                Spacer()
                Button("Отмена", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Создать") { onCreate(name.trimmingCharacters(in: .whitespacesAndNewlines), link.trimmingCharacters(in: .whitespacesAndNewlines), selectedTemplate) }
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 460)
    }
}

struct EditApplicationSheet: View {
    let application: ReleaseApplication
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var link = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Изменить приложение")
                .font(.title2.weight(.semibold))
            Form {
                TextField("Название", text: $name)
                TextField("Ссылка приложения", text: $link, prompt: Text("https://…"))
            }
            .formStyle(.grouped)
            HStack {
                Spacer()
                Button("Отмена", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                Button("Сохранить") {
                    onSave(
                        name.trimmingCharacters(in: .whitespacesAndNewlines),
                        link.trimmingCharacters(in: .whitespacesAndNewlines)
                    )
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 460)
        .onAppear { name = application.name; link = application.link }
    }
}

struct ApplicationChecklistEditor: View {
    let application: ReleaseApplication
    let onSave: ([ChecklistItemDraft]) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var items: [ChecklistItemDraft] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Редактировать чеклист")
                        .font(.title2.weight(.semibold))
                    Text("Изменения относятся только к этому приложению.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button { items.append(ChecklistItemDraft()) } label: {
                    Label("Добавить пункт", systemImage: "plus")
                }
            }

            if items.isEmpty {
                ContentUnavailableView("Нет пунктов", systemImage: "checklist", description: Text("Добавьте первый пункт чеклиста."))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach($items) { $item in
                            HStack(alignment: .center, spacing: 10) {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(item.isChecked ? Color.accentColor : Color.secondary)
                                VStack(spacing: 7) {
                                    TextField("Название пункта", text: $item.title)
                                    TextField("Ссылка в названии (необязательно)", text: $item.link, prompt: Text("https://…"))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Button(role: .destructive) {
                                    items.removeAll { $0.id == item.id }
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.borderless)
                                .help("Удалить пункт")
                            }
                            .padding(12)
                            .background(.background, in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(.quaternary, lineWidth: 1))
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
                    onSave(items.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 620, height: 560)
        .onAppear {
            items = application.checklistItems.sorted { $0.sortOrder < $1.sortOrder }.map {
                ChecklistItemDraft(id: $0.id, title: $0.title, link: $0.link, isChecked: $0.isChecked)
            }
        }
    }
}
