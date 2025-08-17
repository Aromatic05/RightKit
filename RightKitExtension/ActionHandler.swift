//
//  ActionHandler.swift
//  RightKitExtension
//
//  Created by Yiming Sun on 2025/8/15.
//

import Foundation
import Cocoa
import FinderSync

class ActionHandler {
    static let shared = ActionHandler()
    
    private init() {}
    
    // MARK: - Action Handling
    
    func handleAction(actionString: String, targetURL: URL?, selectedItems: [URL]) {
        let components = actionString.components(separatedBy: "|")
        guard components.count >= 1 else {
            NSLog("RightKit: Invalid action string format")
            return
        }
        
        let actionType = components[0]
        let parameter = components.count > 1 ? components[1] : ""
        
        NSLog("RightKit: Executing action type: %@, parameter: %@", actionType, parameter)
        
        switch actionType {
        case "createEmptyFile":
            createEmptyFile(extension: parameter.isEmpty ? "txt" : parameter, in: targetURL)
        case "createFileFromTemplate":
            createFileFromTemplate(extension: parameter.isEmpty ? "txt" : parameter, in: targetURL)
        case "createFolder":
            createFolder(name: parameter.isEmpty ? "新建文件夹" : parameter, in: targetURL)
        case "openTerminal":
            openTerminal(at: targetURL)
        case "copyFilePath":
            copyFilePath(targetURL: targetURL, selectedItems: selectedItems)
        case "cutFile":
            cutOrPaste(targetURL: targetURL, selectedItems: selectedItems)
        default:
            NSLog("RightKit: Unknown action type: %@", actionType)
        }
    }
    
    // MARK: - File Operations
    
