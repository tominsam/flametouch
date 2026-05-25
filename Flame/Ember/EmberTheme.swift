import UIKit
import SwiftUI

extension ShapeStyle where Self == Color {
    
    // MARK: Backgrounds
    static var emberBase: Color { .ember(
        dark:  #colorLiteral(red: 0.07857144193, green: 0.06172594694, blue: 0.05330856765, alpha: 1),
        light: #colorLiteral(red: 0.98039, green: 0.96863, blue: 0.95294, alpha: 1)) }
    static var emberInset: Color { .ember(
        dark:  #colorLiteral(red: 0.5315575787, green: 0.1803963203, blue: 0.004815691092, alpha: 0.1280803617),
        light: #colorLiteral(red: 0.9788023829, green: 0.9550449252, blue: 0.9289879203, alpha: 1)) }
    static var emberElevated: Color { .ember(
        dark:  #colorLiteral(red: 0.6742587352, green: 0.2584658485, blue: 0, alpha: 0.168219466),
        light: #colorLiteral(red: 0.89020, green: 0.86275, blue: 0.82353, alpha: 1)) }
    
    // MARK: Foregrounds
    static var emberTextHi: Color { .ember(
        dark:  #colorLiteral(red: 1.00000, green: 0.94118, blue: 0.84706, alpha: 1),
        light: #colorLiteral(red: 0.11765, green: 0.07059, blue: 0.03137, alpha: 1)) }
    static var emberTextMid: Color { .ember(
        dark:  #colorLiteral(red: 0.90980, green: 0.75294, blue: 0.51765, alpha: 1),
        light: #colorLiteral(red: 0.36078, green: 0.23922, blue: 0.12549, alpha: 1)) }
    static var emberTextLow: Color { .ember(
        dark:  #colorLiteral(red: 0.81569, green: 0.56471, blue: 0.18824, alpha: 1),
        light: #colorLiteral(red: 0.60392, green: 0.43922, blue: 0.31373, alpha: 1)) }
    static var emberTextDim: Color { .ember(
        dark:  #colorLiteral(red: 0.62745, green: 0.40784, blue: 0.18824, alpha: 1),
        light: #colorLiteral(red: 0.75294, green: 0.65882, blue: 0.50980, alpha: 1)) }
    static var emberTextOnTint: Color { .ember(
        dark:  #colorLiteral(red: 0.09412, green: 0.02353, blue: 0.00000, alpha: 1),
        light: #colorLiteral(red: 1.00000, green: 0.97255, blue: 0.94902, alpha: 1)) }
    
    // MARK: Tint
    static var emberTintHi: Color { .ember(
        dark:  #colorLiteral(red: 1, green: 0.6257649383, blue: 0.2647330217, alpha: 1),
        light: #colorLiteral(red: 0.54902, green: 0.28235, blue: 0.06275, alpha: 1)) }
    static var emberTint: Color { .ember(
        dark:  #colorLiteral(red: 1, green: 0.6254868368, blue: 0.3988946161, alpha: 1),
        light: #colorLiteral(red: 0.65882, green: 0.35294, blue: 0.10980, alpha: 1)) }

    static var emberSelectionBackground: Color { .ember(
        dark:  #colorLiteral(red: 0.6322434793, green: 0.2709614911, blue: 0.112898822, alpha: 0.1423137626),
        light: #colorLiteral(red: 0.78431, green: 0.47059, blue: 0.25098, alpha: 0.406390625)) }
    static var emberSelectionBorder: Color { .ember(
        dark:  #colorLiteral(red: 1, green: 0.6257649383, blue: 0.2647330217, alpha: 0.3559974747),
        light: #colorLiteral(red: 0.54902, green: 0.28235, blue: 0.06275, alpha: 0.3955018939)) }

    static var emberButton: Color { .ember(
        dark:  #colorLiteral(red: 1, green: 0.6254868368, blue: 0.3988946161, alpha: 1),
        light: #colorLiteral(red: 0.65882, green: 0.35294, blue: 0.10980, alpha: 1)) }
    static var emberButtonPressed: Color { .ember(
        dark:  #colorLiteral(red: 0.6837629183, green: 0.4276847049, blue: 0.2727493468, alpha: 1),
        light: #colorLiteral(red: 0.78431, green: 0.47059, blue: 0.25098, alpha: 1)) }
    static var emberButtonText: Color { .ember(
        dark:  #colorLiteral(red: 0.09412, green: 0.02353, blue: 0.00000, alpha: 1),
        light: #colorLiteral(red: 1.00000, green: 0.97255, blue: 0.94902, alpha: 1)) }
    
    static var emberPillBackground: Color { .ember(
        dark:  #colorLiteral(red: 0.6322434793, green: 0.2709614911, blue: 0.112898822, alpha: 0.1423137626),
        light: #colorLiteral(red: 0.96078, green: 0.94118, blue: 0.91765, alpha: 1)) }
    static var emberPillBorder: Color { .ember(
        dark:  #colorLiteral(red: 0.5619924951, green: 0.2759504147, blue: 0, alpha: 0.4566425286),
        light: #colorLiteral(red: 0.65882, green: 0.35294, blue: 0.1098, alpha: 0.5678328423)) }

}


// MARK: - Private helper

private extension Color {
    static func ember(dark: UIColor, light: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}


extension Font {

    // MARK: - Headers

    /// Large screen/navigation title — "Network"
    static var emberTitle: Font {
        .system(.largeTitle, design: .rounded, weight: .heavy)
    }

    /// Section or pane title — "mac-studio.local"
    static var emberHeading: Font {
        .system(.title2, design: .rounded, weight: .bold)
    }

    // MARK: - Cell content

    /// Primary row label — device name, service name
    static var emberCellTitle: Font {
        .system(.body, design: .rounded, weight: .medium)
    }

    /// Secondary row label — "Plex Media Server"
    static var emberCellSubtitle: Font {
        .system(.subheadline, design: .rounded, weight: .medium)
    }

    // MARK: - Metadata (monospaced)

    /// IPs, hostnames, service type strings — "_ssh._tcp"
    static var emberMeta: Font {
        var descriptor = UIFont.preferredFont(forTextStyle: .subheadline).fontDescriptor
            .withDesign(.rounded)!
        descriptor = descriptor.addingAttributes([
            .featureSettings: [[
                UIFontDescriptor.FeatureKey.type: kStylisticAlternativesType,
                UIFontDescriptor.FeatureKey.selector: kStylisticAltSixOnSelector,
            ]],
        ])
        let uiFont = UIFont(descriptor: descriptor, size: 0)
        return Font(uiFont)
    }

    /// Section headers, badge labels — "5 SERVICES"
    static var emberSectionHeader: Font {
        .system(.footnote, design: .monospaced, weight: .medium)
    }
}


struct EmberTheme: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.emberCellTitle)
            .backgroundStyle(.emberBase)
            .foregroundStyle(.emberTextMid)
            .tint(.emberTint)
            .accentColor(.emberTint)
            .scrollContentBackground(.hidden)
    }
}

extension View {
    func emberTheme() -> some View {
        modifier(EmberTheme())
    }
}

// MARK: - Button style

struct EmberButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.emberCellSubtitle)
            .foregroundStyle(.emberButtonText)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isPressed ? Color.emberButtonPressed : Color.emberButton)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == EmberButtonStyle {
    static var ember: EmberButtonStyle { EmberButtonStyle() }
}

// MARK: - Preview

#Preview("Ember Colors") {
    List {
        Section("Backgrounds") {
            ColorRow("emberBase", .emberBase)
//            ColorRow("emberCard", .emberCard)
            ColorRow("emberInset", .emberInset)
            ColorRow("emberElevated", .emberElevated)
        }
        Section("Foregrounds") {
            ColorRow("emberTextHi", .emberTextHi)
            ColorRow("emberTextMid", .emberTextMid)
            ColorRow("emberTextLow", .emberTextLow)
            ColorRow("emberTextDim", .emberTextDim)
            ColorRow("emberTextOnTint", .emberTextOnTint)
        }
        Section("Tint") {
            ColorRow("emberTintHi", .emberTintHi)
            ColorRow("emberTint", .emberTint)
            ColorRow("emberSelectionBackground", .emberSelectionBackground)
        }
    }
    .listStyle(.plain)
    .emberTheme()
}

private struct ColorRow: View {
    let name: String
    let color: Color

    init(_ name: String, _ color: Color) {
        self.name = name
        self.color = color
    }

    var body: some View {
        HStack {
            Text(name)
                .frame(maxWidth: .infinity, alignment: .leading)
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .frame(width: 44, height: 28)
        }
        .listRowBackground(Color.emberBase)
    }
}

#Preview("Ember Fonts") {
    VStack(alignment: .leading, spacing: 20) {
        Text("emberTitle - Network")
            .font(.emberTitle)
        Text("emberHeading - mac-studio.local")
            .font(.emberHeading)
        Text("emberCellTitle - Apple TV")
            .font(.emberCellTitle)
        Text("emberCellSubtitle - Plex Media Server")
            .font(.emberCellSubtitle)
        Text("emberMeta - 192.168.1.10")
            .font(.emberMeta)
        Text("emberSectionHeader - 5 SERVICES")
            .font(.emberSectionHeader)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .emberTheme()
}

#Preview("Ember Button") {
    VStack(spacing: 16) {
        Button("Open in Browser") {}
            .buttonStyle(.ember)
        Button("Connect via SSH") {}
            .buttonStyle(.ember)
    }
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .emberTheme()
}
