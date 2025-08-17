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
        // 暂时使用空数组，模板功能将在后续版本中完善
        templates = []
        NSLog("Templates loaded")
    }
    
    func addTemplate(from url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            NSLog("Failed to access security scoped resource: \(url)")
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        guard let templatesURL = ConfigurationManager.templatesDirectoryURL else {
            NSLog("Could not get templates directory URL")
            return
        }
        
        let fileName = url.lastPathComponent
        let destinationURL = templatesURL.appendingPathComponent(fileName)
        
        do {
            // 确保模板目录存在
            try FileManager.default.createDirectory(at: templatesURL, withIntermediateDirectories: true, attributes: nil)
            
            // 复制文件到模板目录
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.copyItem(at: url, to: destinationURL)
            
            // 创建模板信息并添加到列表
            let template = TemplateInfo(
                fileName: fileName,
                displayName: url.deletingPathExtension().lastPathComponent,
                iconName: iconForFileExtension(url.pathExtension)
            )
            
            if !templates.contains(where: { $0.fileName == fileName }) {
                templates.append(template)
            }
            
            NSLog("Added template: \(fileName)")
        } catch {
            NSLog("Failed to add template: \(error)")
        }
    }
    
    func removeTemplate(at index: Int) {
        guard index < templates.count else { return }
        
        let template = templates[index]
        
        guard let templatesURL = ConfigurationManager.templatesDirectoryURL else {
            NSLog("Could not get templates directory URL")
            return
        }
        
        let templateURL = templatesURL.appendingPathComponent(template.fileName)
        
        do {
            try FileManager.default.removeItem(at: templateURL)
            templates.remove(at: index)
            NSLog("Removed template: \(template.fileName)")
        } catch {
            NSLog("Failed to remove template: \(error)")
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
