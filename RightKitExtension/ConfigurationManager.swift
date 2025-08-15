//  ConfigurationManager.swift
//  RightKitExtension
//  Created by GitHub Copilot

import Foundation

class ConfigurationManager {
    static let shared = ConfigurationManager()
    private let appGroupID = "group.Aromatic.RightKit"
    private let configFileName = "menu.json"

    private var configURL: URL? {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
            NSLog("ConfigurationManager: App Group container not found")
            return nil
        }
        // 使用与主程序相同的路径结构
        return containerURL
            .appendingPathComponent("Library")
            .appendingPathComponent("Application Support")
            .appendingPathComponent("RightKit")
            .appendingPathComponent(configFileName)
    }

    func loadConfiguration() throws -> MenuConfiguration {
        guard let url = configURL else {
            throw NSError(domain: "ConfigurationManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "App Group container not found"])
        }
        
        // 如果配置文件不存在，返回默认配置
        if !FileManager.default.fileExists(atPath: url.path) {
            NSLog("ConfigurationManager: Configuration file does not exist, returning default configuration")
            return createDefaultConfiguration()
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(MenuConfiguration.self, from: data)
    }
    
    private func createDefaultConfiguration() -> MenuConfiguration {
        return MenuConfiguration(
            version: "1.0",
            items: [
                MenuItem(
                    name: "新建文件",
                    icon: "doc.badge.plus",
                    action: nil,
                    children: [
                        MenuItem(
                            name: "空白文本文件",
                            icon: "doc.text",
                            action: Action(type: .createEmptyFile, parameter: "新建文件.txt"),
                            children: nil
                        ),
                        MenuItem(
                            name: "Markdown文档",
                            icon: "doc.richtext",
                            action: Action(type: .createEmptyFile, parameter: "新建文档.md"),
                            children: nil
                        )
                    ]
                ),
                MenuItem(
                    name: "新建文件夹",
                    icon: "folder.badge.plus",
                    action: Action(type: .createFolder, parameter: "新建文件夹"),
                    children: nil
                )
            ]
        )
    }
}
