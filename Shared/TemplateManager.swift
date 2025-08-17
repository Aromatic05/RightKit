//
//  TemplateManager.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import Foundation
import SwiftUI

/// 模板管理器，负责处理模板文件夹的Security-Scoped Bookmarks
class TemplateManager {
    
    /// App Group ID - 与ConfigurationManager保持一致
    private static let appGroupID = "group.Aromatic.RightKit"
    
    /// 存储模板文件夹书签的文件名（每个进程独立）
    private static let templateFolderBookmarkFileName = "templateFolderBookmark"
    
    /// 存储模板文件夹路径的文件名（跨进程共享）
    private static let templateFolderPathFileName = "templateFolderPath.txt"
    
    /// 获取App Group容器URL
    private static var containerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
    
    /// 获取bookmark存储文件的完整路径（每个进程独立）
    private static var bookmarkFileURL: URL? {
        guard let containerURL = containerURL else { return nil }
        let processName = Bundle.main.bundleIdentifier?.contains("Extension") == true ? "Extension" : "MainApp"
        return containerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("RightKit")
            .appendingPathComponent("\(processName)_\(templateFolderBookmarkFileName)")
    }
    
    /// 获取路径存储文件的完整路径（跨进程共享）
    private static var pathFileURL: URL? {
        guard let containerURL = containerURL else { return nil }
        return containerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("RightKit")
            .appendingPathComponent(templateFolderPathFileName)
    }
    
    /// 设置模板文件夹并创建Security-Scoped Bookmark
    static func setTemplateFolder(_ url: URL) -> Bool {
        NSLog("Setting template folder: \(url.path)")
        
        // 检查路径是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSLog("Template folder path does not exist: \(url.path)")
            return false
        }
        
        // 获取文件URL
        guard let bookmarkURL = bookmarkFileURL,
              let pathURL = pathFileURL else {
            NSLog("Could not get App Group container URL")
            return false
        }
        
