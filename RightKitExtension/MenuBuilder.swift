//
//  MenuBuilder.swift
//  RightKitExtension
//
//  Created by Yiming Sun on 2025/8/15.
//

import Foundation
import Cocoa
import FinderSync

class MenuBuilder {
    static let shared = MenuBuilder()
    
    private var cachedMenuItems: [MenuItem] = []
    private var titleToActionMap: [String: String] = [:]
    private var needsReload = true
    
    private init() {}
    
    // MARK: - Configuration Management
    
    func reloadConfiguration() {
        NSLog("RightKit MenuBuilder: Reloading configuration...")
        needsReload = true
        titleToActionMap.removeAll()
    }
    
    private func loadConfigurationIfNeeded() {
        guard needsReload else { return }
        
        do {
            let configuration = try ConfigurationManager.shared.loadConfiguration()
            cachedMenuItems = configuration.items
            needsReload = false
            NSLog("RightKit MenuBuilder: Loaded %d menu items", cachedMenuItems.count)
        } catch {
            NSLog("RightKit MenuBuilder: Failed to load configuration: \(error)")
            cachedMenuItems = []
        }
    }
    
    // MARK: - Menu Building
    
    func buildMenu(for menuKind: FIMenuKind) -> NSMenu {
        NSLog("RightKit: Building menu for menuKind: %d", menuKind.rawValue)
        
        loadConfigurationIfNeeded()
        
        let menu = NSMenu(title: "RightKit")
        titleToActionMap.removeAll()
        
        for menuItem in cachedMenuItems {
            let nsMenuItem = buildMenuItem(from: menuItem)
            menu.addItem(nsMenuItem)
        }
        
        // 如果没有菜单项，显示提示
        if cachedMenuItems.isEmpty {
            let emptyItem = NSMenuItem(title: "请在RightKit应用中配置菜单", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        }
        
        return menu
    }
    
    func buildToolbarMenu() -> NSMenu {
        NSLog("RightKit: Building toolbar menu")
        
        let menu = NSMenu(title: "RightKit")
        
        let configItem = NSMenuItem(title: "打开RightKit配置", action: #selector(FinderSync.openConfigApp(_:)), keyEquivalent: "")
        menu.addItem(configItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let aboutItem = NSMenuItem(title: "关于RightKit", action: #selector(FinderSync.showAbout(_:)), keyEquivalent: "")
        menu.addItem(aboutItem)
        
        return menu
    }
    
    private func buildMenuItem(from menuItem: MenuItem) -> NSMenuItem {
        // Determine dynamic title for Cut/Paste toggle
        var displayedTitle = menuItem.name
        if let action = menuItem.action, action.type == .cutFile {
            displayedTitle = CutPasteState.shared.hasPendingCut() ? "粘贴文件" : "剪切文件"
        }
        
        let nsMenuItem = NSMenuItem(title: displayedTitle, action: #selector(FinderSync.menuItemClicked(_:)), keyEquivalent: "")
        // 设置图标
        let iconName = menuItem.icon ?? "questionmark"
        if let image = NSImage(systemSymbolName: iconName, accessibilityDescription: displayedTitle) {
            nsMenuItem.image = image
        }
        
        // 记录菜单标题到动作的映射（使用显示标题，确保点击时能正确解析）
        if let action = menuItem.action {
            let actionString = "\(action.type.rawValue)|\(action.parameter ?? "")"
            titleToActionMap[displayedTitle] = actionString
        }
        
        // 处理子菜单
        if let children = menuItem.children, !children.isEmpty {
            let submenu = NSMenu(title: displayedTitle)
            for childItem in children {
                let childNSMenuItem = buildMenuItem(from: childItem)
                submenu.addItem(childNSMenuItem)
            }
            nsMenuItem.submenu = submenu
        }
        
        return nsMenuItem
    }
    
    // 根据菜单标题获取动作字符串
    func getAction(for title: String) -> String? {
        return titleToActionMap[title]
    }
}
