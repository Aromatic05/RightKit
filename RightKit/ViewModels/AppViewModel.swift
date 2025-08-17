//
//  AppViewModel.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import SwiftUI
import UniformTypeIdentifiers

@MainActor
class AppViewModel: ObservableObject {
    @Published var menuItems: [MenuItem] = []
    @Published var templates: [TemplateInfo] = []
    @Published var hasChanges = false
    @Published var selectedActionType: ActionType? = nil
    @Published var selectedItemId: UUID?
    
    private let configurationManager = ConfigurationManager.shared
    
    init() {
        loadMenuTree()
        loadTemplates()
    }
    
    // MARK: - Menu Management
    
    func loadMenuTree() {
        do {
            let configuration = try configurationManager.loadConfiguration()
            menuItems = configuration.items
            hasChanges = false
            NSLog("Loaded menu tree with \(menuItems.count) items")
        } catch {
            NSLog("Failed to load menu configuration: \(error)")
            menuItems = ConfigurationManager.createDefaultConfiguration().items
            hasChanges = false
        }
    }
    
    func saveMenuTree() {
        let configuration = MenuConfiguration(items: menuItems)
        ConfigurationManager.saveConfiguration(configuration)
        hasChanges = false
        NSLog("Saved menu tree")
    }
    
    func resetToDefaultData() {
        menuItems = ConfigurationManager.createDefaultConfiguration().items
        hasChanges = true
    }
    
    // MARK: - Template Management
    
    func loadTemplates() {
        // 使用TemplateManager获取模板文件列表
        let templateFileNames = TemplateManager.getTemplateFiles()
        templates = templateFileNames.map { fileName in
            TemplateInfo(
                fileName: fileName,
                displayName: URL(fileURLWithPath: fileName).deletingPathExtension().lastPathComponent,
                iconName: iconForFileExtension(URL(fileURLWithPath: fileName).pathExtension)
            )
        }
        NSLog("Loaded \(templates.count) templates")
    }
    
    func addTemplate(from url: URL) {
        // 使用TemplateManager的uploadTemplate方法上传模板
        if TemplateManager.uploadTemplate(from: url) {
            // 上传成功后重新加载模板列表
            loadTemplates()
            NSLog("Template uploaded successfully from: \(url.lastPathComponent)")
        } else {
            NSLog("Failed to upload template from: \(url.lastPathComponent)")
        }
    }
    
    func removeTemplate(at index: Int) {
        guard index < templates.count else { return }
        
        let template = templates[index]
        
        // 使用TemplateManager的deleteTemplate方法删除模板
        if TemplateManager.deleteTemplate(template.fileName) {
            // 删除成功后重新加载模板列表
            loadTemplates()
            NSLog("Template removed successfully: \(template.fileName)")
        } else {
            NSLog("Failed to remove template: \(template.fileName)")
        }
    }
    
    func removeTemplate(_ templateName: String) {
        // 使用TemplateManager的deleteTemplate方法删除模板
        if TemplateManager.deleteTemplate(templateName) {
            // 删除成功后重新加载模板列表
            loadTemplates()
            NSLog("Template removed successfully: \(templateName)")
        } else {
            NSLog("Failed to remove template: \(templateName)")
        }
    }
    
    func createMenuItemFromTemplate(_ template: TemplateInfo) {
        let menuItem = MenuItem(
            name: "新建\(template.displayName)",
            icon: template.iconName ?? "doc.badge.plus",
            action: Action(type: .createFileFromTemplate, parameter: template.fileName),
            children: nil
        )
        addMenuItem(menuItem)
    }
    
    // MARK: - Menu Item Operations
    
    func addMenuItem(_ item: MenuItem, to parent: MenuItem? = nil) {
        if let parent = parent {
            addMenuItemRecursive(item, to: parent, in: &menuItems)
        } else {
            menuItems.append(item)
        }
        hasChanges = true
    }

