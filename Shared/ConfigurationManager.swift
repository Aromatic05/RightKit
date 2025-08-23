//
//  ConfigurationManager.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import Foundation

/// 配置管理器，负责处理菜单配置的读写和App Group数据共享
class ConfigurationManager {
    
    /// 单例实例
    static let shared = ConfigurationManager()
    
    /// 私有初始化器，确保单例模式
    private init() {}
    
    /// App Group ID - 需要与项目配置中的App Group ID一致
    static let appGroupID = "group.Aromatic.RightKit"
    
    /// 配置文件名
    static let configFileName = "menu.json"
    
    /// 通知名称
    static let configUpdateNotificationName = "com.aromatic.RightKit.configUpdated"
    
    /// App Group内持久化的sh检测脚本文件名
    static let detectScriptFileName = "rightkit_terminal_detect.sh"
    
    /// 获取App Group容器URL
    static var containerURL: URL? {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }
    
    /// App Group内 RightKit 基础目录 URL: ~/Library/Application Support/RightKit
    static var rightKitBaseDirectoryURL: URL? {
        containerURL?
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("RightKit")
    }
    
    /// 获取配置文件的完整路径
    static var configFileURL: URL? {
        guard let base = rightKitBaseDirectoryURL else { return nil }
        return base.appendingPathComponent(configFileName)
    }
    
    /// 获取模板目录URL
    static var templatesDirectoryURL: URL? {
        guard let base = rightKitBaseDirectoryURL else { return nil }
        return base.appendingPathComponent("Templates")
    }
    
    /// 获取App Group内持久化的sh检测脚本URL
    static var detectScriptURL: URL? {
        guard let base = rightKitBaseDirectoryURL else { return nil }
        return base.appendingPathComponent(detectScriptFileName)
    }
    
    /// 初始化默认配置
    static func initializeDefaultConfiguration() {
        guard let configURL = configFileURL else {
            NSLog("Error: Could not get App Group container URL")
            return
        }
        
        // 创建目录结构
        let directoryURL = configURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        } catch {
            NSLog("Error creating configuration directory: \(error)")
            return
        }
        
        // 如果配置文件不存在，创建默认配置
        if !FileManager.default.fileExists(atPath: configURL.path) {
            let defaultConfiguration = createDefaultConfiguration()
            saveConfiguration(defaultConfiguration)
        }
    }
    
    /// 创建默认菜单配置
    static func createDefaultConfiguration() -> MenuConfiguration {
        let newFileMenu = MenuItem(
            name: "新建文件",
            icon: "doc.badge.plus",
            action: nil,
            children: [
                MenuItem(
                    name: "空白文本文件",
                    icon: "doc.text",
                    action: Action(type: .createEmptyFile, parameter: "txt"),
                    children: nil
                ),
                MenuItem(
                    name: "Swift 文件",
                    icon: "swift",
                    action: Action(type: .createEmptyFile, parameter: "swift"),
                    children: nil
                ),
                MenuItem(
                    name: "Markdown 文件",
                    icon: "doc.richtext",
                    action: Action(type: .createEmptyFile, parameter: "md"),
                    children: nil
                ),
                MenuItem(
                    name: "JSON 文件",
                    icon: "doc.text.below.ecg",
                    action: Action(type: .createEmptyFile, parameter: "json"),
                    children: nil
                ),
                MenuItem(
                    name: "从模板新建",
                    icon: "doc.on.doc",
                    action: nil,
                    children: [
                        MenuItem(
                            name: "Swift 类模板",
                            icon: "swift",
                            action: Action(type: .createFileFromTemplate, parameter: "swift"),
                            children: nil
                        ),
                        MenuItem(
                            name: "README 模板",
                            icon: "doc.richtext",
                            action: Action(type: .createFileFromTemplate, parameter: "md"),
                            children: nil
                        )
                    ]
                )
            ]
        )
        
        // 添加其他工具菜单项
        let toolsMenu = MenuItem(
            name: "工具",
            icon: "wrench.and.screwdriver",
            action: nil,
            children: [
                MenuItem(
                    name: "在此处打开终端",
                    icon: "terminal",
                    action: Action(type: .openTerminal, parameter: nil),
                    children: nil
                ),
                MenuItem(
                    name: "复制路径",
                    icon: "doc.on.clipboard",
                    action: Action(type: .copyFilePath, parameter: nil),
                    children: nil
                ),
                MenuItem(
                    name: "剪切文件",
                    icon: "scissors",
                    action: Action(type: .cutFile, parameter: nil),
                    children: nil
                ),
                MenuItem(
                    name: "计算文件哈希值",
                    icon: "number",
                    action: Action(type: .hashFile, parameter: nil),
                    children: nil
                ),
                MenuItem(
                    name: "发送到桌面",
                    icon: "desktopcomputer",
                    action: Action(type: .sendToDesktop, parameter: nil),
                    children: nil
                )
            ]
        )
        
        return MenuConfiguration(items: [newFileMenu, toolsMenu])
    }
    
    /// 保存配置到App Group容器
    static func saveConfiguration(_ configuration: MenuConfiguration) {
        guard let configURL = configFileURL else {
            NSLog("Error: Could not get configuration file URL")
            return
        }
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(configuration)
            try data.write(to: configURL)
            NSLog("Configuration saved successfully to: \(configURL.path)")
            
            // 发送配置更新通知给FinderSync扩展
            sendConfigurationUpdateNotification()
        } catch {
            NSLog("Error saving configuration: \(error)")
        }
    }
    
    /// 发送配置更新通知
    private static func sendConfigurationUpdateNotification() {
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(configUpdateNotificationName),
            object: nil,
            deliverImmediately: true
        )
        NSLog("Sent configuration update notification")
    }
    
    /// 实例方法：加载配置
    func loadConfiguration() throws -> MenuConfiguration {
        guard let configURL = Self.configFileURL else {
            throw NSError(domain: "ConfigurationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not get configuration file URL"])
        }
        
        // 如果配置文件不存在，返回默认配置
        if !FileManager.default.fileExists(atPath: configURL.path) {
            NSLog("Configuration file does not exist, returning default configuration")
            return Self.createDefaultConfiguration()
        }
        
        do {
            let data = try Data(contentsOf: configURL)
            let decoder = JSONDecoder()
            let configuration = try decoder.decode(MenuConfiguration.self, from: data)
            NSLog("Configuration loaded successfully from: \(configURL.path)")
            return configuration
        } catch {
            NSLog("Error loading configuration: \(error), returning default configuration")
            return Self.createDefaultConfiguration()
        }
    }
    
    /// 确保检测脚本存在，若不存在则创建
    static func ensureDetectScriptExists() {
        guard let scriptURL = detectScriptURL else { return }
        if !FileManager.default.fileExists(atPath: scriptURL.path) {
            let scriptContent = "#!/bin/sh\necho rightkit_detect\n"
            do {
                // 创建目录结构
                let directoryURL = scriptURL.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
                try scriptContent.write(to: scriptURL, atomically: true, encoding: .utf8)
                let attributes: [FileAttributeKey: Any] = [.posixPermissions: 0o755]
                try FileManager.default.setAttributes(attributes, ofItemAtPath: scriptURL.path)
            } catch {
                NSLog("Error creating detect script: \(error)")
            }
        }
    }
}
