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

    // MARK: - Appearance Detection
    
    private func isDarkMode() -> Bool {
        let appearance = NSApp.effectiveAppearance.name
        return appearance == .darkAqua || appearance == .vibrantDark || appearance == .accessibilityHighContrastDarkAqua || appearance == .accessibilityHighContrastVibrantDark
    }
    
    private func getIconColor() -> NSColor {
        return isDarkMode() ? .white : .black
    }

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

    func buildMenu(contextType: DisplayCondition, isMultiSelection: Bool = false) -> NSMenu {
        NSLog("RightKit: Building menu for contextType: %@, isMultiSelection: %@", String(describing: contextType), String(describing: isMultiSelection))

        loadConfigurationIfNeeded()

        let menu = NSMenu(title: "RightKit")
        titleToActionMap.removeAll()

        for menuItem in cachedMenuItems {
            if shouldDisplay(menuItem, for: contextType, isMultiSelection: isMultiSelection) {
                let nsMenuItem = buildMenuItem(from: menuItem, contextType: contextType, isMultiSelection: isMultiSelection)
                menu.addItem(nsMenuItem)
            }
        }

        // 如果没有菜单项，显示提示
        if menu.items.isEmpty {
            let emptyItem = NSMenuItem(title: "请在RightKit应用中配置菜单", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            menu.addItem(emptyItem)
        }

        return menu
    }

    /// 判断菜单项是否应显示
    private func shouldDisplay(_ menuItem: MenuItem, for contextType: DisplayCondition, isMultiSelection: Bool) -> Bool {
        let condition = menuItem.displayCondition ?? .all
        if isMultiSelection {
            return condition == .all
        }
        return condition == .all || condition == contextType
    }

    private func buildMenuItem(from menuItem: MenuItem, contextType: DisplayCondition, isMultiSelection: Bool) -> NSMenuItem {
        // 使用扩展提供的动态标题
        let displayedTitle = menuItem.displayTitle

        let nsMenuItem = NSMenuItem(title: displayedTitle, action: #selector(FinderSync.menuItemClicked(_:)), keyEquivalent: "")
        // 设置图标
        let iconName = menuItem.icon ?? "questionmark"

        // 根据系统外观动态设置图标颜色
        let iconColor = getIconColor()

        // 使用 SF Symbols 的颜色配置功能
        if let sysImage = NSImage(systemSymbolName: iconName, accessibilityDescription: displayedTitle) {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
                .applying(NSImage.SymbolConfiguration(paletteColors: [iconColor]))
            let configured = sysImage.withSymbolConfiguration(config) ?? sysImage
            nsMenuItem.image = configured
        } else if let namedImage = Bundle(for: MenuBuilder.self).image(forResource: iconName) ?? NSImage(named: NSImage.Name(iconName)) {
            // 对于自定义图片，设置为模板图像让系统自动适配
            namedImage.isTemplate = true
            nsMenuItem.image = namedImage
        }

        // 记录菜单标题到动作的映射（兼容旧逻辑），并把动作字符串放到 representedObject
        if let action = menuItem.action {
            let param = action.parameter ?? ""
            let actionString = "\(action.type.rawValue)|\(param)"
            titleToActionMap[displayedTitle] = actionString
            nsMenuItem.representedObject = actionString
        }

        // 处理子菜单
        if let children = menuItem.children, !children.isEmpty {
            let submenu = NSMenu(title: displayedTitle)
            for childItem in children {
                if shouldDisplay(childItem, for: contextType, isMultiSelection: isMultiSelection) {
                    let childNSMenuItem = buildMenuItem(from: childItem, contextType: contextType, isMultiSelection: isMultiSelection)
                    submenu.addItem(childNSMenuItem)
                }
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
