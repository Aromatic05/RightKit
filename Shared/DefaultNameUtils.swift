//
//  DefaultNameUtils.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/18.
//

struct DefaultNameUtils {
    // Centralized icon set
    private static let allIconNames: Set<String> = [
        // File extension icons
        "doc.plaintext", "text.book.closed", "swift", "terminal", "globe", "paintbrush", "f.cursive", "curlybraces", "doc.text", "doc.richtext", "table", "rectangle.on.rectangle.angled", "archivebox", "photo", "music.note", "film",
        // ActionType icons (for Picker, mapping is handled elsewhere)
        "doc", "doc.badge.plus", "folder", "terminal", "doc.on.doc", "scissors", "play", "app", "minus",
        // Icons from ConfigurationManager default config
        "doc.text.below.ecg", "folder.badge.plus", "wrench.and.screwdriver", "doc.on.clipboard", "desktopcomputer", "hash", "trash", "eye.slash"
    ]

    private static let extensionToIcon: [String: String] = [
        "txt": "doc.plaintext",
        "md": "text.book.closed",
        "swift": "swift",
        "py": "terminal",
        "html": "globe",
        "htm": "globe",
        "css": "paintbrush",
        "js": "f.cursive",
        "json": "curlybraces",
        "yaml": "doc.text",
        "yml": "doc.text",
        "pdf": "doc.richtext",
        "doc": "doc.text",
        "docx": "doc.text",
        "xls": "table",
        "xlsx": "table",
        "ppt": "rectangle.on.rectangle.angled",
        "pptx": "rectangle.on.rectangle.angled",
        "zip": "archivebox",
        "rar": "archivebox",
        "png": "photo",
        "jpg": "photo",
        "jpeg": "photo",
        "gif": "photo",
        "mp3": "music.note",
        "wav": "music.note",
        "mp4": "film",
        "mov": "film",
        "avi": "film",
        "csv": "table",
        "rtf": "doc.richtext"
    ]

    private static let extensionToDefaultName: [String: String] = [
        "txt": "新建文本文件.txt",
        "swift": "新建Swift文件.swift",
        "md": "新建Markdown文件.md",
        "json": "新建JSON文件.json",
        "py": "新建Python文件.py",
        "js": "新建JavaScript文件.js",
        "html": "新建HTML文件.html",
        "css": "新建CSS文件.css",
        "pdf": "新建PDF文件.pdf",
        "doc": "新建Word文件.doc",
        "docx": "新建Word文件.docx",
        "xls": "新建Excel文件.xls",
        "xlsx": "新建Excel文件.xlsx",
        "ppt": "新建PPT文件.ppt",
        "pptx": "新建PPT文件.pptx",
        "zip": "新建压缩包.zip",
        "rar": "新建压缩包.rar",
        "png": "新建图片.png",
        "jpg": "新建图片.jpg",
        "jpeg": "新建图片.jpeg",
        "gif": "新建图片.gif",
        "mp3": "新建音频文件.mp3",
        "wav": "新建音频文件.wav",
        "mp4": "新建视频文件.mp4",
        "mov": "新建视频文件.mov",
        "avi": "新建视频文件.avi",
        "csv": "新建表格文件.csv",
        "rtf": "新建富文本文件.rtf",
        "yaml": "新建YAML文件.yaml",
        "yml": "新建YAML文件.yml"
    ]

    static let availableIcons: [String] = Array(allIconNames).sorted()

    static func iconForFileExtension(_ ext: String) -> String {
        let key = ext.lowercased()
        return extensionToIcon[key] ?? "doc"
    }
    
    /// 生成指定扩展名的默认文件名
    static func generateDefaultFileName(for fileExtension: String) -> String {
        let key = fileExtension.lowercased()
        return extensionToDefaultName[key] ?? "新建文件.\(fileExtension)"
    }
    
    // 根据参数内容和类型智能推荐图标
    static func suggestIcon(for parameter: String, actionType: ActionType) -> String {
        let param = parameter.trimmingCharacters(in: .whitespacesAndNewlines)
        switch actionType {
        case .createEmptyFile:
            // 取扩展名
            let ext = param.lowercased()
            return DefaultNameUtils.iconForFileExtension(ext)
        case .createFileFromTemplate:
            // 取模板文件扩展名
            if let ext = param.split(separator: ".").last {
                return DefaultNameUtils.iconForFileExtension(String(ext))
            }
            return "doc"
        case .runShellScript:
            if param.hasSuffix(".sh") { return "terminal" }
            return "play"
        case .openWithApp:
            if param.hasSuffix(".app") { return "app" }
            return "app"
        case .createFolder:
            return "folder"
        case .copyFilePath, .cutFile:
            return "doc.on.doc"
        case .openTerminal:
            return "terminal"
        case .separator:
            return "minus"
        case .sendToDesktop:
            return "desktopcomputer"
        case .hashFile:
            return "hash"
        case .deleteFile:
            return "trash"
        case .showHiddenFiles:
            return "eye.slash"
        }
    }
}

extension Array where Element: Hashable {
    func removingDuplicates() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
