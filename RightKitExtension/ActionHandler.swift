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
            createFileFromTemplate(parameter: parameter.isEmpty ? "template.txt" : parameter, in: targetURL)
        case "createFolder":
            createFolder(name: parameter.isEmpty ? "新建文件夹" : parameter, in: targetURL)
        case "openTerminal":
            openTerminal(at: selectedItems.first ?? targetURL)
        case "copyFilePath":
            copyFilePath(targetURL: targetURL, selectedItems: selectedItems)
        case "runShellScript":
            runShellScript(scriptPath: parameter, at: targetURL)
        case "cutFile":
            cutOrPaste(targetURL: targetURL, selectedItems: selectedItems)
        case "openWithApp":
            openWithApp(appUrl: URL(filePath: parameter), targetURL: selectedItems.first ?? targetURL)
        case "sendToDesktop":
            sendToDesktop(targetURL: selectedItems.first ?? targetURL)
        case "hashFile":
            calcFileHash(targetURL: selectedItems.first ?? targetURL)
        case "deleteFile":
            deleteFiles(selectedItems: selectedItems)
        case "showHiddenFiles":
            showHiddenFiles()
        default:
            NSLog("RightKit: Unknown action type: %@", actionType)
        }
    }
    
    // MARK: - File Operations
    
    private func createEmptyFile(extension fileExtension: String, in targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        
        // 根据扩展名生成默认文件名
        let defaultFileName = DefaultNameUtils.generateDefaultFileName(for: fileExtension)
        
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
    
    private func createFileFromTemplate(parameter: String, in targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        var templateFileName: String
        var targetFileName: String
        
        // 判断参数是扩展名还是完整文件名
        if parameter.isEmpty {
            templateFileName = "template.txt"
            targetFileName = DefaultNameUtils.generateDefaultFileName(for: "txt")
        } else if !parameter.contains(".") && parameter.range(of: "[^a-zA-Z0-9]", options: .regularExpression) == nil {
            // 仅为扩展名且无特殊字符
            templateFileName = "template.\(parameter)"
            targetFileName = DefaultNameUtils.generateDefaultFileName(for: parameter)
        } else {
            // 认为是完整文件名
            templateFileName = parameter
            targetFileName = parameter
        }
        let uniqueFileURL = generateUniqueFileURL(baseName: targetFileName, in: targetDirectory)
        NSLog("RightKit: Creating file from template '%@' in directory: %@", uniqueFileURL.lastPathComponent, targetDirectory.path)
        var templateCopied = false

        if let templateFolderURL = TemplateManager.getTemplateFolderURL() {
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.activateFileRename(for: uniqueFileURL)
            }
        } else {
            NSLog("RightKit: Template file not found, falling back to creating empty file")
            let fileManager = FileManager.default
            let success = fileManager.createFile(atPath: uniqueFileURL.path, contents: nil, attributes: nil)
            if success {
                NSLog("RightKit: Successfully created empty file as fallback: %@", uniqueFileURL.lastPathComponent)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
        let uniqueFolderURL = targetDirectory.appendingPathComponent(name)
        var finalFolderURL = uniqueFolderURL
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: uniqueFolderURL.path) {
            // 自动加数字后缀
            var counter = 1
            repeat {
                let candidate = targetDirectory.appendingPathComponent("\(name) \(counter)")
                if !fileManager.fileExists(atPath: candidate.path) {
                    finalFolderURL = candidate
                    break
                }
                counter += 1
            } while true
        }
        NSLog("RightKit: Creating folder '%@' at: %@", finalFolderURL.lastPathComponent, targetDirectory.path)
        do {
            try fileManager.createDirectory(at: finalFolderURL, withIntermediateDirectories: false, attributes: nil)
            NSLog("RightKit: Successfully created folder: %@", finalFolderURL.lastPathComponent)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.activateFileRename(for: finalFolderURL)
            }
        } catch {
            NSLog("RightKit: Error creating folder: %@", error.localizedDescription)
        }
    }
    
    private func getTerminal() -> String {
        ConfigurationManager.ensureDetectScriptExists()
        let scriptURL = ConfigurationManager.detectScriptURL
        let appURL = scriptURL.flatMap { NSWorkspace.shared.urlForApplication(toOpen: $0) }
        let terminalAppPath = appURL?.path ?? "Terminal"
        return terminalAppPath
    }
    
    private func openTerminal(at targetURL: URL?) {
        // 优先使用目标目录，如果是文件则取父目录
        var targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        var isDirectory: ObjCBool = false
        if let url = targetURL, !FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) || !isDirectory.boolValue {
            targetDirectory = url.deletingLastPathComponent()
        }
        NSLog("RightKit: Opening terminal at: %@ (using user's default .sh handler)", targetDirectory.path)
        // 确保检测脚本存在
        let terminalAppPath = getTerminal()
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = ["-a", terminalAppPath, targetDirectory.path]
        process.launch()
    }
    
    private func runShellScript(scriptPath: String, at targetURL: URL?) {
        var target = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        let process = Process()
        process.launchPath = "/usr/bin/open"
        process.arguments = ["-a", "Terminal", scriptPath]
        process.launch()
    }
    
    private func openWithApp(appUrl: URL, targetURL: URL?) {
        guard let fileURL = targetURL else {
            NSLog("RightKit: openWithApp called with nil targetURL")
            return
        }
        NSLog("RightKit: Opening %@ with app at %@", fileURL.path, appUrl.path)
        let configuration = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([fileURL], withApplicationAt: appUrl, configuration: configuration) { app, error in
            if let error = error {
                NSLog("RightKit: Failed to open %@ with app %@: %@", fileURL.path, appUrl.path, error.localizedDescription)
            } else if app == nil {
                NSLog("RightKit: App launched but NSRunningApplication is nil for %@ with app %@", fileURL.path, appUrl.path)
            } else {
                NSLog("RightKit: Successfully opened %@ with app %@", fileURL.path, appUrl.path)
            }
        }
    }
    
    private func sendToDesktop(targetURL: URL?) {
        guard let targetURL = targetURL else {
            NSLog("RightKit: sendToDesktop called with nil targetURL")
            return
        }
        let fileManager = FileManager.default
        // 获取桌面路径
        guard let desktopURL = fileManager.urls(for: .desktopDirectory, in: .userDomainMask).first else {
            NSLog("RightKit: Failed to get Desktop directory")
            return
        }
        // 生成快捷方式名称
        let shortcutName = targetURL.lastPathComponent + " 别名"
        var shortcutURL = desktopURL.appendingPathComponent(shortcutName)
        var counter = 1
        // 保证名称唯一
        while fileManager.fileExists(atPath: shortcutURL.path) {
            let newName = targetURL.deletingPathExtension().lastPathComponent + " 别名" + (counter > 1 ? " " + String(counter) : "")
            let ext = targetURL.pathExtension
            let finalName = ext.isEmpty ? newName : newName + "." + ext
            shortcutURL = desktopURL.appendingPathComponent(finalName)
            counter += 1
        }
        do {
            try fileManager.createSymbolicLink(at: shortcutURL, withDestinationURL: targetURL)
            NSLog("RightKit: Successfully created desktop shortcut at %@", shortcutURL.path)
        } catch {
            NSLog("RightKit: Failed to create desktop shortcut: %@", error.localizedDescription)
        }
    }
    
    private func calcFileHash(targetURL: URL?) {
        guard let url = targetURL else {
            NSLog("RightKit: calcFileHash called with nil targetURL")
            return
        }
        
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSLog("RightKit: File does not exist: \(url.path)")
            return
        }
        
        // 构建 URL Scheme 调用 RightKitHelper
        var components = URLComponents()
        components.scheme = "hashcalculator-helper"
        components.host = "calculate-hash"
        components.queryItems = [URLQueryItem(name: "filePath", value: url.path)]
        
        guard let schemeURL = components.url else {
            NSLog("RightKit: Failed to create URL scheme for hash calculation")
            return
        }
        
        NSLog("RightKit: Opening hash calculator with URL: \(schemeURL.absoluteString)")
        
        // 使用 NSWorkspace 打开 URL Scheme
        NSWorkspace.shared.open(schemeURL)
    }
    
    private func deleteFiles(selectedItems: [URL]) {
        guard !selectedItems.isEmpty else {
            NSLog("RightKit: deleteFiles called with empty selection")
            return
        }
//        DispatchQueue.main.async {
//            let alert = NSAlert()
//            alert.messageText = "确认永久删除?"
//            alert.informativeText = "此操作无法撤销，将永久删除所选文件。"
//            alert.alertStyle = .warning
//            alert.addButton(withTitle: "删除")
//            alert.addButton(withTitle: "取消")
//            let response = alert.runModal()
//            if response == .alertFirstButtonReturn {
//                let fileManager = FileManager.default
//                for url in selectedItems {
//                    do {
//                        try fileManager.removeItem(at: url)
//                        NSLog("RightKit: Permanently deleted %@", url.path)
//                    } catch {
//                        NSLog("RightKit: Failed to delete %@: %@", url.path, error.localizedDescription)
//                    }
//                }
//            } else {
//                NSLog("RightKit: User cancelled permanent delete")
//            }
//        }
    }
    
    private func showHiddenFiles() {
        // 切换 Finder 的隐藏文件显示状态
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        let currentState = UserDefaults.standard.bool(forKey: "AppleShowAllFiles")
        let newState = !currentState
        let value = newState ? "TRUE" : "FALSE"
        let script = "defaults write com.apple.finder AppleShowAllFiles -bool \(value); killall Finder"
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", script]
        task.launch()
        task.waitUntilExit()
        UserDefaults.standard.set(newState, forKey: "AppleShowAllFiles")
        NSLog("RightKit: Set AppleShowAllFiles to %@ and restarted Finder", value)
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
    
    // MARK: - Cut / Paste
    /// 切换剪切/粘贴：有待粘贴则执行粘贴，否则开始剪切
    private func cutOrPaste(targetURL: URL?, selectedItems: [URL]) {
        CutPasteState.shared.cutOrPaste(targetURL: targetURL, selectedItems: selectedItems)
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
}