    private func createEmptyFile(extension fileExtension: String, in targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        
        // 根据扩展名生成默认文件名
        let defaultFileName = generateDefaultFileName(for: fileExtension)
        
        // 生成唯一的文件名，处理重复文件
        let uniqueFileURL = generateUniqueFileURL(baseName: defaultFileName, in: targetDirectory)
        
        NSLog("RightKit: Creating empty file '%@' in directory: %@", uniqueFileURL.lastPathComponent, targetDirectory.path)
        
        // 直接使用 FileManager 创建空文件
        let fileManager = FileManager.default
        let success = fileManager.createFile(atPath: uniqueFileURL.path, contents: nil, attributes: nil)
        
        if success {
            NSLog("RightKit: Successfully created file: %@", uniqueFileURL.lastPathComponent)
            
            // 激活重命名功能
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.activateFileRename(for: uniqueFileURL)
            }
        } else {
            NSLog("RightKit: Failed to create file: %@", uniqueFileURL.lastPathComponent)
        }
    }
    
    private func createFileFromTemplate(extension fileExtension: String, in targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        let defaultFileName = generateDefaultFileName(for: fileExtension)
        let uniqueFileURL = generateUniqueFileURL(baseName: defaultFileName, in: targetDirectory)
        NSLog("RightKit: Creating file from template '%@' in directory: %@", uniqueFileURL.lastPathComponent, targetDirectory.path)
        let templateFileName = "template.\(fileExtension)"
        var templateCopied = false
        if let templateFolderURL = TemplateManager.getTemplateFolderURL(),
           templateFolderURL.startAccessingSecurityScopedResource() {
            defer { templateFolderURL.stopAccessingSecurityScopedResource() }
            let templateFileURL = templateFolderURL.appendingPathComponent(templateFileName)
            if FileManager.default.fileExists(atPath: templateFileURL.path) {
                do {
                    try FileManager.default.copyItem(at: templateFileURL, to: uniqueFileURL)
                    NSLog("RightKit: Successfully copied template file from: %@", templateFileName)
                    templateCopied = true
                } catch {
                    NSLog("RightKit: Error copying template file: %@", error.localizedDescription)
                }
            } else {
                NSLog("RightKit: Template file does not exist: %@", templateFileName)
            }
        } else {
            NSLog("RightKit: Template folder not configured or cannot access")
        }
        if templateCopied {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.activateFileRename(for: uniqueFileURL)
            }
        } else {
            NSLog("RightKit: Template file not found, falling back to creating empty file")
            let fileManager = FileManager.default
            let success = fileManager.createFile(atPath: uniqueFileURL.path, contents: nil, attributes: nil)
            if success {
                NSLog("RightKit: Successfully created empty file as fallback: %@", uniqueFileURL.lastPathComponent)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.activateFileRename(for: uniqueFileURL)
                }
            } else {
                NSLog("RightKit: Failed to create file: %@", uniqueFileURL.lastPathComponent)
            }
        }
    }
    
    private func createFolder(name: String, in targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        
        // 生成唯一的文件夹名，处理重复文件夹
        let uniqueFolderURL = generateUniqueFolderURL(baseName: name, in: targetDirectory)
        
        NSLog("RightKit: Creating folder '%@' at: %@", uniqueFolderURL.lastPathComponent, targetDirectory.path)
        
        do {
            try FileManager.default.createDirectory(at: uniqueFolderURL, withIntermediateDirectories: false, attributes: nil)
            NSLog("RightKit: Successfully created folder: %@", uniqueFolderURL.lastPathComponent)
            
            // 激活重命名功能
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.activateFileRename(for: uniqueFolderURL)
            }
        } catch {
            NSLog("RightKit: Error creating folder: %@", error.localizedDescription)
        }
    }
    
    private func openTerminal(at targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        
        NSLog("RightKit: Opening terminal at: %@", targetDirectory.path)
        
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(targetDirectory.path)'"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var errorDict: NSDictionary?
            appleScript.executeAndReturnError(&errorDict)
            
            if let error = errorDict {
                NSLog("RightKit: Error opening terminal: %@", error.description)
            } else {
                NSLog("RightKit: Successfully opened terminal")
            }
        }
    }
    
    private func copyFilePath(targetURL: URL?, selectedItems: [URL]) {
        var pathsToCopy: [String] = []
        
        // 如果有选中的文件，复制选中文件的路径
        if !selectedItems.isEmpty {
            pathsToCopy = selectedItems.map { $0.path }
            NSLog("RightKit: Copying paths of selected items: %@", pathsToCopy.joined(separator: ", "))
        }
        // 如果没有选中文件但有目标URL，复制目标目录的路径
        else if let targetURL = targetURL {
            pathsToCopy = [targetURL.path]
            NSLog("RightKit: Copying target directory path: %@", targetURL.path)
        }
        // 如果都没有，复制当前用户目录
        else {
            let homeDirectory = NSHomeDirectory()
            pathsToCopy = [homeDirectory]
            NSLog("RightKit: Copying home directory path: %@", homeDirectory)
        }
        
        // 将路径复制到剪贴板
        let pathsString = pathsToCopy.joined(separator: "\n")
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(pathsString, forType: .string)
        
        NSLog("RightKit: Successfully copied %d path(s) to clipboard", pathsToCopy.count)
    }
    
    // MARK: - Helper Methods
    
    /// 生成唯一的文件URL，处理重复文件名
    private func generateUniqueFileURL(baseName: String, in directory: URL) -> URL {
        let fileManager = FileManager.default
        let baseURL = directory.appendingPathComponent(baseName)
        
        // 如果文件不存在，直接返回原始名称
        if !fileManager.fileExists(atPath: baseURL.path) {
            return baseURL
        }
        
        // 分离文件名和扩展名
        let nameWithoutExtension = (baseName as NSString).deletingPathExtension
        let fileExtension = (baseName as NSString).pathExtension
        
        // 生成带数字后缀的唯一文件名
        var counter = 1
        var uniqueURL: URL
        
        repeat {
            let uniqueName: String
            if fileExtension.isEmpty {
                uniqueName = "\(nameWithoutExtension) \(counter)"
            } else {
                uniqueName = "\(nameWithoutExtension) \(counter).\(fileExtension)"
            }
            uniqueURL = directory.appendingPathComponent(uniqueName)
            counter += 1
        } while fileManager.fileExists(atPath: uniqueURL.path)
        
        return uniqueURL
    }
    
    // MARK: - Cut / Paste
    
    /// 切换剪切/粘贴：有待粘贴则执行粘贴，否则开始剪切
    private func cutOrPaste(targetURL: URL?, selectedItems: [URL]) {
        if CutPasteState.shared.hasPendingCut() {
            pasteFiles(to: targetURL)
        } else {
            beginCut(selectedItems: selectedItems)
        }
    }
    
    /// 开始剪切：记录状态并写入粘贴板标记
    private func beginCut(selectedItems: [URL]) {
        guard !selectedItems.isEmpty else {
            NSLog("RightKit: No files selected for cutting")
            return
        }
        CutPasteState.shared.beginCut(urls: selectedItems)
        NSLog("RightKit: Cut set with %d item(s)", selectedItems.count)
    }
    
    /// 粘贴：将待剪切文件移动到目标目录，处理冲突与跨卷
    private func pasteFiles(to targetURL: URL?) {
        let pending = CutPasteState.shared.pendingCutURLs()
        guard !pending.isEmpty else {
            NSLog("RightKit: No pending cut to paste")
            return
        }
        let destDir = resolvePasteDestination(targetURL)
        NSLog("RightKit: Pasting %d item(s) to: %@", pending.count, destDir.path)
        
        var movedTargets: [URL] = []
        for src in pending {
            do {
                let dest = makeUniqueDestination(for: src, in: destDir)
                try moveItemSmart(from: src, to: dest)
                movedTargets.append(dest)
                NSLog("RightKit: Moved '%@' -> '%@'", src.lastPathComponent, dest.lastPathComponent)
            } catch {
                NSLog("RightKit: Paste failed for '%@': %@", src.path, error.localizedDescription)
            }
        }
        
        // 清除剪切状态
        CutPasteState.shared.clear()
        
        // 在 Finder 中选中粘贴后的项目
        if let first = movedTargets.first {
            let root = first.deletingLastPathComponent().path
            for url in movedTargets {
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: root)
            }
        }
    }
    
    private func resolvePasteDestination(_ targetURL: URL?) -> URL {
        let fm = FileManager.default
        var dir = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: dir.path, isDirectory: &isDir), !isDir.boolValue {
            dir = dir.deletingLastPathComponent()
        }
        return dir
    }
    
    private func makeUniqueDestination(for source: URL, in directory: URL) -> URL {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        fm.fileExists(atPath: source.path, isDirectory: &isDir)
        let baseName = source.lastPathComponent
        if isDir.boolValue {
            return generateUniqueFolderURL(baseName: baseName, in: directory)
        } else {
            return generateUniqueFileURL(baseName: baseName, in: directory)
        }
    }
    
    /// Move with cross-volume fallback (copy+remove)
    private func moveItemSmart(from src: URL, to dst: URL) throws {
        let fm = FileManager.default
        // If same parent directory, moving to new name is a rename; allow unique name already handled.
        do {
            try fm.moveItem(at: src, to: dst)
        } catch {
            // Try copy and delete as a fallback (e.g., EXDEV)
            do {
                try fm.copyItem(at: src, to: dst)
                try fm.removeItem(at: src)
            } catch {
                throw error
            }
        }
    }
    
    /// 生成唯一的文件夹URL，处理重复文件夹名
    private func generateUniqueFolderURL(baseName: String, in directory: URL) -> URL {
        let fileManager = FileManager.default
        let baseURL = directory.appendingPathComponent(baseName)
        
        // 如果文件夹不存在，直接返回原始名称
        if !fileManager.fileExists(atPath: baseURL.path) {
            return baseURL
        }
        
        // 生成带数字后缀的唯一文件夹名
        var counter = 1
        var uniqueURL: URL
        
        repeat {
            let uniqueName = "\(baseName) \(counter)"
            uniqueURL = directory.appendingPathComponent(uniqueName)
            counter += 1
        } while fileManager.fileExists(atPath: uniqueURL.path)
        
        return uniqueURL
    }
    
    /// 激活文件/文件夹的重命名功能 - 使用有效的方法
    private func activateFileRename(for fileURL: URL) {
        NSLog("RightKit: Attempting to activate rename for: %@", fileURL.path)
        
        // 使用有效的方法：直接在目标目录中选中文件
        DispatchQueue.main.async {
            let targetDirectory = fileURL.deletingLastPathComponent()
            NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: targetDirectory.path)
        }
    }
    
    /// 生成指定扩展名的默认文件名
    private func generateDefaultFileName(for fileExtension: String) -> String {
        // 根据文件类型生成简洁的默认名称
        switch fileExtension.lowercased() {
        case "txt":
            return "新建文本文件.txt"
        case "swift":
            return "新建Swift文件.swift"
        case "md":
            return "新建Markdown文件.md"
        case "json":
            return "新建JSON文件.json"
        case "py":
            return "新建Python文件.py"
        case "js":
            return "新建JavaScript文件.js"
        case "html":
            return "新建HTML文件.html"
        case "css":
            return "新建CSS文件.css"
        default:
            return "新建文件.\(fileExtension)"
        }
    }
}
