import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handleURLScheme(url)
        }
    }

    private func handleURLScheme(_ url: URL) {
        guard url.scheme == "hashcalculator-helper" else {
            NSLog("RightKitHelper: Unknown URL scheme: \(url.scheme ?? "nil")")
            return
        }
        switch url.host {
        case "calculate-hash":
            handleHashCalculation(url)
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
