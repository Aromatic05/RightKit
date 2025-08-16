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
            cutFile(selectedItems: selectedItems)
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
        
        // 根据扩展名生成默认文件名
        let defaultFileName = generateDefaultFileName(for: fileExtension)
        
        // 生成唯一的文件名，处理重复文件
        let uniqueFileURL = generateUniqueFileURL(baseName: defaultFileName, in: targetDirectory)
        
        NSLog("RightKit: Creating file from template '%@' in directory: %@", uniqueFileURL.lastPathComponent, targetDirectory.path)
        
        // 获取模板内容
        let templateContent = generateTemplateContent(for: fileExtension, fileName: uniqueFileURL.deletingPathExtension().lastPathComponent)
        
        // 创建文件
        let fileManager = FileManager.default
        let success = fileManager.createFile(atPath: uniqueFileURL.path, contents: templateContent.data(using: .utf8), attributes: nil)
        
        if success {
            NSLog("RightKit: Successfully created file from template: %@", uniqueFileURL.lastPathComponent)
            
            // 激活重命名功能
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.activateFileRename(for: uniqueFileURL)
            }
        } else {
            NSLog("RightKit: Failed to create file from template: %@", uniqueFileURL.lastPathComponent)
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
    
    private func cutFile(selectedItems: [URL]) {
        guard !selectedItems.isEmpty else {
            NSLog("RightKit: No files selected for cutting")
            return
        }
        
        NSLog("RightKit: Cutting %d file(s)", selectedItems.count)
        
        // 获取系统剪贴板
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // 创建文件URL数组用于剪贴板
        var fileURLs: [URL] = []
        var filePaths: [String] = []
        
        for url in selectedItems {
            fileURLs.append(url)
            filePaths.append(url.path)
        }
        
        // 设置剪贴板内容 - 使用多种格式以确保兼容性
        pasteboard.setPropertyList(filePaths, forType: .fileURL)
        
        // 设置剪切操作标记 (用于标识这是剪切而不是复制)
        let cutFlag = Data([1]) // 1表示剪切，0表示复制
        pasteboard.setData(cutFlag, forType: NSPasteboard.PasteboardType("com.apple.pasteboard.promised-file-content-type"))
        
        // 记录要剪切的文件路径用于后续移动操作
        UserDefaults.standard.set(filePaths, forKey: "RightKit.CutFiles")
        UserDefaults.standard.synchronize()
        
        NSLog("RightKit: Successfully cut files to clipboard: %@", filePaths.joined(separator: ", "))
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
    
    /// 根据模板扩展名生成文件内容
    private func generateTemplateContent(for fileExtension: String, fileName: String) -> String {
        // 根据扩展名返回对应的模板内容
        switch fileExtension {
        case "swift":
            return "// 这是一个 Swift 文件模板\n\nimport Foundation\n\n// TODO: 在此处添加代码\n"
        case "txt":
            return "这是一个文本文件模板。\n\n请在此处添加内容。"
        case "md":
            return "# 这是一个 Markdown 文件模板\n\n请在此处添加内容。"
        default:
            return "// 未知文件类型，请手动添加内容。"
        }
    }
}
