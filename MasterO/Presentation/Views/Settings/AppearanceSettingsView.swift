import SwiftUI

struct AppearanceSettingsView: View {
    @Bindable var settings: AppearanceSettingsViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private var palette: MasterOPalette { MasterOPalette(isDark: colorScheme == .dark) }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("Настройки")
                        .font(.system(size: 25, weight: .bold, design: .rounded))
                        .foregroundStyle(palette.primaryText)
                    Text("Подстройте рабочее пространство под себя")
                        .font(.system(size: 12))
                        .foregroundStyle(palette.secondaryText)
                }
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(palette.secondaryText)
                        .frame(width: 30, height: 30)
                        .background(palette.insetSurface, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Закрыть настройки")
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("ТЕМА", detail: "Выберите оформление")
                HStack(spacing: 9) {
                    ForEach(AppTheme.allCases) { theme in
                        themeTile(theme)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("АКЦЕНТ", detail: "Цвет действий и выделения")
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 11, style: .continuous)
                            .fill(settings.accentColor.gradient)
                        Image(systemName: "sparkle")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 39, height: 39)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Свой цвет")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(palette.primaryText)
                        Text("Акцент используется во всём приложении")
                            .font(.system(size: 10))
                            .foregroundStyle(palette.secondaryText)
                    }
                    Spacer()
                    ColorPicker(
                        "Акцентный цвет",
                        selection: Binding(get: { settings.accentColor }, set: { settings.setAccentColor($0) }),
                        supportsOpacity: false
                    )
                    .labelsHidden()
                }
                .padding(12)
                .background(palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(palette.border, lineWidth: 1))
            }

            VStack(alignment: .leading, spacing: 10) {
                sectionTitle("ШРИФТ", detail: "Стиль текста в рабочем пространстве")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(AppFontChoice.allCases) { choice in
                        fontTile(choice)
                    }
                }
            }

            HStack(spacing: 12) {
                Image(systemName: "text.alignleft")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(settings.accentColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Пример интерфейса")
                        .font(settings.fontChoice.sampleFont.weight(.semibold))
                        .foregroundStyle(palette.primaryText)
                    Text("Подготовка приложения к публикации")
                        .font(settings.fontChoice.sampleFont)
                        .foregroundStyle(palette.secondaryText)
                }
                Spacer()
                Circle().fill(settings.accentColor).frame(width: 8, height: 8)
            }
            .padding(13)
            .background(palette.insetSurface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

            Spacer(minLength: 0)
        }
        .padding(25)
        .frame(width: 560, height: 570)
        .background(palette.canvas)
    }

    private func sectionTitle(_ title: String, detail: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .tracking(1.25)
                .foregroundStyle(palette.secondaryText)
            Spacer()
            Text(detail)
                .font(.system(size: 10))
                .foregroundStyle(palette.secondaryText.opacity(0.8))
        }
    }

    private func themeTile(_ theme: AppTheme) -> some View {
        let selected = settings.theme == theme
        let icon: String = switch theme {
        case .system: "circle.lefthalf.filled"
        case .light: "sun.max"
        case .dark: "moon"
        }
        return Button { settings.theme = theme } label: {
            VStack(spacing: 7) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .medium))
                Text(theme.title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(selected ? settings.accentColor : palette.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selected ? settings.accentColor.opacity(0.09) : palette.surface, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 13, style: .continuous).stroke(selected ? settings.accentColor.opacity(0.55) : palette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private func fontTile(_ choice: AppFontChoice) -> some View {
        let selected = settings.fontChoice == choice
        return Button { settings.fontChoice = choice } label: {
            VStack(spacing: 4) {
                Text("Aa")
                    .font(choice.sampleFont.weight(.semibold))
                    .foregroundStyle(selected ? settings.accentColor : palette.primaryText)
                Text(choice.title)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(selected ? settings.accentColor : palette.secondaryText)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(selected ? settings.accentColor.opacity(0.08) : palette.surface, in: RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(selected ? settings.accentColor.opacity(0.55) : palette.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}
