import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openWindow) private var openWindow
    @Bindable var settings: AppearanceSettingsViewModel
    @State private var viewModel = ApplicationViewModel()
    @State private var showingNewApplication = false
    @State private var showingTemplates = false
    @State private var showingSettings = false
    @State private var searchText = ""
    @State private var isSidebarCollapsed = false

    private var palette: MasterOPalette { MasterOPalette(isDark: colorScheme == .dark) }

    private var dateGroups: [ApplicationDateGroup] {
        let calendar = Calendar.current
        let filteredApplications = viewModel.applications.filter {
            searchText.isEmpty || $0.name.localizedCaseInsensitiveContains(searchText)
        }
        let grouped = Dictionary(grouping: filteredApplications) { calendar.startOfDay(for: $0.createdAt) }
        return grouped.keys.sorted(by: >).compactMap { day in
            guard let applications = grouped[day] else { return nil }
            return ApplicationDateGroup(day: day, applications: applications.sorted { $0.createdAt > $1.createdAt })
        }
    }

    var body: some View {
        HStack(spacing: 0) {
            Group {
                if isSidebarCollapsed {
                    collapsedSidebar.frame(width: 58)
                } else {
                    sidebar.frame(width: 250)
                }
            }
            Rectangle()
                .fill(palette.border)
                .frame(width: 1)
            mainPanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(palette.canvas)
        .animation(.easeInOut(duration: 0.2), value: isSidebarCollapsed)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    isSidebarCollapsed.toggle()
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .help(isSidebarCollapsed ? "Показать боковую панель" : "Скрыть боковую панель")
                .accessibilityLabel(isSidebarCollapsed ? "Показать боковую панель" : "Скрыть боковую панель")
            }
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
        .sheet(isPresented: $showingSettings) {
            AppearanceSettingsView(settings: settings)
        }
        .alert("Ошибка", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("ОК", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .preferredColorScheme(settings.theme.colorScheme)
        .tint(settings.accentColor)
        .environment(\.font, settings.baseFont)
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 11) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("CheckTuk")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                }
                Spacer()
                Button { showingNewApplication = true } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(settings.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain)
                .help("Добавить приложение")
                .accessibilityLabel("Добавить приложение")
            }
            .padding(.horizontal, 20)
            .padding(.top, 23)
            .padding(.bottom, 20)

            HStack(spacing: 9) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                TextField("Найти приложение", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundStyle(palette.primaryText)
            }
            .padding(.horizontal, 12)
            .frame(height: 37)
            .background(palette.insetSurface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(palette.border.opacity(0.65), lineWidth: 1))
            .padding(.horizontal, 15)
            .padding(.bottom, 17)

            HStack {
                Text("ВАШИ ПРИЛОЖЕНИЯ")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .tracking(1.3)
                    .foregroundStyle(palette.secondaryText)
                Spacer()
                Text("\(viewModel.applications.count)")
                    .font(.system(size: 10, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(palette.secondaryText)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    if dateGroups.isEmpty {
                        VStack(alignment: .leading, spacing: 9) {
                            Image(systemName: searchText.isEmpty ? "square.stack.3d.up" : "magnifyingglass")
                                .font(.system(size: 19, weight: .light))
                                .foregroundStyle(palette.secondaryText)
                            Text(searchText.isEmpty ? "Здесь появятся приложения" : "Ничего не найдено")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(palette.secondaryText)
                            if searchText.isEmpty {
                                Button("Создать первое") { showingNewApplication = true }
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(settings.accentColor)
                                    .buttonStyle(.plain)
                            }
                        }
                        .padding(15)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(palette.surface.opacity(0.7), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    } else {
                        ForEach(dateGroups) { group in
                            VStack(alignment: .leading, spacing: 7) {
                                Text(group.day.formatted(.dateTime.day().month(.wide).year()).uppercased())
                                    .font(.system(size: 9, weight: .bold, design: .rounded))
                                    .tracking(0.9)
                                    .foregroundStyle(palette.secondaryText.opacity(0.82))
                                    .padding(.horizontal, 10)

                                ForEach(group.applications) { application in
                                    ApplicationSidebarItem(
                                        application: application,
                                        isSelected: application.id == viewModel.selectedApplicationID,
                                        palette: palette,
                                        accent: settings.accentColor
                                    ) {
                                        viewModel.selectedApplicationID = application.id
                                    }
                                    .contextMenu {
                                        Button("Удалить приложение", role: .destructive) {
                                            viewModel.deleteApplication(application)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 11)
                .padding(.bottom, 10)
            }

            Spacer(minLength: 8)
            Rectangle().fill(palette.border).frame(height: 1)
            HStack(spacing: 9) {
                collapsedAction(icon: "square.grid.2x2", help: "Шаблоны чеклистов") { showingTemplates = true }
                collapsedAction(icon: "lightbulb", help: "Подсказки") { openWindow(id: "tips") }
                collapsedAction(icon: "slider.horizontal.3", help: "Настройки") { showingSettings = true }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
        }
        .frame(maxHeight: .infinity)
        .background(palette.sidebar)
    }

    private var collapsedSidebar: some View {
        VStack(spacing: 10) {
            Button { showingNewApplication = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(settings.accentColor, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .buttonStyle(.plain)
            .help("Добавить приложение")
            .accessibilityLabel("Добавить приложение")

            Rectangle().fill(palette.border).frame(height: 1).padding(.vertical, 3)

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(viewModel.applications.sorted { $0.createdAt > $1.createdAt }) { application in
                        Button {
                            viewModel.selectedApplicationID = application.id
                        } label: {
                            Circle()
                                .fill(application.status.displayColor)
                                .frame(width: 11, height: 11)
                                .frame(width: 42, height: 42)
                                .background(
                                    application.id == viewModel.selectedApplicationID ? settings.accentColor.opacity(0.14) : .clear,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(application.id == viewModel.selectedApplicationID ? settings.accentColor.opacity(0.55) : .clear, lineWidth: 1)
                                }
                                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .help(application.name)
                        .contextMenu {
                            Button("Удалить приложение", role: .destructive) {
                                viewModel.deleteApplication(application)
                            }
                        }
                    }
                }
            }

            Spacer(minLength: 4)
            Rectangle().fill(palette.border).frame(height: 1).padding(.vertical, 3)
            collapsedAction(icon: "square.grid.2x2", help: "Шаблоны чеклистов") { showingTemplates = true }
            collapsedAction(icon: "lightbulb", help: "Подсказки") { openWindow(id: "tips") }
            collapsedAction(icon: "slider.horizontal.3", help: "Настройки") { showingSettings = true }
        }
        .padding(.horizontal, 7)
        .padding(.top, 17)
        .padding(.bottom, 10)
        .frame(maxHeight: .infinity)
        .background(palette.sidebar)
    }

    private func collapsedAction(icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.secondaryText)
                .frame(width: 34, height: 34)
                .background(palette.insetSurface, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .help(help)
        .accessibilityLabel(help)
    }

    @ViewBuilder
    private var mainPanel: some View {
        if let application = viewModel.selectedApplication {
            ApplicationDetailView(application: application, viewModel: viewModel, palette: palette)
        } else {
            VStack(spacing: 15) {
                ZStack {
                    Circle().fill(settings.accentColor.opacity(0.11)).frame(width: 88, height: 88)
                    Image(systemName: "checklist")
                        .font(.system(size: 31, weight: .light))
                        .foregroundStyle(settings.accentColor)
                }
                Text("Всё готово к запуску")
                    .font(.system(size: 23, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.primaryText)
                Text("Создайте приложение, выберите чеклист — и держите подготовку под контролем.")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.secondaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 410)
                Button { showingNewApplication = true } label: {
                    Label("Добавить приложение", systemImage: "plus")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 17)
                        .padding(.vertical, 11)
                        .foregroundStyle(.white)
                        .background(settings.accentColor, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(palette.canvas)
        }
    }
}

private struct ApplicationDateGroup: Identifiable {
    let day: Date
    let applications: [ReleaseApplication]
    var id: Date { day }
}

private struct ApplicationSidebarItem: View {
    let application: ReleaseApplication
    let isSelected: Bool
    let palette: MasterOPalette
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(application.status.displayColor)
                    .frame(width: 3, height: 34)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 5) {
                        Text(application.name.isEmpty ? "Без названия" : application.name)
                            .font(.system(size: 12, weight: .semibold))
                            .lineLimit(1)
                            .foregroundStyle(palette.primaryText)
                        if !application.link.isEmpty {
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(palette.secondaryText)
                        }
                    }
                    HStack(spacing: 5) {
                        Text(application.status.title)
                        Text("·")
                        Text(application.createdAt.formatted(date: .omitted, time: .shortened))
                    }
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(palette.secondaryText)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .background(isSelected ? accent.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(accent.opacity(0.25), lineWidth: 1)
                }
            }
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(application.name), \(application.status.title)")
    }
}
