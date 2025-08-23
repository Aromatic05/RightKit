import Cocoa
import Foundation

class FileHashDialog: NSWindowController, NSWindowDelegate {
    private let fileURL: URL
    private var selectedTypes: Set<FileHashType> = [.md5, .sha1, .sha256]
    private var checkboxes: [NSButton] = []
    private var resultTextView: NSTextView!

    init(fileURL: URL) {
        self.fileURL = fileURL
        let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 400, height: 320),
                              styleMask: [.titled, .closable],
                              backing: .buffered, defer: false)
        window.title = "文件哈希值计算"
        super.init(window: window)
        window.delegate = self // 设置窗口代理
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        guard let contentView = window?.contentView else { return }
        let label = NSTextField(labelWithString: "请选择要计算的哈希类型：")
        label.frame = NSRect(x: 20, y: 270, width: 560, height: 48)
        contentView.addSubview(label)

        var y = 240
        for type in FileHashType.allCases {
            let checkbox = NSButton(checkboxWithTitle: type.rawValue, target: self, action: #selector(checkboxChanged(_:)))
            checkbox.frame = NSRect(x: 20, y: y, width: 100, height: 24)
            checkbox.state = selectedTypes.contains(type) ? .on : .off
            contentView.addSubview(checkbox)
            checkboxes.append(checkbox)
            y -= 30
        }

        let calcButton = NSButton(title: "计算", target: self, action: #selector(calcPressed))
        calcButton.frame = NSRect(x: 20, y: 40, width: 80, height: 32)
        contentView.addSubview(calcButton)

        resultTextView = NSTextView(frame: NSRect(x: 120, y: 20, width: 260, height: 180))
        resultTextView.isEditable = false
        resultTextView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        contentView.addSubview(resultTextView)
    }

    @objc private func checkboxChanged(_ sender: NSButton) {
        guard let idx = checkboxes.firstIndex(of: sender) else { return }
        let type = FileHashType.allCases[idx]
        if sender.state == .on {
            selectedTypes.insert(type)
        } else {
            selectedTypes.remove(type)
        }
    }

    @objc private func calcPressed() {
        let results = FileHashUtils.calculateHashes(for: fileURL, types: Array(selectedTypes))
        let text = results.map { "\($0.type.rawValue): \($0.value)" }.joined(separator: "\n")
        resultTextView.string = text.isEmpty ? "无法读取文件或未选择类型" : text
    }

    func showModal() {
        guard let window = self.window else { return }
        let app = NSApplication.shared
        app.runModal(for: window)
    }

    func windowWillClose(_ notification: Notification) {
        NSApp.terminate(nil) // 窗口关闭时立即退出进程
    }
}
