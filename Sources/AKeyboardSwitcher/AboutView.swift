import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "keyboard.badge.ellipsis")
                    .font(.largeTitle)
                    .foregroundStyle(Color.accentColor)
                VStack(alignment: .leading) {
                    Text("AKeyboardSwitcher").font(.title2).bold()
                    Text("Version \(Self.version)").font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 20)
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
            }

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    Text("Author:").foregroundStyle(.secondary)
                    Text("Florian Paul Azim Hoberg @gyptazy").textSelection(.enabled)
                }
                GridRow {
                    Text("Web:").foregroundStyle(.secondary)
                    Link("https://gyptazy.com/blog/akeyboardswitcher",
                         destination: URL(string: "https://gyptazy.com/blog/akeyboardswitcher")!)
                }
                GridRow {
                    Text("Mail:").foregroundStyle(.secondary)
                    Link("support@gyptazy.com", destination: URL(string: "mailto:support@gyptazy.com")!)
                }
                GridRow {
                    Text("License:").foregroundStyle(.secondary)
                    Text("GPLv3 (Open-Source)")
                }
            }
        }
        .padding(20)
        .fixedSize()
    }

    private static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    }
}
