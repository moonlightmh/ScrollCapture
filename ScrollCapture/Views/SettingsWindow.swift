import SwiftUI

struct SettingsView: View {
    @ObservedObject var appState = AppState.shared

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("通用", systemImage: "gear") }

            StitchSettingsView()
                .tabItem { Label("拼接", systemImage: "rectangle.on.rectangle") }
        }
        .frame(width: 450, height: 300)
        .padding()
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage(Constants.StorageKeys.exportFormat) var exportFormat: String = "PNG"
    @AppStorage(Constants.StorageKeys.jpgQuality) var jpgQuality: Double = 0.9
    @AppStorage(Constants.StorageKeys.lastExportPath) var lastExportPath: String = ""

    var body: some View {
        let form = Form {
            Section("导出设置") {
                Picker("默认格式", selection: $exportFormat) {
                    Text("PNG").tag("PNG")
                    Text("JPG").tag("JPG")
                }
                .pickerStyle(.menu)

                if exportFormat == "JPG" {
                    VStack(alignment: .leading) {
                        Text("JPG 质量: \(Int(jpgQuality * 100))%")
                        Slider(value: $jpgQuality, in: 0.5...1.0, step: 0.05)
                    }
                }

                HStack {
                    Text("默认路径:")
                    TextField("", text: $lastExportPath)
                        .disabled(true)
                    Button("选择...") {
                        selectExportPath()
                    }
                }
            }
        }
        return form
    }

    private func selectExportPath() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK {
            lastExportPath = panel.url?.path ?? ""
        }
    }
}

// MARK: - Stitch Settings

struct StitchSettingsView: View {
    @AppStorage(Constants.StorageKeys.templateHeight) var templateHeight: Int = 100
    @AppStorage(Constants.StorageKeys.matchThreshold) var matchThreshold: Double = 0.85
    @AppStorage(Constants.StorageKeys.maxResultHeight) var maxResultHeight: Int = 50000
    @AppStorage(Constants.StorageKeys.learnedOverlap) var learnedOverlap: Int = 100

    var body: some View {
        Form {
            Section("拼接参数") {
                HStack {
                    Text("模板高度:")
                    TextField("", value: $templateHeight, format: .number)
                        .frame(width: 60)
                    Text("px")
                    Spacer()
                }

                HStack {
                    Text("匹配阈值:")
                    TextField("", value: $matchThreshold, format: .number)
                        .frame(width: 60)
                    Text("(0.5 - 0.99)")
                    Spacer()
                }

                HStack {
                    Text("最大长度:")
                    TextField("", value: $maxResultHeight, format: .number)
                        .frame(width: 80)
                    Text("px")
                    Spacer()
                }
            }

            Section("学习值") {
                HStack {
                    Text("当前学习重叠值:")
                    Text("\(learnedOverlap) px")
                    Spacer()
                    Button("重置") {
                        learnedOverlap = 100
                    }
                }

                Text("此值会根据实际拼接结果自动调整")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Settings Window Controller

class SettingsWindowController: NSObject {
    static let shared = SettingsWindowController()

    private var window: NSWindow?

    private override init() {
        super.init()
    }

    func showWindow() {
        if window == nil {
            let contentView = SettingsView()
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 450, height: 300),
                styleMask: [.titled, .closable],
                backing: .buffered,
                defer: false
            )
            window?.title = "设置"
            window?.contentView = NSHostingView(rootView: contentView)
            window?.center()
            window?.isReleasedWhenClosed = false
        }
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}