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
    
    private init() {}
    
    // MARK: - Menu Building
    
    func buildMenu(for menuKind: FIMenuKind) -> NSMenu {
        NSLog("RightKit: Building menu for menuKind: %d", menuKind.rawValue)
        
        let menu = NSMenu(title: "")
        
        // 加载配置并构建动态菜单
        do {
            let config = try ConfigurationManager.shared.loadConfiguration()
            NSLog("RightKit: Loaded configuration with %d menu items", config.items.count)
            
            for menuItem in config.items {
                let nsMenuItem = buildMenuItem(from: menuItem)
                menu.addItem(nsMenuItem)
            }
            
            if config.items.isEmpty {
                let emptyItem = NSMenuItem(title: "暂无菜单项", action: nil, keyEquivalent: "")
                emptyItem.isEnabled = false
                menu.addItem(emptyItem)
            }
            
        } catch {
            NSLog("RightKit: Error loading configuration: %@", error.localizedDescription)
            let errorItem = NSMenuItem(title: "加载配置失败", action: nil, keyEquivalent: "")
            errorItem.isEnabled = false
            menu.addItem(errorItem)
        }
        
        return menu
    }
    
    private func buildMenuItem(from menuItem: MenuItem) -> NSMenuItem {
        let nsMenuItem = NSMenuItem(title: menuItem.name, action: #selector(FinderSync.menuItemClicked(_:)), keyEquivalent: "")
        
        // 设置representedObject为简单字符串，避免序列化问题
        if let action = menuItem.action {
            let actionString = "\(action.type.rawValue)|\(action.parameter ?? "")"
            nsMenuItem.representedObject = actionString
            NSLog("RightKit: Created menu item '%@' with action: %@", menuItem.name, actionString)
        }
        
        // 处理子菜单
        if let children = menuItem.children, !children.isEmpty {
            let submenu = NSMenu(title: menuItem.name)
            for childItem in children {
                let childNSMenuItem = buildMenuItem(from: childItem)
                submenu.addItem(childNSMenuItem)
            }
            nsMenuItem.submenu = submenu
        }
        
        return nsMenuItem
    }
}
