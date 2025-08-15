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
            createFile(filename: parameter.isEmpty ? "新建文件.txt" : parameter, in: targetURL)
        case "createFileFromTemplate":
            createFile(filename: parameter.isEmpty ? "新建文件.txt" : parameter, in: targetURL)
        case "createFolder":
            createFolder(name: parameter.isEmpty ? "新建文件夹" : parameter, in: targetURL)
        case "openTerminal":
            openTerminal(at: targetURL)
        default:
            NSLog("RightKit: Unknown action type: %@", actionType)
        }
    }
    
    func handleFallbackAction(menuTitle: String, targetURL: URL?, selectedItems: [URL]) {
        NSLog("RightKit: Handling fallback action for: %@", menuTitle)
        
        // 根据菜单标题推断动作
        if menuTitle.contains("空白文本文件") || menuTitle.contains("新建文件") {
            createFile(filename: "新建文件.txt", in: targetURL)
        } else if menuTitle.contains("Markdown") {
            createFile(filename: "新建文档.md", in: targetURL)
        } else if menuTitle.contains("文件夹") {
            createFolder(name: "新建文件夹", in: targetURL)
        } else if menuTitle.contains("终端") || menuTitle.contains("Terminal") {
            openTerminal(at: targetURL)
        } else {
            NSLog("RightKit: Could not infer action from menu title: %@", menuTitle)
        }
    }
    
    // MARK: - File Operations
    
    private func createFile(filename: String, in targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        
        // 生成唯一的文件名，处理重复文件
        let uniqueFileURL = generateUniqueFileURL(baseName: filename, in: targetDirectory)
        
        NSLog("RightKit: Creating file '%@' in directory: %@", uniqueFileURL.lastPathComponent, targetDirectory.path)
        
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
            
            NSLog("RightKit: Successfully selected file using effective method")
            
            // 延迟后尝试发送回车键激活重命名
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.attemptKeyboardRename(for: fileURL)
            }
        }
    }
    
    /// 尝试发送键盘事件激活重命名
    private func attemptKeyboardRename(for fileURL: URL) {
        NSLog("RightKit: Attempting keyboard rename activation")
        
        // 尝试更简单的AppleScript，避免复杂的应用程序引用
        let script = """
        delay 0.2
        tell application "System Events"
            keystroke return
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var errorDict: NSDictionary?
            appleScript.executeAndReturnError(&errorDict)
            
            if let error = errorDict {
                NSLog("RightKit: Keyboard event failed: %@", error.description)
                self.showRenameInstructions(for: fileURL)
            } else {
                NSLog("RightKit: Successfully sent keyboard event")
            }
        } else {
            self.showRenameInstructions(for: fileURL)
        }
    }
    
    /// 显示重命名指导通知
    private func showRenameInstructions(for fileURL: URL) {
        NSLog("RightKit: Showing rename instructions to user")
        // 确保文件在Finder中被选中
        let workspace = NSWorkspace.shared
        workspace.activateFileViewerSelecting([fileURL])
    }
}
