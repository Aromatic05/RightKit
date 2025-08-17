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
    
    /// 存储模板文件夹书签的UserDefaults键
    private static let templateFolderBookmarkKey = "templateFolderBookmark"
    private static let templateFolderPathKey = "templateFolderPath" // 备用存储路径
    
    /// 设置模板文件夹并创建Security-Scoped Bookmark
    static func setTemplateFolder(_ url: URL) -> Bool {
        NSLog("Setting template folder: \(url.path)")
        
        // 检查路径是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            NSLog("Template folder path does not exist: \(url.path)")
            return false
        }
        
        // 对于应用沙盒内的路径，直接存储路径而不是使用 bookmark
        let isInAppContainer = url.path.contains("/Library/Containers/\(Bundle.main.bundleIdentifier ?? "")")
        
        if isInAppContainer {
            // 应用沙盒内的路径，直接存储
            UserDefaults.standard.set(url.path, forKey: templateFolderPathKey)
            UserDefaults.standard.removeObject(forKey: templateFolderBookmarkKey) // 清除旧的 bookmark
            UserDefaults.standard.synchronize()
            NSLog("Template folder path saved (sandbox): \(url.path)")
            return true
        } else {
            // 沙盒外的路径，使用 security-scoped bookmark
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
                
                UserDefaults.standard.set(bookmarkData, forKey: templateFolderBookmarkKey)
                UserDefaults.standard.removeObject(forKey: templateFolderPathKey) // 清除旧的路径
                UserDefaults.standard.synchronize()
                
                NSLog("Template folder bookmark saved (security-scoped): \(url.path)")
                return true
            } catch {
                NSLog("Error creating bookmark: \(error)")
                return false
            }
        }
    }
    
    /// 获取模板文件夹URL
    static func getTemplateFolderURL() -> URL? {
        // 优先检查是否有直接存储的路径（沙盒内）
        if let savedPath = UserDefaults.standard.string(forKey: templateFolderPathKey) {
            let url = URL(fileURLWithPath: savedPath)
            if FileManager.default.fileExists(atPath: url.path) {
                NSLog("Retrieved template folder from saved path: \(url.path)")
                return url
            } else {
                NSLog("Saved path no longer exists, clearing: \(savedPath)")
                UserDefaults.standard.removeObject(forKey: templateFolderPathKey)
                UserDefaults.standard.synchronize()
            }
        }
        
        // 检查是否有 bookmark 数据（沙盒外）
        guard let bookmarkData = UserDefaults.standard.data(forKey: templateFolderBookmarkKey) else {
            NSLog("No template folder bookmark or path found")
            return nil
        }
        
        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
            
            if isStale {
                NSLog("Bookmark is stale for: \(url.path)")
                // 不要在这里立即尝试重新创建，而是返回nil让上层处理
                return nil
            }
            
            NSLog("Retrieved template folder from bookmark: \(url.path)")
            return url
        } catch {
            NSLog("Error resolving bookmark: \(error)")
            UserDefaults.standard.removeObject(forKey: templateFolderBookmarkKey)
            UserDefaults.standard.synchronize()
            return nil
        }
    }
    
    /// 获取模板文件夹中的所有模板文件
    static func getTemplateFiles() -> [String] {
        guard let templateURL = getTemplateFolderURL() else {
            NSLog("Template folder not configured")
            return []
        }
        
        let needsSecurityScope = !templateURL.path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path)
        
        if needsSecurityScope {
            guard templateURL.startAccessingSecurityScopedResource() else {
                NSLog("Failed to access template folder")
                return []
            }
        }
        
        defer {
            if needsSecurityScope {
                templateURL.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
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
            }.sorted() // 添加排序以保持一致性
            
            NSLog("Found \(templateFiles.count) template files: \(templateFiles)")
            return templateFiles
        } catch {
            NSLog("Error reading template folder: \(error)")
            return []
        }
    }
    
    /// 从模板创建文件
    static func createFileFromTemplate(templateName: String, targetDirectory: URL, newFileName: String? = nil) -> Bool {
        guard let templateURL = getTemplateFolderURL() else {
            NSLog("Template folder not configured")
            return false
        }
        
        let needsSecurityScope = !templateURL.path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path)
        
        if needsSecurityScope {
            guard templateURL.startAccessingSecurityScopedResource() else {
                NSLog("Failed to access template folder")
                return false
            }
        }
        
        defer {
            if needsSecurityScope {
                templateURL.stopAccessingSecurityScopedResource()
            }
        }
        
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
        
        do {
            try FileManager.default.copyItem(at: sourceURL, to: uniqueTargetURL)
            NSLog("File created from template: \(uniqueTargetURL.path)")
            return true
        } catch {
            NSLog("Error creating file from template: \(error)")
            return false
        }
    }
    
    /// 上传模板文件到模板文件夹
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
    
    /// 删除模板文件
    static func deleteTemplate(_ templateName: String) -> Bool {
        guard let templateURL = getTemplateFolderURL() else {
            NSLog("Template folder not configured")
            return false
        }
        
        let needsSecurityScope = !templateURL.path.hasPrefix(FileManager.default.homeDirectoryForCurrentUser.path)
        
        if needsSecurityScope {
            guard templateURL.startAccessingSecurityScopedResource() else {
                NSLog("Failed to access template folder")
                return false
            }
        }
        
        defer {
            if needsSecurityScope {
                templateURL.stopAccessingSecurityScopedResource()
            }
        }
        
        let targetURL = templateURL.appendingPathComponent(templateName)
        
        // 检查文件是否存在
        guard FileManager.default.fileExists(atPath: targetURL.path) else {
            NSLog("Template file does not exist: \(templateName)")
            return false
        }
        
        do {
            try FileManager.default.removeItem(at: targetURL)
            NSLog("Template deleted successfully: \(templateName)")
            return true
        } catch {
            NSLog("Error deleting template: \(error)")
            return false
        }
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
    
    /// 初始化模板文件夹（强制清理旧配置并弹窗选择）
    static func initializeTemplateFolder() {
        NSLog("Initializing template folder...")
        
        // 检查当前路径是否是旧的沙盒路径
        if let currentURL = getTemplateFolderURL() {
            let isOldSandboxPath = currentURL.path.contains("/Library/Containers/") &&
                                   currentURL.path.contains("/Data/Documents/")
            
            if !isOldSandboxPath {
                NSLog("Template folder already configured with valid path: \(currentURL.path)")
                return
            } else {
                NSLog("Found old sandbox path, will clear and prompt user: \(currentURL.path)")
                // 清理旧的沙盒配置
                resetTemplateFolder()
            }
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
        UserDefaults.standard.removeObject(forKey: templateFolderPathKey)
        UserDefaults.standard.removeObject(forKey: templateFolderBookmarkKey)
        UserDefaults.standard.synchronize()
        NSLog("Template folder configuration reset")
    }
    
    /// 获取当前模板文件夹路径（用于显示）
    static func getCurrentTemplateFolderPath() -> String? {
        return getTemplateFolderURL()?.path
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
