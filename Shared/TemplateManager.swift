//
//  TemplateManager.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import Foundation
import AppKit

/// 模板管理器，负责处理模板文件夹的Security-Scoped Bookmarks
class TemplateManager {
    
    // MARK: - App Group/Shared Paths
    
    /// App Group内 RightKit 目录
    private static var rightKitDirectoryURL: URL? {
        ConfigurationManager.rightKitBaseDirectoryURL
    }
    
    /// 进程标识（区分主应用与扩展）
    private static var processTag: String { isExtension ? "Extension" : "MainApp" }
    
    /// 是否为Extension进程
    private static var isExtension: Bool {
        Bundle.main.bundleIdentifier?.contains("Extension") == true
    }
    
    /// 存储模板文件夹书签的文件名（每个进程独立）
    private static let templateFolderBookmarkFileName = "templateFolderBookmark"
    
    /// 存储模板文件夹路径的文件名（跨进程共享）
    private static let templateFolderPathFileName = "templateFolderPath.txt"
    
    /// 获取bookmark存储文件的完整路径（每个进程独立）
    private static var bookmarkFileURL: URL? {
        guard let base = rightKitDirectoryURL else { return nil }
        return base.appendingPathComponent("\(processTag)_\(templateFolderBookmarkFileName)")
    }
    
    /// 获取路径存储文件的完整路径（跨进程共享）
    private static var pathFileURL: URL? {
        guard let base = rightKitDirectoryURL else { return nil }
        return base.appendingPathComponent(templateFolderPathFileName)
    }
    
    // MARK: - Public APIs
    
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
        
        // 2. 为当前进程创建bookmark
        guard url.startAccessingSecurityScopedResource() else {
            NSLog("Failed to access security scoped resource")
            return false
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let bookmarkData = try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
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
        // 1) 尝试从bookmark获取
        if let url = getTemplateFolderURLFromBookmark() { return url }
        
        // 2) 使用存储的纯文本路径
        guard let storedPath = getStoredTemplateFolderPath() else {
            NSLog("No stored template folder path found")
            return nil
        }
        let url = URL(fileURLWithPath: storedPath)
        
        // 路径是否仍然存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSLog("Stored template folder path no longer exists: \(storedPath)")
            return nil
        }
        
