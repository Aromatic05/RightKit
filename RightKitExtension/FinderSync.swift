//
//  FinderSync.swift
//  RightKitExtension
//
//  Created by Yiming Sun on 2025/8/15.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    
    override init() {
        super.init()
        
        NSLog("RightKit FinderSync launched from %@", Bundle.main.bundlePath as NSString)
        
        // 设置为监控所有目录，这样右键菜单就能在任何位置显示
        // 包括外接磁盘、桌面、文档等所有位置
        setupDirectoryMonitoring()
        
        // 监听配置更改通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(configurationDidChange),
            name: NSNotification.Name("RightKitConfigurationChanged"),
            object: nil
        )
    }
    
    private func setupDirectoryMonitoring() {
        // 获取所有挂载的卷（包括外接磁盘）
        var directoriesToMonitor: [URL] = []
        
        // 添加根目录 - 这样可以监控整个文件系统
        directoriesToMonitor.append(URL(fileURLWithPath: "/"))
        
        // 添加用户目录（修正：用 NSHomeDirectory() 获取）
        let homeDirectory = URL(fileURLWithPath: NSHomeDirectory())
        directoriesToMonitor.append(homeDirectory)
        
        // 添加桌面
        if let desktopDirectory = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
            directoriesToMonitor.append(desktopDirectory)
        }
        
        // 添加文档目录
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            directoriesToMonitor.append(documentsDirectory)
        }
        
        // 添加下载目录
        if let downloadsDirectory = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            directoriesToMonitor.append(downloadsDirectory)
        }
        
        // 获取所有挂载的卷（外接磁盘等）
        let mountedVolumeURLs = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: [])
        if let volumes = mountedVolumeURLs {
            for volume in volumes {
                // 排除系统特殊卷
                let path = volume.path
                if !path.hasPrefix("/System/Volumes/") && !path.hasPrefix("/private/") {
                    directoriesToMonitor.append(volume)
                }
            }
        }
        
        // 设置监控目录
        FIFinderSyncController.default().directoryURLs = Set(directoriesToMonitor)
        
        NSLog("RightKit: Monitoring directories: %@", directoriesToMonitor.map { $0.path }.joined(separator: ", "))
    }
    
    @objc private func configurationDidChange() {
        NSLog("RightKit: Configuration changed notification received")
        // 配置更改时可以重新加载菜单或执行其他操作
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Primary Finder Sync protocol methods
    
    override func beginObservingDirectory(at url: URL) {
        NSLog("RightKit: beginObservingDirectory: %@", url.path as NSString)
    }
    
    override func endObservingDirectory(at url: URL) {
        NSLog("RightKit: endObservingDirectory: %@", url.path as NSString)
    }
    
    // MARK: - Menu and toolbar item support
    
    override var toolbarItemName: String {
        return "RightKit"
    }
    
    override var toolbarItemToolTip: String {
        return "RightKit: 右键菜单增强工具"
    }
    
    override var toolbarItemImage: NSImage {
        return NSImage(systemSymbolName: "folder.badge.gearshape", accessibilityDescription: "RightKit") ?? NSImage(named: NSImage.folderName)!
    }
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
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
        let nsMenuItem = NSMenuItem(title: menuItem.name, action: #selector(menuItemClicked(_:)), keyEquivalent: "")
        
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
    
    @IBAction func menuItemClicked(_ sender: AnyObject?) {
        guard let menuItem = sender as? NSMenuItem else {
            NSLog("RightKit: menuItemClicked - sender is not NSMenuItem")
            return
        }
        
        NSLog("RightKit: menuItemClicked called for: %@", menuItem.title)
        
        let target = FIFinderSyncController.default().targetedURL()
        let selectedItems = FIFinderSyncController.default().selectedItemURLs() ?? []
        
        NSLog("RightKit: Target directory: %@", target?.path ?? "nil")
        NSLog("RightKit: Selected items count: %d", selectedItems.count)
        
        // 处理动作
        if let actionString = menuItem.representedObject as? String {
            NSLog("RightKit: Processing action: %@", actionString)
            handleAction(actionString: actionString, targetURL: target, selectedItems: selectedItems)
        } else {
            NSLog("RightKit: No action found for menu item, attempting fallback")
            // Fallback：根据菜单标题推断动作
            handleFallbackAction(menuTitle: menuItem.title, targetURL: target, selectedItems: selectedItems)
        }
    }
    
    private func handleAction(actionString: String, targetURL: URL?, selectedItems: [URL]) {
        let components = actionString.components(separatedBy: "|")
        guard components.count >= 1 else {
            NSLog("RightKit: Invalid action string format")
            return
        }
        
        let actionType = components[0]
        let parameter = components.count > 1 ? components[1] : ""
        
        NSLog("RightKit: Executing action type: %@, parameter: %@", actionType, parameter)
        
        switch actionType {
        case "createEmptyFile":
            createFile(filename: parameter.isEmpty ? "新建文件.txt" : parameter, in: targetURL)
        case "createFileFromTemplate":
            createFile(filename: parameter.isEmpty ? "新建文件.txt" : parameter, in: targetURL)
        case "createFolder":
            createFolder(name: parameter.isEmpty ? "新建文件夹" : parameter, in: targetURL)
        case "openTerminal":
            openTerminal(at: targetURL)
        default:
            NSLog("RightKit: Unknown action type: %@", actionType)
        }
    }
    
    private func handleFallbackAction(menuTitle: String, targetURL: URL?, selectedItems: [URL]) {
        NSLog("RightKit: Handling fallback action for: %@", menuTitle)
        
        // 根据菜单标题推断动作
        if menuTitle.contains("空白文本文件") || menuTitle.contains("新建文件") {
            createFile(filename: "新建文件.txt", in: targetURL)
        } else if menuTitle.contains("Markdown") {
            createFile(filename: "新建文档.md", in: targetURL)
        } else if menuTitle.contains("文件夹") {
            createFolder(name: "新建文件夹", in: targetURL)
        } else if menuTitle.contains("终端") || menuTitle.contains("Terminal") {
            openTerminal(at: targetURL)
        } else {
            NSLog("RightKit: Could not infer action from menu title: %@", menuTitle)
        }
    }
    
    private func createFile(filename: String, in targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        let fileURL = targetDirectory.appendingPathComponent(filename)
        
        NSLog("RightKit: Creating file '%@' in directory: %@", filename, targetDirectory.path)
        
        // 直接使用 FileManager 创建空文件
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: fileURL.path) {
            let success = fileManager.createFile(atPath: fileURL.path, contents: nil, attributes: nil)
            if success {
                NSLog("RightKit: Successfully created file: %@", filename)
            } else {
                NSLog("RightKit: Failed to create file: %@", filename)
            }
        } else {
            NSLog("RightKit: File already exists: %@", filename)
        }
    }
    
    private func createFolder(name: String, in targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        let folderURL = targetDirectory.appendingPathComponent(name)
        
        NSLog("RightKit: Creating folder '%@' at: %@", name, folderURL.path)
        
        do {
            try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: false, attributes: nil)
            NSLog("RightKit: Successfully created folder: %@", name)
        } catch {
            NSLog("RightKit: Error creating folder: %@", error.localizedDescription)
        }
    }
    
    private func openTerminal(at targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        
        NSLog("RightKit: Opening terminal at: %@", targetDirectory.path)
        
        let script = """
        tell application "Terminal"
            activate
            do script "cd '\(targetDirectory.path)'"
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var errorDict: NSDictionary?
            appleScript.executeAndReturnError(&errorDict)
            
            if let error = errorDict {
                NSLog("RightKit: Error opening terminal: %@", error.description)
            } else {
                NSLog("RightKit: Successfully opened terminal")
            }
        }
    }
}
