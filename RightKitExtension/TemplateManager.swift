//
//  TemplateManager.swift
//  RightKitExtension
//
//  Created by Yiming Sun on 2025/8/15.
//

import Foundation

/// 模板管理器，负责处理模板文件夹的Security-Scoped Bookmarks
class TemplateManager {
    
    /// App Group ID
    static let appGroupID = "group.Aromatic.RightKit"
    
    /// 存储模板文件夹书签的UserDefaults键
    private static let templateFolderBookmarkKey = "templateFolderBookmark"
    
    /// 获取共享的UserDefaults
    static var sharedUserDefaults: UserDefaults? {
        return UserDefaults(suiteName: appGroupID)
    }
    
    /// 获取模板文件夹URL（从Security-Scoped Bookmark恢复）
    static func getTemplateFolderURL() -> URL? {
        guard let bookmarkData = sharedUserDefaults?.data(forKey: templateFolderBookmarkKey) else {
            NSLog("No template folder bookmark found")
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
                NSLog("Bookmark is stale, need to recreate")
                return nil
            }
            
            return url
        } catch {
            NSLog("Error resolving bookmark: \(error)")
            return nil
        }
    }
    
    /// 从模板创建文件
    static func createFileFromTemplate(templateName: String, targetDirectory: URL, newFileName: String? = nil) -> Bool {
        guard let templateURL = getTemplateFolderURL() else {
            NSLog("Template folder not configured")
            return false
        }
        
        guard templateURL.startAccessingSecurityScopedResource() else {
            NSLog("Failed to access template folder")
            return false
        }
        
        defer {
            templateURL.stopAccessingSecurityScopedResource()
        }
        
        let sourceURL = templateURL.appendingPathComponent(templateName)
        
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
    
    /// 生成唯一的文件URL（如果文件已存在，添加数字后缀）
    private static func generateUniqueFileURL(baseURL: URL) -> URL {
        var counter = 1
        var currentURL = baseURL
        
        while FileManager.default.fileExists(atPath: currentURL.path) {
            let fileName = baseURL.deletingPathExtension().lastPathComponent
            let fileExtension = baseURL.pathExtension
            let newFileName = "\(fileName) \(counter).\(fileExtension)"
            currentURL = baseURL.deletingLastPathComponent().appendingPathComponent(newFileName)
            counter += 1
        }
        
        return currentURL
    }
}