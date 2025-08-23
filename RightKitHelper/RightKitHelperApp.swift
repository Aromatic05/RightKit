import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleURLScheme(url)
        }
    }

    private func handleURLScheme(_ url: URL) {
        guard url.scheme == "rightkit-helper" else {
            NSLog("RightKitHelper: Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }
        switch url.host {
        case "calculate-hash":
            handleHashCalculation(url)
        case "delete-file":
            handleDeleteFile(url)
        default:
            NSLog("RightKitHelper: Unknown URL host: \(url.host ?? "nil")")
        }
    }

    private func handleHashCalculation(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              let filePathItem = queryItems.first(where: { $0.name == "filePath" }),
              let filePath = filePathItem.value else {
            NSLog("RightKitHelper: Invalid hash calculation URL - missing filePath parameter")
            return
        }
        let fileURL = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            NSLog("RightKitHelper: File does not exist: \(fileURL.path)")
            return
        }
        NSLog("RightKitHelper: Showing hash dialog for file: \(fileURL.path)")
        DispatchQueue.main.async {
            let dialog = FileHashDialog(fileURL: fileURL)
            dialog.showModal()
        }
    }

    private func handleDeleteFile(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            NSLog("RightKitHelper: Invalid delete file URL - missing query items")
            return
        }
        let filePaths = queryItems.filter { $0.name == "filePath" }.compactMap { $0.value }
        let urls = filePaths.map { URL(fileURLWithPath: $0) }.filter { FileManager.default.fileExists(atPath: $0.path) }
        guard !urls.isEmpty else {
            NSLog("RightKitHelper: No valid files to delete")
            return
        }
        NSLog("RightKitHelper: Showing system delete confirmation for files: \(urls.map { $0.path })")
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "确认永久删除?"
            alert.informativeText = "此操作无法撤销，将永久删除所选文件。"
            alert.alertStyle = .warning
            alert.addButton(withTitle: "删除")
            alert.addButton(withTitle: "取消")
            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                let fileManager = FileManager.default
                for url in urls {
                    do {
                        try fileManager.removeItem(at: url)
                        NSLog("RightKitHelper: Permanently deleted %@", url.path)
                    } catch {
                        NSLog("RightKitHelper: Failed to delete %@: %@", url.path, error.localizedDescription)
                    }
                }
            } else {
                NSLog("RightKitHelper: User cancelled permanent delete")
            }
            NSApp.terminate(nil)
        }
    }
}

@main
struct RightKitHelperApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
