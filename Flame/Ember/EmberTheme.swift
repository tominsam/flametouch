import SwiftUI

extension ShapeStyle where Self == Color {

    // MARK: Backgrounds
    static var emberBase: Color { .ember(dark: 0x0c0a08, light: 0xfaf7f3) }
    static var emberCard: Color { .ember(dark: 0x1c1610, light: 0xf5f0ea) }
    static var emberInset: Color { .ember(dark: 0x261e14, light: 0xede8e0) }
    static var emberElevated: Color { .ember(dark: 0x2e2820, light: 0xe3dcd2) }

    // MARK: Foregroundsπ
    static var emberTextHi: Color { .ember(dark: 0xf0e4d0, light: 0x1e1208) }
    static var emberTextMid: Color { .ember(dark: 0xf0d0a0, light: 0x5c3d20) }
    static var emberTextLow: Color { .ember(dark: 0x8c6038, light: 0x9a7050) }
    static var emberTextDim: Color { .ember(dark: 0x3a2a1e, light: 0xc0a882) }
    static var emberTextOnTint: Color { .ember(dark: 0x1a0e06, light: 0xfff8f2) }

    // MARK: Tint
    static var emberTintHi: Color { .ember(dark: 0xe8964e, light: 0x8c4810) }
    static var emberTint: Color { .ember(dark: 0xc87941, light: 0xa85a1c) }
    static var emberTintDim: Color { .ember(dark: 0x8a5128, light: 0xc87840) }
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

// MARK: - Private helper

private extension Color {
    static func ember(dark: UInt32, light: UInt32) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? .init(hex: dark) : .init(hex: light) })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255,
            green: CGFloat((hex >> 8)  & 0xff) / 255,
            blue: CGFloat( hex        & 0xff) / 255,
            alpha: 1
        )
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
            .foregroundStyle(.emberTextOnTint)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(configuration.isPressed ? Color.emberTintDim : Color.emberTint)
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
            ColorRow("emberCard", .emberCard)
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
            ColorRow("emberTintDim", .emberTintDim)
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