    private func addMenuItemRecursive(_ item: MenuItem, to parent: MenuItem, in items: inout [MenuItem]) {
        for index in items.indices {
            if items[index].id == parent.id {
                if items[index].children == nil {
                    items[index].children = []
                }
                items[index].children?.append(item)
                return
            }
            if items[index].children != nil {
                addMenuItemRecursive(item, to: parent, in: &items[index].children!)
            }
        }
    }

    func removeMenuItem(_ item: MenuItem) {
        removeMenuItemRecursive(item, from: &menuItems)
        hasChanges = true
    }
    
    private func removeMenuItemRecursive(_ item: MenuItem, from items: inout [MenuItem]) {
        items.removeAll { $0.id == item.id }
        
        for index in items.indices {
            if var children = items[index].children {
                removeMenuItemRecursive(item, from: &children)
                items[index].children = children
            }
        }
    }
    
    private func findMenuItemIndex(_ item: MenuItem) -> Int? {
        return menuItems.firstIndex { $0.id == item.id }
    }
    
    func addSubmenu(name: String = "新子菜单") {
        let submenu = MenuItem(
            name: name,
            icon: "folder",
            action: nil,
            children: []
        )
        addMenuItem(submenu)
    }
    
    func addSeparator() {
        let separator = MenuItem(
            name: "分隔线",
            icon: "minus",
            action: Action(type: .separator, parameter: nil),
            children: nil
        )
        addMenuItem(separator)
    }
    
    func addEmptyFileAction(fileExtension: String = "txt") {
        let action = MenuItem(
            name: "新建空白文件",
            icon: "doc",
            action: Action(type: .createEmptyFile, parameter: fileExtension),
            children: nil
        )
        addMenuItem(action)
    }
    
    func moveMenuItem(_ item: MenuItem, to destination: MenuItem?) {
        // 移除原位置的项目
        removeMenuItem(item)
        
        // 添加到新位置
        addMenuItem(item, to: destination)
    }
    
    func updateMenuItem(_ item: MenuItem, name: String? = nil, icon: String? = nil, parameter: String? = nil) {
        updateMenuItemRecursive(item, name: name, icon: icon, parameter: parameter, in: &menuItems)
        hasChanges = true
    }
    
    private func updateMenuItemRecursive(_ item: MenuItem, name: String?, icon: String?, parameter: String?, in items: inout [MenuItem]) {
        for index in items.indices {
            if items[index].id == item.id {
                if let name = name {
                    items[index].name = name
                }
                if let icon = icon {
                    items[index].icon = icon
                }
                if let parameter = parameter {
                    if items[index].action != nil {
                        items[index].action?.parameter = parameter
                    }
                }
                return
            }
            
            if var children = items[index].children {
                updateMenuItemRecursive(item, name: name, icon: icon, parameter: parameter, in: &children)
                items[index].children = children
            }
        }
    }
    
    // MARK: - Utility Methods
    
    private func iconForFileExtension(_ ext: String) -> String {
        switch ext.lowercased() {
        case "txt":
            return "doc.plaintext"
        case "md":
            return "text.book.closed"
        case "swift":
            return "swift"
        case "py":
            return "terminal"
        case "html", "htm":
            return "globe"
        case "css":
            return "paintbrush"
        case "js":
            return "function"
        case "json":
            return "braces"
        case "yaml", "yml":
            return "doc.text"
        default:
            return "doc"
        }
    }
    
    func initializeChildren(for item: MenuItem) {
        initializeChildrenRecursive(for: item, in: &menuItems)
    }
    private func initializeChildrenRecursive(for item: MenuItem, in items: inout [MenuItem]) {
        for index in items.indices {
            if items[index].id == item.id {
                if items[index].children == nil {
                    items[index].children = []
                    hasChanges = true
                }
                return
            }
            if items[index].children != nil {
                initializeChildrenRecursive(for: item, in: &items[index].children!)
            }
        }
    }
}
