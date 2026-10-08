import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ApplicationViewModel()
    @State private var showingNewApplication = false
    @State private var showingTemplates = false

    private var dateGroups: [ApplicationDateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: viewModel.applications) { calendar.startOfDay(for: $0.createdAt) }
        return grouped.keys.sorted().compactMap { day in
            guard let applications = grouped[day] else { return nil }
            return ApplicationDateGroup(day: day, applications: applications.sorted { $0.createdAt < $1.createdAt })
        }
    }

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 240, ideal: 285, max: 360)
        } detail: {
            detail
        }
        .task { viewModel.connect(to: modelContext) }
        .sheet(isPresented: $showingNewApplication) {
            NewApplicationSheet(templates: viewModel.templates) { name, link, template in
                viewModel.createApplication(name: name, link: link, template: template)
                showingNewApplication = false
            }
        }
        .sheet(isPresented: $showingTemplates) {
            TemplateManagerView(viewModel: viewModel)
        }
        .alert("Ошибка", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("ОК", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var sidebar: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "checklist")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.tint)
                Text("Приложения")
                    .font(.headline)
                Spacer()
                Button { showingNewApplication = true } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .help("Добавить приложение")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)

            if viewModel.applications.isEmpty {
                ContentUnavailableView("Пока нет приложений", systemImage: "square.stack.3d.up", description: Text("Создайте приложение и выберите для него шаблон чеклиста."))
                    .padding(.horizontal, 10)
            } else {
                List(selection: $viewModel.selectedApplicationID) {
                    ForEach(dateGroups) { group in
                        Section {
                            ForEach(group.applications) { application in
                                ApplicationSidebarRow(application: application)
                                    .tag(application.id)
                                    .contextMenu {
                                        Button("Удалить приложение", role: .destructive) {
                                            viewModel.deleteApplication(application)
                                        }
                                    }
                            }
                        } header: {
                            Text(group.day.formatted(.dateTime.day().month(.wide).year()))
                                .textCase(nil)
                        }
                    }
                }
                .listStyle(.sidebar)
            }

            Divider()
            Button {
                showingTemplates = true
            } label: {
                Label("Шаблоны чеклистов", systemImage: "square.grid.2x2")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.regularMaterial)
    }

    @ViewBuilder
    private var detail: some View {
        if let application = viewModel.selectedApplication {
            ApplicationDetailView(application: application, viewModel: viewModel)
        } else {
            ContentUnavailableView("Выберите приложение", systemImage: "checklist", description: Text("Или создайте новое приложение, чтобы начать работу."))
        }
    }
}

private struct ApplicationDateGroup: Identifiable {
    let day: Date
    let applications: [ReleaseApplication]
    var id: Date { day }
}

private struct ApplicationSidebarRow: View {
    let application: ReleaseApplication

    var body: some View {
        HStack(spacing: 9) {
            Circle()
                .fill(statusColor)
                .frame(width: 9, height: 9)
            VStack(alignment: .leading, spacing: 3) {
                Text(application.name.isEmpty ? "Без названия" : application.name)
                    .lineLimit(1)
                    .font(.system(size: 13, weight: .medium))
                Text(application.createdAt.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if !application.link.isEmpty {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(application.name), \(application.status.title)")
    }

    private var statusColor: Color {
        switch application.status {
        case .notStarted: .gray
        case .inProgress: .orange
        case .completed: .green
        }
    }
}

private struct ApplicationDetailView: View {
    @Environment(\.openURL) private var openURL
    @Bindable var application: ReleaseApplication
    @Bindable var viewModel: ApplicationViewModel
    @State private var showingChecklistEditor = false
    @State private var showingApplicationEditor = false

    private var sortedItems: [ChecklistEntry] {
        application.checklistItems.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            checklistContent
        }
        .background(Color(nsColor: .windowBackgroundColor))
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

    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    if let url = application.link.validWebURL {
                        Link(destination: url) {
                            HStack(spacing: 7) {
                                Text(application.name.isEmpty ? "Без названия" : application.name)
                                    .font(.system(size: 26, weight: .semibold))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 13, weight: .medium))
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        Text(application.name.isEmpty ? "Без названия" : application.name)
                            .font(.system(size: 26, weight: .semibold))
                    }
                }
                HStack(spacing: 8) {
                    Text(application.checklistTypeName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(application.createdAt.formatted(date: .long, time: .shortened))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            Picker("Статус", selection: Binding(
                get: { application.status },
                set: { viewModel.setStatus($0, for: application) }
            )) {
                ForEach(ApplicationStatus.allCases) { status in
                    Text(status.title).tag(status)
                }
            }
            .pickerStyle(.menu)
            .tint(statusTint)
            .fixedSize()
            Menu {
                Button("Изменить приложение…", systemImage: "pencil") { showingApplicationEditor = true }
                Button("Редактировать чеклист…", systemImage: "checklist") { showingChecklistEditor = true }
                Divider()
                Button("Удалить приложение", systemImage: "trash", role: .destructive) {
                    viewModel.deleteApplication(application)
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .frame(width: 30, height: 28)
                    .contentShape(Rectangle())
            }
            .menuStyle(.borderlessButton)
        }
        .padding(.horizontal, 30)
        .padding(.vertical, 24)
    }

    @ViewBuilder
    private var checklistContent: some View {
        if sortedItems.isEmpty {
            ContentUnavailableView {
                Label("Чеклист пуст", systemImage: "checklist")
            } description: {
                Text("Добавьте пункты, чтобы отслеживать подготовку приложения.")
            } actions: {
                Button("Добавить пункты") { showingChecklistEditor = true }
                    .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("Чеклист")
                            .font(.title3.weight(.semibold))
                        Spacer()
                        Text("\(sortedItems.filter(\.isChecked).count) из \(sortedItems.count)")
                            .font(.subheadline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 14)

                    VStack(spacing: 0) {
                        ForEach(sortedItems) { item in
                            ChecklistItemRow(item: item) {
                                viewModel.toggle(item)
                            }
                            if item.id != sortedItems.last?.id { Divider().padding(.leading, 42) }
                        }
                    }
                    .padding(.horizontal, 16)
                    .background(.background, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.quaternary, lineWidth: 1))
                }
                .frame(maxWidth: 760)
                .padding(.horizontal, 32)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
        }
    }

    private var statusTint: Color {
        switch application.status {
        case .notStarted: .gray
        case .inProgress: .orange
        case .completed: .green
        }
    }
}

private struct ChecklistItemRow: View {
    @Environment(\.openURL) private var openURL
    @Bindable var item: ChecklistEntry
    let toggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: toggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(item.isChecked ? Color.accentColor : Color.secondary.opacity(0.65))
                    .frame(width: 24, height: 34)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(item.isChecked ? "Снять отметку" : "Отметить выполненным")

            if let url = item.link.validWebURL {
                Link(destination: url) {
                    Text(item.title)
                        .strikethrough(item.isChecked)
                        .foregroundStyle(item.isChecked ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .simultaneousGesture(TapGesture().onEnded(toggle))
                .accessibilityHint("Откроет ссылку и переключит отметку")
            } else {
                Button(action: toggle) {
                    Text(item.title)
                        .strikethrough(item.isChecked)
                        .foregroundStyle(item.isChecked ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 5)
        .accessibilityElement(children: .contain)
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
