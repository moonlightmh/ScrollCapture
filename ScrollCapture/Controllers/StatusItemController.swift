import Cocoa
import SwiftUI
import Combine

class StatusItemController {
    private var statusItem: NSStatusItem?
    private var menu: NSMenu?

    private let appState = AppState.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        setupStatusItem()
        observeState()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "ScrollCapture")
            button.image?.isTemplate = true
        }

        menu = createMenu()
        statusItem?.menu = menu
    }

    private func createMenu() -> NSMenu {
        let menu = NSMenu()

        let startItem = NSMenuItem(title: "开始截图", action: #selector(startCapture), keyEquivalent: "s")
        startItem.target = self
        menu.addItem(startItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "退出", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    private func observeState() {
        appState.$captureState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateMenuForState(state)
                self?.updateStatusItemTitle(state)
            }
            .store(in: &cancellables)

        appState.$screenshotCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.updateScreenshotCount(count)
            }
            .store(in: &cancellables)
    }

    private func updateMenuForState(_ state: CaptureState) {
        guard let menu = menu else { return }

        let startItem = menu.items.first

        switch state {
        case .idle:
            startItem?.title = "开始截图"
            startItem?.action = #selector(startCapture)
            startItem?.keyEquivalent = "s"
            // Remove cancel item if exists
            if let cancelItem = menu.items.first(where: { $0.title == "取消截图" }) {
                menu.removeItem(cancelItem)
            }

        case .selectingArea:
            startItem?.title = "选择区域中..."
            startItem?.action = nil
            startItem?.keyEquivalent = ""

        case .capturing:
            startItem?.title = "结束截图"
            startItem?.action = #selector(endCapture)
            startItem?.keyEquivalent = "e"
            // Add cancel option
            if menu.items.first(where: { $0.title == "取消截图" }) == nil {
                let cancelItem = NSMenuItem(title: "取消截图", action: #selector(cancelCapture), keyEquivalent: "")
                cancelItem.target = self
                menu.insertItem(cancelItem, at: 1)
            }

        case .exporting:
            startItem?.title = "导出中..."
            startItem?.action = nil
            startItem?.keyEquivalent = ""

        case .error(let message):
            startItem?.title = "错误: \(message)"
            startItem?.action = #selector(startCapture)
            startItem?.keyEquivalent = "s"
            if let cancelItem = menu.items.first(where: { $0.title == "取消截图" }) {
                menu.removeItem(cancelItem)
            }
        }
    }

    private func updateStatusItemTitle(_ state: CaptureState) {
        if let button = statusItem?.button {
            switch state {
            case .capturing:
                button.toolTip = "已截图 \(appState.screenshotCount) 张"
            default:
                button.toolTip = "ScrollCapture"
            }
        }
    }

    private func updateScreenshotCount(_ count: Int) {
        if appState.captureState == .capturing {
            statusItem?.button?.toolTip = "已截图 \(count) 张"
        }
    }

    @objc private func startCapture() {
        if !PermissionChecker.shared.hasScreenRecordingPermission() {
            showPermissionAlert()
            return
        }
        appState.startNewSession()
        CaptureManager.shared.startSelection()
    }

    @objc private func endCapture() {
        appState.captureState = .exporting
        ExportManager.shared.export()
    }

    @objc private func cancelCapture() {
        appState.cancelSession()
    }

    @objc private func openSettings() {
        SettingsWindowController.shared.showWindow()
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "需要屏幕录制权限"
        alert.informativeText = "ScrollCapture 需要屏幕录制权限才能截取屏幕内容。\n\n请在系统设置 > Privacy > 屏幕录制 中开启 ScrollCapture。"
        alert.addButtonWithTitle("打开系统设置")
        alert.addButtonWithTitle("稍后设置")
        alert.alertStyle = .warning

        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            PermissionChecker.shared.openPrivacySettings()
        }
    }
}