        // 创建目录结构（如果不存在）
        let directoryURL = bookmarkURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("Error creating bookmark directory: \(error)")
            return false
        }
        
        // 1. 先保存纯文本路径（跨进程共享）
        do {
            try url.path.write(to: pathURL, atomically: true, encoding: .utf8)
            NSLog("Template folder path saved to app group: \(url.path)")
        } catch {
            NSLog("Error saving template folder path: \(error)")
            return false
        }
        
        // 2. 然后为当前进程创建bookmark
        guard url.startAccessingSecurityScopedResource() else {
            NSLog("Failed to access security scoped resource")
            return false
        }
        
        defer {
            url.stopAccessingSecurityScopedResource()
        }
        
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
            
            // 将bookmark数据写入当前进程的文件
            try bookmarkData.write(to: bookmarkURL)
            
            NSLog("Template folder bookmark saved for current process: \(url.path)")
            return true
        } catch {
            NSLog("Error creating or saving bookmark: \(error)")
            return false
        }
    }
    
    /// 获取存储的模板文件夹路径（纯文本）
    static func getStoredTemplateFolderPath() -> String? {
        guard let pathURL = pathFileURL else {
            NSLog("Could not get App Group container URL")
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: pathURL.path) else {
            NSLog("No template folder path found")
            return nil
        }
        
        do {
            let path = try String(contentsOf: pathURL, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
            NSLog("Retrieved stored template folder path: \(path)")
            return path
        } catch {
            NSLog("Error reading template folder path: \(error)")
            return nil
        }
    }
    
    /// 获取模板文件夹URL
    static func getTemplateFolderURL() -> URL? {
        // 1. 首先尝试从当前进程的bookmark获取
        if let url = getTemplateFolderURLFromBookmark() {
            return url
        }
        
        // 2. Extension特殊处理：直接尝试访问存储的路径
        guard let storedPath = getStoredTemplateFolderPath() else {
            NSLog("No stored template folder path found")
            return nil
        }
        
        let url = URL(fileURLWithPath: storedPath)
        
        // 检查路径是否仍然存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSLog("Stored template folder path no longer exists: \(storedPath)")
            return nil
        }
        
        // 检查是否是Extension进程
        let isExtension = Bundle.main.bundleIdentifier?.contains("Extension") == true
        
        if isExtension {
            // Extension直接尝试访问路径，不需要重新授权
            NSLog("Extension directly accessing template folder: \(storedPath)")
            
            // 测试是否能够直接访问该路径
            do {
                let _ = try FileManager.default.contentsOfDirectory(atPath: url.path)
                NSLog("Extension successfully accessed template folder: \(storedPath)")
                return url
            } catch {
                NSLog("Extension failed to access template folder: \(error)")
                return nil
            }
        } else {
            // 主应用尝试重新授权并创建bookmark
            NSLog("MainApp attempting to re-authorize path: \(storedPath)")
            
            if setTemplateFolder(url) {
                NSLog("Successfully re-authorized template folder: \(storedPath)")
                return url
            } else {
                NSLog("Failed to re-authorize template folder: \(storedPath)")
                return nil
            }
        }
    }
    
    /// Extension专用：检查是否能直接访问模板文件夹
    static func canExtensionAccessTemplateFolder() -> Bool {
        guard Bundle.main.bundleIdentifier?.contains("Extension") == true else {
            return false
        }
        
        guard let storedPath = getStoredTemplateFolderPath() else {
            NSLog("Extension: No stored template folder path found")
            return false
        }
        
        let url = URL(fileURLWithPath: storedPath)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSLog("Extension: Stored template folder path no longer exists: \(storedPath)")
            return false
        }
        
        // 测试读取权限
        do {
            let _ = try FileManager.default.contentsOfDirectory(atPath: url.path)
            NSLog("Extension: Can directly access template folder: \(storedPath)")
            return true
        } catch {
            NSLog("Extension: Cannot access template folder: \(error)")
            return false
        }
    }
    
    /// 从bookmark获取模板文件夹URL（私有方法）
    private static func getTemplateFolderURLFromBookmark() -> URL? {
        guard let bookmarkURL = bookmarkFileURL else {
            NSLog("Could not get App Group container URL")
            return nil
        }
        
        // 检查bookmark文件是否存在
        guard FileManager.default.fileExists(atPath: bookmarkURL.path) else {
            NSLog("No template folder bookmark found for current process")
            return nil
        }
        
        do {
            let bookmarkData = try Data(contentsOf: bookmarkURL)
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                NSLog("Bookmark is stale for: \(url.path)")
                // 删除过期的bookmark文件
                try? FileManager.default.removeItem(at: bookmarkURL)
                return nil
            }
            
            NSLog("Retrieved template folder from bookmark: \(url.path)")
            return url
        } catch {
            NSLog("Error resolving bookmark: \(error)")
            // 删除无效的bookmark文件
            try? FileManager.default.removeItem(at: bookmarkURL)
            return nil
        }
    }
    
    /// 执行需要模板文件夹访问的操作（统一处理security-scoped资源）
    private static func executeWithTemplateAccess<T>(operation: (URL) throws -> T) -> T? {
        guard let templateURL = getTemplateFolderURL() else {
            NSLog("Template folder not configured")
            return nil
        }
        
        // Extension不需要security-scoped调用，主应用需要
        let isExtension = Bundle.main.bundleIdentifier?.contains("Extension") == true
        let needsSecurityScope = !isExtension && !templateURL.path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path)
        
        if needsSecurityScope {
            guard templateURL.startAccessingSecurityScopedResource() else {
                NSLog("Failed to access template folder")
                return nil
            }
        }
        
        defer {
            if needsSecurityScope {
                templateURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            return try operation(templateURL)
        } catch {
            NSLog("Template operation failed: \(error)")
            return nil
        }
    }
    
    /// 获取模板文件夹中的所有模板文件
    static func getTemplateFiles() -> [String] {
        return executeWithTemplateAccess { templateURL in
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: templateURL,
                includingPropertiesForKeys: [.isRegularFileKey],
                options: [.skipsHiddenFiles, .skipsSubdirectoryDescendants]
            )
            
            let templateFiles = fileURLs.compactMap { url -> String? in
                let resourceValues = try? url.resourceValues(forKeys: [.isRegularFileKey])
                if resourceValues?.isRegularFile == true {
                    return url.lastPathComponent
                }
                return nil
            }.sorted()
            
            NSLog("Found \(templateFiles.count) template files: \(templateFiles)")
            return templateFiles
        } ?? []
    }
    
    /// 从模板创建文件
    static func createFileFromTemplate(templateName: String, targetDirectory: URL, newFileName: String? = nil) -> Bool {
        return executeWithTemplateAccess { templateURL in
            let sourceURL = templateURL.appendingPathComponent(templateName)
            
            // 检查源文件是否存在
            guard FileManager.default.fileExists(atPath: sourceURL.path) else {
                NSLog("Template file does not exist: \(templateName)")
                return false
            }
            
            // 确定目标文件名
            let finalFileName = newFileName ?? templateName
            let targetURL = targetDirectory.appendingPathComponent(finalFileName)
            
            // 生成唯一文件名（如果文件已存在）
            let uniqueTargetURL = generateUniqueFileURL(baseURL: targetURL)
            
            try FileManager.default.copyItem(at: sourceURL, to: uniqueTargetURL)
            NSLog("File created from template: \(uniqueTargetURL.path)")
            return true
        } ?? false
    }
    
    /// 上传模板文件到模板文件夹
    static func uploadTemplate(from sourceURL: URL) -> Bool {
        guard let templateURL = getTemplateFolderURL() else {
            NSLog("Template folder not configured")
            return false
        }

        // 检查源文件是否存在
        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            NSLog("Source file does not exist: \(sourceURL.path)")
            return false
        }

        let sourceAccessing = sourceURL.startAccessingSecurityScopedResource()
        if !sourceAccessing {
            NSLog("Could not start accessing security scoped resource for source URL, but continuing: \(sourceURL.path)")
        }
        defer {
            if sourceAccessing {
                sourceURL.stopAccessingSecurityScopedResource()
            }
        }

        // 检查目标文件夹的访问权限
        let destinationAccessing = templateURL.startAccessingSecurityScopedResource()
        if !destinationAccessing {
            NSLog("Could not start accessing security scoped resource for destination URL, but continuing: \(templateURL.path)")
        }
        defer {
            if destinationAccessing {
                templateURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let fileExtension = sourceURL.pathExtension
        let targetFileName = fileExtension.isEmpty ? "template" : "template.\(fileExtension)"
        let targetURL = templateURL.appendingPathComponent(targetFileName)
        let uniqueTargetURL = generateUniqueTemplateURL(baseURL: targetURL)
        
        NSLog("Attempting to upload template from \(sourceURL.path) to \(uniqueTargetURL.path)")
        
        do {
            try FileManager.default.copyItem(at: sourceURL, to: uniqueTargetURL)
            NSLog("Template uploaded successfully: \(uniqueTargetURL.lastPathComponent)")
            return true
        } catch {
            NSLog("Error uploading template: \(error)")
            // 打印更详细的错误信息
            if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? NSError {
                NSLog("Underlying error: \(underlyingError)")
            }
            return false
        }
    }
    
    /// 删除模板文件 - Extension优化版本
    static func deleteTemplate(_ templateName: String) -> Bool {
        return executeWithTemplateAccess { templateURL in
            let targetURL = templateURL.appendingPathComponent(templateName)
            
            // 检查文件是否存在
            guard FileManager.default.fileExists(atPath: targetURL.path) else {
                NSLog("Template file does not exist: \(templateName)")
                return false
            }
            
            try FileManager.default.removeItem(at: targetURL)
            NSLog("Template deleted successfully: \(templateName)")
            return true
        } ?? false
    }
    
    /// 生成唯一的文件URL（如果文件已存在，添加数字后缀）
    private static func generateUniqueFileURL(baseURL: URL) -> URL {
        var counter = 1
        var currentURL = baseURL
        
        while FileManager.default.fileExists(atPath: currentURL.path) {
            let fileName = baseURL.deletingPathExtension().lastPathComponent
            let fileExtension = baseURL.pathExtension
            let newFileName = fileExtension.isEmpty ? "\(fileName) \(counter)" : "\(fileName) \(counter).\(fileExtension)"
            currentURL = baseURL.deletingLastPathComponent().appendingPathComponent(newFileName)
            counter += 1
        }
        
        return currentURL
    }
    
    /// 生成唯一的模板URL（用于模板上传时避免重名）
    private static func generateUniqueTemplateURL(baseURL: URL) -> URL {
        var counter = 1
        var currentURL = baseURL
        
        while FileManager.default.fileExists(atPath: currentURL.path) {
            let fileExtension = baseURL.pathExtension
            let newFileName = fileExtension.isEmpty ? "template\(counter)" : "template\(counter).\(fileExtension)"
            currentURL = baseURL.deletingLastPathComponent().appendingPathComponent(newFileName)
            counter += 1
        }
        
        return currentURL
    }
    
    /// 初始化模板文件夹（检查配置状态，仅在未配置时弹窗）
    static func initializeTemplateFolder() {
        NSLog("Initializing template folder...")
        
        // 检查当前是否有有效的模板文件夹配置
        if let currentURL = getTemplateFolderURL() {
            NSLog("Template folder already configured with valid path: \(currentURL.path)")
            return
        }
        
        NSLog("No valid template folder configured, prompting user to select...")
        
        // 弹出选择对话框让用户选择并授权访问路径
        DispatchQueue.main.async {
            selectTemplateFolder { success in
                if !success {
                    NSLog("User did not select template folder, will prompt again next time")
                }
            }
        }
    }
    
    /// 选择模板文件夹（总是弹窗，用于UI中的选择/更改按钮）
    static func selectTemplateFolderForUI(completion: @escaping (Bool) -> Void = { _ in }) {
        NSLog("UI requested template folder selection...")
        
        DispatchQueue.main.async {
            selectTemplateFolder { success in
                if success {
                    NSLog("User selected new template folder from UI")
                    // 发送通知让UI更新
                    NotificationCenter.default.post(
                        name: NSNotification.Name("TemplateFolderChanged"),
                        object: nil
                    )
                } else {
                    NSLog("User cancelled template folder selection from UI")
                }
                completion(success)
            }
        }
    }
    
    /// 检查模板文件夹是否已配置
    static func isTemplateFolderConfigured() -> Bool {
        return getTemplateFolderURL() != nil
    }
    
    /// 强制重新初始化到用户选择的目录（弹窗选择）
    static func forceReinitializeWithUserSelection() {
        NSLog("Force reinitializing template folder with user selection...")
        
        // 清理所有旧配置
        resetTemplateFolder()
        
        // 弹出选择对话框让用户选择新的路径
        DispatchQueue.main.async {
            selectTemplateFolder { success in
                if success {
                    NSLog("Template folder reinitialized with user selection")
                } else {
                    NSLog("User cancelled template folder selection")
                }
            }
        }
    }
    
    /// 选择新的模板文件夹
    static func selectTemplateFolder(completion: @escaping (Bool) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.title = "选择模板文件夹"
        openPanel.message = "请选择用于存储模板文件的文件夹"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        
        // 设置默认路径为用户Documents目录
        let documentsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Documents")
        openPanel.directoryURL = documentsPath
        
        openPanel.begin { response in
            if response == .OK, let selectedURL = openPanel.url {
                NSLog("User selected template folder: \(selectedURL.path)")
                let success = setTemplateFolder(selectedURL)
                DispatchQueue.main.async {
                    completion(success)
                }
            } else {
                NSLog("User cancelled template folder selection")
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    /// 在Finder中显示模板文件夹
    static func revealTemplateFolderInFinder() {
        guard let templateURL = getTemplateFolderURL() else {
            NSLog("Template folder not configured")
            return
        }
        
        NSWorkspace.shared.open(templateURL)
    }
    
    /// 重置模板文件夹配置
    static func resetTemplateFolder() {
        // 删除当前进程的bookmark文件
        if let bookmarkURL = bookmarkFileURL,
           FileManager.default.fileExists(atPath: bookmarkURL.path) {
            do {
                try FileManager.default.removeItem(at: bookmarkURL)
                NSLog("Template folder bookmark file deleted for current process")
            } catch {
                NSLog("Error deleting bookmark file: \(error)")
            }
        }
        
        // 删除共享的路径文件（只有主应用才应该删除这个）
        let isMainApp = Bundle.main.bundleIdentifier?.contains("Extension") != true
        if isMainApp,
           let pathURL = pathFileURL,
           FileManager.default.fileExists(atPath: pathURL.path) {
            do {
                try FileManager.default.removeItem(at: pathURL)
                NSLog("Template folder path file deleted")
            } catch {
                NSLog("Error deleting path file: \(error)")
            }
        }
        
        NSLog("Template folder configuration reset")
    }
    
    /// 获取当前模板文件夹路径（用于显示）
    static func getCurrentTemplateFolderPath() -> String? {
        // 优先从bookmark获取，fallback到存储的路径
        if let url = getTemplateFolderURLFromBookmark() {
            return url.path
        }
        return getStoredTemplateFolderPath()
    }
    
    /// 强制重新初始化到用户Documents目录
    static func forceReinitializeToUserDocuments() {
        NSLog("Force reinitializing template folder to user Documents...")
        
        // 清理所有旧配置
        resetTemplateFolder()
        
        // 使用用户的Documents目录
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let defaultTemplatesPath = homeDirectory
            .appendingPathComponent("Documents")
            .appendingPathComponent("RightKit")
            .appendingPathComponent("Templates")
        
        NSLog("Force reinitializing to path: \(defaultTemplatesPath.path)")
        
        // 创建文件夹
        createDefaultTemplateFolder(at: defaultTemplatesPath)
        
        // 设置模板文件夹
        if setTemplateFolder(defaultTemplatesPath) {
            NSLog("Template folder force reinitialized successfully: \(defaultTemplatesPath.path)")
        } else {
            NSLog("Failed to force reinitialize template folder")
        }
    }
    
    /// 创建默认模板文件夹
    private static func createDefaultTemplateFolder(at url: URL) {
        do {
            try FileManager.default.createDirectory(
                at: url,
                withIntermediateDirectories: true,
                attributes: nil
            )
            NSLog("Created default template folder at: \(url.path)")
        } catch {
            NSLog("Failed to create default template folder: \(error)")
        }
    }
}
