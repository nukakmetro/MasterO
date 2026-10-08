import SwiftUI

struct ApplicationDetailView: View {
    @Bindable var application: ReleaseApplication
    @Bindable var viewModel: ApplicationViewModel
    let palette: MasterOPalette

    @Environment(\.openURL) private var openURL
    @State private var showingChecklistEditor = false
    @State private var showingApplicationEditor = false

    private var sortedItems: [ChecklistEntry] {
        application.checklistItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    private var checkedCount: Int { sortedItems.filter(\.isChecked).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                applicationHeader
                checklistSection
                footerNote
            }
            .frame(maxWidth: 920, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .background(palette.canvas)
        .sheet(isPresented: $showingChecklistEditor) {
            ApplicationChecklistEditor(application: application) { drafts in
                viewModel.updateChecklist(application, drafts: drafts)
                showingChecklistEditor = false
            }
        }
        .sheet(isPresented: $showingApplicationEditor) {
            EditApplicationSheet(application: application) { name, link in
                viewModel.updateApplication(application, name: name, link: link)
                showingApplicationEditor = false
            }
        }
    }

    private var applicationHeader: some View {
        HStack(alignment: .top, spacing: 20) {
            VStack(alignment: .leading, spacing: 13) {
                if let url = application.link.validWebURL {
                    Link(destination: url) {
                        HStack(alignment: .firstTextBaseline, spacing: 10) {
                            Text(application.name.isEmpty ? "Без названия" : application.name)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .tracking(-0.8)
                                .lineLimit(2)
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(palette.secondaryText)
                        }
                        .foregroundStyle(palette.primaryText)
                    }
                    .buttonStyle(.plain)
                    .help("Открыть ссылку приложения")
                } else {
                    Text(application.name.isEmpty ? "Без названия" : application.name)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .tracking(-0.8)
                        .foregroundStyle(palette.primaryText)
                        .lineLimit(2)
                        .textSelection(.enabled)
                }

                HStack(spacing: 8) {
                    MetaChip(title: application.checklistTypeName, icon: "checklist", palette: palette)
                    MetaChip(title: application.createdAt.formatted(date: .abbreviated, time: .omitted), icon: "calendar", palette: palette)
                }
            }
            Spacer(minLength: 0)
            HStack(spacing: 7) {
                Menu {
                    ForEach(ApplicationStatus.allCases) { status in
                        Button {
                            viewModel.setStatus(status, for: application)
                        } label: {
                            Label(status.title, systemImage: application.status == status ? "checkmark.circle.fill" : "circle")
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Circle().fill(application.status.displayColor).frame(width: 8, height: 8)
                        Text(application.status.title)
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(palette.primaryText)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(palette.surface, in: Capsule())
                    .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)

                Menu {
                    Button("Изменить приложение", systemImage: "pencil") { showingApplicationEditor = true }
                    Button("Редактировать чеклист", systemImage: "list.bullet.rectangle.portrait") { showingChecklistEditor = true }
                    Divider()
                    Button("Удалить приложение", systemImage: "trash", role: .destructive) {
                        viewModel.deleteApplication(application)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(palette.secondaryText)
                        .frame(width: 34, height: 34)
                        .background(palette.insetSurface, in: Circle())
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .help("Действия с приложением")
            }
            .padding(.top, 5)
        }
    }

    private var checklistSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Чеклист")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                }
                Spacer()
                Text("\(checkedCount)/\(sortedItems.count)")
                    .font(.system(size: 11, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(checkedCount == sortedItems.count && !sortedItems.isEmpty ? application.status.displayColor : palette.secondaryText)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(palette.insetSurface, in: Capsule())
                Button { showingChecklistEditor = true } label: {
                    Label("Изменить список", systemImage: "slider.horizontal.3")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(palette.primaryText)
                        .padding(.horizontal, 11)
                        .padding(.vertical, 8)
                        .background(palette.surface, in: Capsule())
                        .overlay(Capsule().stroke(palette.border, lineWidth: 1))
                }
                .buttonStyle(.plain)
            }

            if sortedItems.isEmpty {
                Button { showingChecklistEditor = true } label: {
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 24, weight: .light))
                            .foregroundStyle(.tint)
                        Text("Добавить первый пункт")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(palette.primaryText)
                        Text("Список можно дополнить в любой момент")
                            .font(.system(size: 10))
                            .foregroundStyle(palette.secondaryText)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 29)
                    .background(palette.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).strokeBorder(palette.border, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                }
                .buttonStyle(.plain)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sortedItems.enumerated()), id: \.element.id) { index, item in
                        ChecklistItemRow(item: item, palette: palette) {
                            viewModel.toggle(item)
                        }
                        if index < sortedItems.count - 1 {
                            Rectangle()
                                .fill(palette.border)
                                .frame(height: 1)
                                .padding(.leading, 55)
                        }
                    }
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 5)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 17, style: .continuous).stroke(palette.border, lineWidth: 1))
            }
        }
    }

    private var footerNote: some View {
        HStack(spacing: 7) {
            Image(systemName: "info.circle")
            Text("Пункты этого приложения можно менять независимо от шаблона.")
        }
        .font(.system(size: 10))
        .foregroundStyle(palette.secondaryText)
        .padding(.horizontal, 2)
    }
}

private struct MetaChip: View {
    let title: String
    let icon: String
    let palette: MasterOPalette

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .semibold))
            Text(title)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(palette.secondaryText)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(palette.insetSurface, in: Capsule())
    }
}

private struct ChecklistItemRow: View {
    @Bindable var item: ChecklistEntry
    let palette: MasterOPalette
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 13) {
            if let url = item.link.validWebURL {
                Link(destination: url) {
                    HStack(spacing: 7) {
                        Text(item.title)
                            .strikethrough(item.isChecked)
                            .foregroundStyle(item.isChecked ? palette.secondaryText : palette.primaryText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(palette.secondaryText.opacity(0.8))
                    }
                    .font(.system(size: 12, weight: item.isChecked ? .regular : .medium))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded(toggle))
                .accessibilityHint("Открывает ссылку и переключает отметку")
            } else {
                Button(action: toggle) {
                    Text(item.title)
                        .font(.system(size: 12, weight: item.isChecked ? .regular : .medium))
                        .strikethrough(item.isChecked)
                        .foregroundStyle(item.isChecked ? palette.secondaryText : palette.primaryText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }

            Button(action: toggle) {
                ZStack {
                    Circle().fill(item.isChecked ? Color.accentColor : .clear)
                    Circle().stroke(item.isChecked ? Color.accentColor : palette.border, lineWidth: 1.5)
                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 21, height: 21)
                .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isChecked ? "Снять отметку" : "Отметить выполненным")
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 11)
    }
}

private extension String {
    var validWebURL: URL? {
        guard !trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        let candidate = value.contains("://") ? value : "https://\(value)"
        guard let url = URL(string: candidate), ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { return nil }
        return url
    }
}
