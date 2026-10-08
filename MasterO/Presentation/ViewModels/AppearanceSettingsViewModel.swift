import AppKit
import Observation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Как в системе"
        case .light: "Светлая"
        case .dark: "Тёмная"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum AppFontChoice: String, CaseIterable, Identifiable {
    case system
    case avenirNext
    case georgia
    case helveticaNeue
    case menlo
    case palatino

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: "Системный (SF Pro)"
        case .avenirNext: "Avenir Next"
        case .georgia: "Georgia"
        case .helveticaNeue: "Helvetica Neue"
        case .menlo: "Menlo"
        case .palatino: "Palatino"
        }
    }

    var sampleFont: Font {
        switch self {
        case .system: .system(size: 14)
        case .avenirNext: .custom("Avenir Next", size: 14)
        case .georgia: .custom("Georgia", size: 14)
        case .helveticaNeue: .custom("Helvetica Neue", size: 14)
        case .menlo: .custom("Menlo", size: 14)
        case .palatino: .custom("Palatino", size: 14)
        }
    }

    var baseFont: Font {
        switch self {
        case .system: .system(size: 13)
        case .avenirNext: .custom("Avenir Next", size: 13)
        case .georgia: .custom("Georgia", size: 13)
        case .helveticaNeue: .custom("Helvetica Neue", size: 13)
        case .menlo: .custom("Menlo", size: 13)
        case .palatino: .custom("Palatino", size: 13)
        }
    }
}

@MainActor
@Observable
final class AppearanceSettingsViewModel {
    private let defaults: UserDefaults

    var theme: AppTheme {
        didSet { defaults.set(theme.rawValue, forKey: Key.theme) }
    }

    var accentHex: String {
        didSet { defaults.set(accentHex, forKey: Key.accentHex) }
    }

    var fontChoice: AppFontChoice {
        didSet { defaults.set(fontChoice.rawValue, forKey: Key.fontChoice) }
    }

    var accentColor: Color { Color(hex: accentHex) }
    var baseFont: Font { fontChoice.baseFont }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        theme = AppTheme(rawValue: defaults.string(forKey: Key.theme) ?? "") ?? .system
        accentHex = defaults.string(forKey: Key.accentHex) ?? "#0A84FF"
        fontChoice = AppFontChoice(rawValue: defaults.string(forKey: Key.fontChoice) ?? "") ?? .system
    }

    func setAccentColor(_ color: Color) {
        let resolvedColor = NSColor(color).usingColorSpace(.deviceRGB) ?? .systemBlue
        accentHex = String(
            format: "#%02X%02X%02X",
            Int(resolvedColor.redComponent * 255),
            Int(resolvedColor.greenComponent * 255),
            Int(resolvedColor.blueComponent * 255)
        )
    }

    private enum Key {
        static let theme = "appearance.theme"
        static let accentHex = "appearance.accentHex"
        static let fontChoice = "appearance.fontChoice"
    }
}

private extension Color {
    init(hex: String) {
        let value = UInt64(hex.trimmingCharacters(in: CharacterSet(charactersIn: "#")), radix: 16) ?? 0x0A84FF
        self.init(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}
