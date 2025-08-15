//
//  FinderSync.swift
//  RightKitExtension
//
//  Created by Yiming Sun on 2025/8/15.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    
    /// App Group ID - 需要与主程序一致
    private let appGroupID = "group.Aromatic.RightKit"
    
    /// 缓存的菜单配置
    private var cachedConfiguration: MenuConfiguration?

    override init() {
        super.init()
        
        // 监控根目录，这样我们的右键菜单可以在任何地方出现
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        
        // 初始化时加载配置
        loadMenuConfiguration()
        
        NSLog("RightKitExtension successfully launched.")
    }
    
    // MARK: - Configuration Management
    
    /// 获取App Group容器URL
    private var containerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
    
    /// 获取配置文件的完整路径
    private var configFileURL: URL? {
        guard let containerURL = containerURL else { return nil }
        return containerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("RightKit")
            .appendingPathComponent("menu.json")
    }
    
    /// 加载菜单配置
    private func loadMenuConfiguration() {
        guard let configURL = configFileURL else {
            NSLog("Error: Could not get configuration file URL")
            return
        }
        
        guard FileManager.default.fileExists(atPath: configURL.path) else {
            NSLog("Configuration file does not exist at: \(configURL.path)")
            return
        }
        
        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            cachedConfiguration = try decoder.decode(MenuConfiguration.self, from: data)
            NSLog("Menu configuration loaded successfully from: \(configURL.path)")
        } catch {
            NSLog("Error loading menu configuration: \(error)")
        }
    }
    
    // MARK: - Menu Building
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        // 创建主菜单
        let menu = NSMenu(title: "")
        
        // 如果有缓存的配置，使用动态菜单
        if let configuration = cachedConfiguration {
            buildMenuItems(from: configuration.items, into: menu)
        } else {
            // 如果没有配置，显示一个占位菜单项
            menu.addItem(withTitle: "RightKit (配置加载失败)", action: nil, keyEquivalent: "")
        }
        
        return menu
    }
    
    /// 递归构建菜单项
    private func buildMenuItems(from items: [MenuItem], into menu: NSMenu) {
        for item in items {
            let menuItem = NSMenuItem(title: item.name, action: nil, keyEquivalent: "")
            
            // 设置图标（如果有）
            if let iconName = item.icon {
                if #available(macOS 11.0, *) {
                    menuItem.image = NSImage(systemSymbolName: iconName, accessibilityDescription: nil)
                }
            }
            
            // 如果有子菜单，递归创建
            if let children = item.children, !children.isEmpty {
                let submenu = NSMenu(title: item.name)
                buildMenuItems(from: children, into: submenu)
                menuItem.submenu = submenu
            } else if let action = item.action {
                // 如果有动作，设置点击处理
                menuItem.action = #selector(menuItemClicked(_:))
                menuItem.target = self
                // 将动作信息存储在represented object中
                menuItem.representedObject = action
            }
            
            menu.addItem(menuItem)
        }
    }
    
    // MARK: - Action Handling
    
    /// 处理菜单项点击
    @IBAction func menuItemClicked(_ sender: NSMenuItem) {
        guard let action = sender.representedObject as? Action else {
            NSLog("Error: No action found for menu item")
            return
        }
        
        NSLog("Menu item clicked: \(sender.title), action: \(action.type.rawValue)")
        
        // 获取当前上下文信息
        let targetURL = FIFinderSyncController.default().targetedURL()
        let selectedURLs = FIFinderSyncController.default().selectedItemURLs()
        
        NSLog("Target URL: \(targetURL?.path ?? "None")")
        NSLog("Selected URLs: \(selectedURLs?.map { $0.path } ?? [])")
        
        // 根据动作类型执行相应操作
        switch action.type {
        case .createEmptyFile:
            handleCreateEmptyFile(parameter: action.parameter, targetURL: targetURL)
        case .createFileFromTemplate:
            handleCreateFileFromTemplate(parameter: action.parameter, targetURL: targetURL)
        case .copyFilePath:
            handleCopyFilePath(selectedURLs: selectedURLs, targetURL: targetURL)
        case .cutFile:
            handleCutFile(selectedURLs: selectedURLs)
        case .runShellScript:
            handleRunShellScript(parameter: action.parameter, targetURL: targetURL)
        }
    }
    
    /// 处理创建空文件
    private func handleCreateEmptyFile(parameter: String?, targetURL: URL?) {
        guard let fileExtension = parameter else {
            NSLog("Error: No file extension provided for createEmptyFile action")
            return
        }
        
        // 确定目标目录
        let targetDirectory: URL
        if let url = targetURL {
            if url.hasDirectoryPath {
                targetDirectory = url
            } else {
                targetDirectory = url.deletingLastPathComponent()
            }
        } else {
            NSLog("Error: No target directory found")
            return
        }
        
        // 生成文件名和默认内容
        let fileName = "新建文件.\(fileExtension)"
        let fileURL = targetDirectory.appendingPathComponent(fileName)
        let finalURL = generateUniqueFileURL(baseURL: fileURL)
        
        // 根据文件类型生成默认内容
        let defaultContent = generateDefaultContent(for: fileExtension)
        
        // 创建文件
        do {
            try defaultContent.write(to: finalURL, atomically: true, encoding: .utf8)
            NSLog("Empty file created successfully: \(finalURL.path)")
        } catch {
            NSLog("Error creating empty file: \(error)")
        }
    }
    
    /// 根据文件扩展名生成默认内容
    private func generateDefaultContent(for fileExtension: String) -> String {
        switch fileExtension.lowercased() {
        case "swift":
            return """
//
//  \(generateFileName(for: fileExtension))
//  Created by RightKit on \(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .none))
//

import Foundation

class NewClass {
    
}
"""
        case "md":
            return """
# 新建文档

## 概述

这是一个新建的 Markdown 文档。

## 内容

在这里编写您的内容...
"""
        case "json":
            return """
{
    "name": "新建配置",
    "version": "1.0",
    "description": "这是一个新建的 JSON 配置文件"
}
"""
        case "html":
            return """
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>新建页面</title>
</head>
<body>
    <h1>Hello, World!</h1>
</body>
</html>
"""
        default:
            return ""
        }
    }
    
    /// 生成文件名
    private func generateFileName(for fileExtension: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"
        let dateString = dateFormatter.string(from: Date())
        return "新建文件_\(dateString).\(fileExtension)"
    }
    
    /// 处理从模板创建文件
    private func handleCreateFileFromTemplate(parameter: String?, targetURL: URL?) {
        guard let templateName = parameter else {
            NSLog("Error: No template name provided for createFileFromTemplate action")
            return
        }
        
        // 确定目标目录
        let targetDirectory: URL
        if let url = targetURL {
            if url.hasDirectoryPath {
                targetDirectory = url
            } else {
                targetDirectory = url.deletingLastPathComponent()
            }
        } else {
            NSLog("Error: No target directory found")
            return
        }
        
        // 从TemplateManager创建文件
        if TemplateManager.createFileFromTemplate(templateName: templateName, targetDirectory: targetDirectory) {
            NSLog("File created from template successfully: \(templateName)")
        } else {
            NSLog("Failed to create file from template: \(templateName)")
        }
    }
    
    /// 处理复制文件路径
    private func handleCopyFilePath(selectedURLs: [URL]?, targetURL: URL?) {
        let urlsToCopy: [URL]
        
        if let selected = selectedURLs, !selected.isEmpty {
            urlsToCopy = selected
        } else if let target = targetURL {
            urlsToCopy = [target]
        } else {
            NSLog("No files to copy path from")
            return
        }
        
        let paths = urlsToCopy.map { $0.path }
        let pathString = paths.joined(separator: "\n")
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(pathString, forType: .string)
        
        NSLog("Copied \(paths.count) file path(s) to clipboard")
    }
    
    /// 处理剪切文件
    private func handleCutFile(selectedURLs: [URL]?) {
        guard let selectedURLs = selectedURLs, !selectedURLs.isEmpty else {
            NSLog("No files selected for cut operation")
            return
        }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        
        // 设置文件URL到剪贴板
        pasteboard.writeObjects(selectedURLs as [NSURL])
        
        // 标记为移动操作
        pasteboard.setData(Data(), forType: NSPasteboard.PasteboardType("NSFilenamesPboardType.move"))
        
        NSLog("Cut \(selectedURLs.count) file(s) to clipboard")
    }
    
    /// 处理运行Shell脚本（占位实现）
    private func handleRunShellScript(parameter: String?, targetURL: URL?) {
        NSLog("RunShellScript action - will be implemented in future versions")
        NSLog("Parameter: \(parameter ?? "None")")
        NSLog("Target URL: \(targetURL?.path ?? "None")")
    }
    
    /// 生成唯一的文件URL（如果文件已存在，添加数字后缀）
    private func generateUniqueFileURL(baseURL: URL) -> URL {
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