        if isExtension {
            // Extension直接尝试访问路径
            if canReadDirectory(at: url) {
                NSLog("Extension successfully accessed template folder: \(storedPath)")
                return url
            } else {
                NSLog("Extension failed to access template folder at: \(storedPath)")
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
                return (resourceValues?.isRegularFile == true) ? url.lastPathComponent : nil
            }.sorted()
            NSLog("Found \(templateFiles.count) template files: \(templateFiles)")
            return templateFiles
        } ?? []
    }
    
    /// 从模板创建文件
    static func createFileFromTemplate(templateName: String, targetDirectory: URL, newFileName: String? = nil) -> Bool {
        return executeWithTemplateAccess { templateURL in
            let sourceURL = templateURL.appendingPathComponent(templateName)
            guard FileManager.default.fileExists(atPath: sourceURL.path) else {
                NSLog("Template file does not exist: \(templateName)")
                return false
            }
            let finalFileName = newFileName ?? templateName
            let targetURL = targetDirectory.appendingPathComponent(finalFileName)
            let uniqueTargetURL = generateUniqueFileURL(baseURL: targetURL)
            try FileManager.default.copyItem(at: sourceURL, to: uniqueTargetURL)
            NSLog("File created from template: \(uniqueTargetURL.path)")
            return true
        } ?? false
    }
    
    /// 上传模板文件到模板文件夹
    static func uploadTemplate(from sourceURL: URL) -> Bool {
        return executeWithTemplateAccess { templateURL in
            // 检查源文件是否存在
            guard FileManager.default.fileExists(atPath: sourceURL.path) else {
                NSLog("Source file does not exist: \(sourceURL.path)")
                return false
            }
            
            // 访问源URL（如有需要）
            let sourceAccessing = sourceURL.startAccessingSecurityScopedResource()
            defer { if sourceAccessing { sourceURL.stopAccessingSecurityScopedResource() } }
            
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
                if let underlyingError = (error as NSError).userInfo[NSUnderlyingErrorKey] as? NSError {
                    NSLog("Underlying error: \(underlyingError)")
                }
                return false
            }
        } ?? false
    }
    
    /// 删除模板文件 - Extension优化版本
    static func deleteTemplate(_ templateName: String) -> Bool {
        return executeWithTemplateAccess { templateURL in
            let targetURL = templateURL.appendingPathComponent(templateName)
            guard FileManager.default.fileExists(atPath: targetURL.path) else {
                NSLog("Template file does not exist: \(templateName)")
                return false
            }
            try FileManager.default.removeItem(at: targetURL)
            NSLog("Template deleted successfully: \(templateName)")
            return true
        } ?? false
    }
    
    /// 初始化模板文件夹（检查配置状态，仅在未配置时弹窗）
    static func initializeTemplateFolder() {
        NSLog("Initializing template folder...")
        DispatchQueue.global(qos: .userInitiated).async {
            let isConfigured = getTemplateFolderURL() != nil
            if isConfigured {
                NSLog("Template folder already configured")
                return
            }
            NSLog("No valid template folder configured, prompting user to select...")
            // selectTemplateFolder 会自行切换到主线程
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
        selectTemplateFolder { success in
            if success {
                NSLog("User selected new template folder from UI")
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
    
    /// 检查模板文件夹是否已配置（轻量级检查，不进行文件系统访问）
    static func isTemplateFolderConfigured() -> Bool {
        return getStoredTemplateFolderPath() != nil
    }
    
    /// 异步检查模板文件夹是否可访问（用于后台验证）
    static func validateTemplateFolderAccess(completion: @escaping (Bool) -> Void) {
        DispatchQueue.global(qos: .utility).async {
            let isValid = getTemplateFolderURL() != nil
            DispatchQueue.main.async { completion(isValid) }
        }
    }
    
    /// 强制重新初始化到用户选择的目录（弹窗选择）
    static func forceReinitializeWithUserSelection() {
        NSLog("Force reinitializing template folder with user selection...")
        resetTemplateFolder()
        DispatchQueue.main.async { selectTemplateFolder { success in
            if success { NSLog("Template folder reinitialized with user selection") }
            else { NSLog("User cancelled template folder selection") }
        }}
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
        if let bookmarkURL = bookmarkFileURL,
           FileManager.default.fileExists(atPath: bookmarkURL.path) {
            do { try FileManager.default.removeItem(at: bookmarkURL); NSLog("Template folder bookmark file deleted for current process") }
            catch { NSLog("Error deleting bookmark file: \(error)") }
        }
        if !isExtension,
           let pathURL = pathFileURL,
           FileManager.default.fileExists(atPath: pathURL.path) {
            do { try FileManager.default.removeItem(at: pathURL); NSLog("Template folder path file deleted") }
            catch { NSLog("Error deleting path file: \(error)") }
        }
        NSLog("Template folder configuration reset")
    }
    
    /// 获取当前模板文件夹路径（用于显示）
    static func getCurrentTemplateFolderPath() -> String? {
        if let url = getTemplateFolderURLFromBookmark() { return url.path }
        return getStoredTemplateFolderPath()
    }
    
    /// 强制重新初始化到用户Documents目录
    static func forceReinitializeToUserDocuments() {
        NSLog("Force reinitializing template folder to user Documents...")
        resetTemplateFolder()
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let defaultTemplatesPath = homeDirectory
            .appendingPathComponent("Documents")
            .appendingPathComponent("RightKit")
            .appendingPathComponent("Templates")
        NSLog("Force reinitializing to path: \(defaultTemplatesPath.path)")
        createDefaultTemplateFolder(at: defaultTemplatesPath)
        if setTemplateFolder(defaultTemplatesPath) {
            NSLog("Template folder force reinitialized successfully: \(defaultTemplatesPath.path)")
        } else {
            NSLog("Failed to force reinitialize template folder")
        }
    }
    
    // MARK: - Private helpers
    
    /// 选择新的模板文件夹（确保在主线程上显示NSOpenPanel）
    static func selectTemplateFolder(completion: @escaping (Bool) -> Void) {
        // 确保在主线程展示
        if !Thread.isMainThread {
            DispatchQueue.main.async { selectTemplateFolder(completion: completion) }
            return
        }
        
        let openPanel = NSOpenPanel()
        openPanel.title = "选择模板文件夹"
        openPanel.message = "请选择用于存储模板文件的文件夹"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents")
        
        openPanel.begin { response in
            if response == .OK, let selectedURL = openPanel.url {
                NSLog("User selected template folder: \(selectedURL.path)")
                DispatchQueue.global(qos: .userInitiated).async {
                    let success = setTemplateFolder(selectedURL)
                    DispatchQueue.main.async { completion(success) }
                }
            } else {
                NSLog("User cancelled template folder selection")
                completion(false)
            }
        }
    }
    
    /// 从bookmark获取模板文件夹URL（私有方法）
    private static func getTemplateFolderURLFromBookmark() -> URL? {
        guard let bookmarkURL = bookmarkFileURL else {
            NSLog("Could not get App Group container URL")
            return nil
        }
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
                try? FileManager.default.removeItem(at: bookmarkURL)
                return nil
            }
            NSLog("Retrieved template folder from bookmark: \(url.path)")
            return url
        } catch {
            NSLog("Error resolving bookmark: \(error)")
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
        let needsSecurityScope = !isExtension && !templateURL.path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path)
        if needsSecurityScope {
            guard templateURL.startAccessingSecurityScopedResource() else {
                NSLog("Failed to access template folder")
                return nil
            }
        }
        defer { if needsSecurityScope { templateURL.stopAccessingSecurityScopedResource() } }
        do { return try operation(templateURL) }
        catch { NSLog("Template operation failed: \(error)"); return nil }
    }
    
    /// 生成唯一的文件URL（如果文件已存在，添加数字后缀："name 1.ext"）
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
    
    /// 生成唯一的模板URL（用于模板上传时避免重名："template1.ext"）
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
    
    /// 测试是否能读取目录内容（Extension直访验证）
    private static func canReadDirectory(at url: URL) -> Bool {
        do { _ = try FileManager.default.contentsOfDirectory(atPath: url.path); return true }
        catch { return false }
    }
}
