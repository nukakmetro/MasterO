import SwiftUI

struct MasterOPalette {
    let isDark: Bool

    var sidebar: Color { color(light: 0xEEF1F6, dark: 0x11151C) }
    var canvas: Color { color(light: 0xF7F8FA, dark: 0x171B23) }
    var surface: Color { color(light: 0xFFFFFF, dark: 0x202631) }
    var insetSurface: Color { color(light: 0xF0F2F6, dark: 0x1A1F28) }
    var border: Color { color(light: 0xE2E6ED, dark: 0x303743) }
    var primaryText: Color { color(light: 0x202631, dark: 0xF3F5F8) }
    var secondaryText: Color { color(light: 0x6E7785, dark: 0xA4ADBA) }

    func color(light: UInt32, dark: UInt32) -> Color {
        let value = isDark ? dark : light
        return Color(
            .sRGB,
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255,
            opacity: 1
        )
    }
}

extension ApplicationStatus {
    var displayColor: Color {
        switch self {
        case .notStarted: Color(red: 0.53, green: 0.57, blue: 0.64)
        case .inProgress: Color(red: 0.98, green: 0.61, blue: 0.25)
        case .completed: Color(red: 0.28, green: 0.75, blue: 0.53)
        }
    }
}
