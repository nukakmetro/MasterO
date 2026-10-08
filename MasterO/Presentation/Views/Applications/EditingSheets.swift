import SwiftUI

struct NewApplicationSheet: View {
    let templates: [ChecklistTemplate]
    let onCreate: (String, String, ChecklistTemplate?) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var name = ""
    @State private var link = ""
    @State private var selectedTemplateID: UUID?

    private var palette: MasterOPalette { MasterOPalette(isDark: colorScheme == .dark) }
    private var selectedTemplate: ChecklistTemplate? { templates.first { $0.id == selectedTemplateID } }

    var body: some View {
        VStack(alignment: .leading, spacing: 19) {
            SheetHeading(
                eyebrow: "НОВАЯ ЗАПИСЬ",
                title: "Добавить приложение",
                subtitle: "Создайте рабочую карточку и выберите чеклист.",
                palette: palette
            ) { dismiss() }

            VStack(spacing: 11) {
                EditorTextField(title: "Название приложения", placeholder: "Например, CheckTuk", text: $name, palette: palette)
                EditorTextField(title: "Ссылка приложения", placeholder: "https://…", text: $link, palette: palette)

                HStack(spacing: 12) {
                    Image(systemName: "checklist")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(.tint)
                        .frame(width: 38, height: 38)
                        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Тип чеклиста")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(palette.primaryText)
                        Text("Пункты шаблона скопируются в приложение")
                            .font(.system(size: 9))
                            .foregroundStyle(palette.secondaryText)
                    }
                    Spacer(minLength: 0)
                    Picker("Тип чеклиста", selection: $selectedTemplateID) {
                        Text("Без шаблона").tag(Optional<UUID>.none)
                        ForEach(templates) { template in
                            Text(template.name).tag(Optional(template.id))
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.menu)
                    .fixedSize()
                }
                .padding(12)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(palette.border, lineWidth: 1))
            }

            HStack {
                Button("Отмена") { dismiss() }
                    .buttonStyle(QuietButtonStyle(palette: palette))
                Spacer()
                Button {
                    onCreate(name.trimmingCharacters(in: .whitespacesAndNewlines), link.trimmingCharacters(in: .whitespacesAndNewlines), selectedTemplate)
                } label: {
                    Label("Создать приложение", systemImage: "arrow.right")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(AccentButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(23)
        .frame(width: 540)
        .background(palette.canvas)
    }
}

struct EditApplicationSheet: View {
    let application: ReleaseApplication
    let onSave: (String, String) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var name = ""
    @State private var link = ""

    private var palette: MasterOPalette { MasterOPalette(isDark: colorScheme == .dark) }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            SheetHeading(
                eyebrow: "КАРТОЧКА ПРИЛОЖЕНИЯ",
                title: "Редактирование",
                subtitle: "Название будет вести по указанной ссылке.",
                palette: palette
            ) { dismiss() }

            VStack(spacing: 11) {
                EditorTextField(title: "Название приложения", placeholder: "Название", text: $name, palette: palette)
                EditorTextField(title: "Ссылка приложения", placeholder: "https://…", text: $link, palette: palette)
            }
            HStack {
                Button("Отмена") { dismiss() }
                    .buttonStyle(QuietButtonStyle(palette: palette))
                Spacer()
                Button {
                    onSave(name.trimmingCharacters(in: .whitespacesAndNewlines), link.trimmingCharacters(in: .whitespacesAndNewlines))
                } label: {
                    Label("Сохранить", systemImage: "checkmark")
                }
                .buttonStyle(AccentButtonStyle())
                .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(23)
        .frame(width: 540)
        .background(palette.canvas)
        .onAppear { name = application.name; link = application.link }
    }
}

struct ApplicationChecklistEditor: View {
    let application: ReleaseApplication
    let onSave: ([ChecklistItemDraft]) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @State private var items: [ChecklistItemDraft] = []

    private var palette: MasterOPalette { MasterOPalette(isDark: colorScheme == .dark) }

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(alignment: .top) {
                SheetHeading(
                    eyebrow: application.name.uppercased(),
                    title: "Состав чеклиста",
                    subtitle: "Добавляйте пункты и ссылки для этого приложения.",
                    palette: palette
                ) { dismiss() }
                Spacer()
                Button { items.append(ChecklistItemDraft()) } label: {
                    Label("Добавить", systemImage: "plus")
                }
                .buttonStyle(QuietButtonStyle(palette: palette))
                .padding(.top, 5)
            }

            ScrollView {
                LazyVStack(spacing: 9) {
                    ForEach($items) { $item in
                        HStack(spacing: 11) {
                            Button { item.isChecked.toggle() } label: {
                                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 20))
                                    .foregroundStyle(item.isChecked ? Color.accentColor : palette.secondaryText)
                            }
                            .buttonStyle(.plain)

                            VStack(spacing: 7) {
                                TextField("Название пункта", text: $item.title)
                                    .font(.system(size: 12, weight: .medium))
                                TextField("Ссылка в названии · необязательно", text: $item.link, prompt: Text("https://…"))
                                    .font(.system(size: 10))
                                    .foregroundStyle(palette.secondaryText)
                            }

                            Button(role: .destructive) {
                                items.removeAll { $0.id == item.id }
                            } label: {
                                Image(systemName: "minus")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(palette.secondaryText)
                                    .frame(width: 27, height: 27)
                                    .background(palette.insetSurface, in: Circle())
                            }
                            .buttonStyle(.plain)
                            .help("Удалить пункт")
                        }
                        .padding(12)
                        .background(palette.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(palette.border, lineWidth: 1))
                    }
                }
            }

            HStack {
                Text("\(items.count) пунктов")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                Spacer()
                Button("Отмена") { dismiss() }
                    .buttonStyle(QuietButtonStyle(palette: palette))
                Button {
                    onSave(items.filter { !$0.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty })
                } label: {
                    Label("Сохранить список", systemImage: "checkmark")
                }
                .buttonStyle(AccentButtonStyle())
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 650, height: 580)
        .background(palette.canvas)
        .onAppear {
            items = application.checklistItems.sorted { $0.sortOrder < $1.sortOrder }.map {
                ChecklistItemDraft(id: $0.id, title: $0.title, link: $0.link, isChecked: $0.isChecked)
            }
        }
    }
}

private struct SheetHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let palette: MasterOPalette
    let close: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            VStack(alignment: .leading, spacing: 5) {
                Text(eyebrow)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(.tint)
                    .lineLimit(1)
                Text(title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundStyle(palette.secondaryText)
            }
            Spacer(minLength: 0)
            Button(action: close) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(palette.secondaryText)
                    .frame(width: 28, height: 28)
                    .background(palette.insetSurface, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Закрыть")
        }
    }
}

private struct EditorTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    let palette: MasterOPalette

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(0.9)
                .foregroundStyle(palette.secondaryText)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(palette.primaryText)
        }
        .padding(12)
        .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(palette.border, lineWidth: 1))
    }
}

private struct AccentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(Color.accentColor.opacity(configuration.isPressed ? 0.78 : 1), in: Capsule())
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

private struct QuietButtonStyle: ButtonStyle {
    let palette: MasterOPalette

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(palette.primaryText)
            .padding(.horizontal, 13)
            .padding(.vertical, 9)
            .background(palette.insetSurface.opacity(configuration.isPressed ? 0.75 : 1), in: Capsule())
            .overlay(Capsule().stroke(palette.border, lineWidth: 1))
    }
}
