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
        
        // 生成唯一的文件名，处理重复文件
        let uniqueFileURL = generateUniqueFileURL(baseName: filename, in: targetDirectory)
        
        NSLog("RightKit: Creating file '%@' in directory: %@", uniqueFileURL.lastPathComponent, targetDirectory.path)
        
        // 直接使用 FileManager 创建空文件
        let fileManager = FileManager.default
        let success = fileManager.createFile(atPath: uniqueFileURL.path, contents: nil, attributes: nil)
        
        if success {
            NSLog("RightKit: Successfully created file: %@", uniqueFileURL.lastPathComponent)
            
            // 激活重命名功能
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.activateFileRename(for: uniqueFileURL)
            }
        } else {
            NSLog("RightKit: Failed to create file: %@", uniqueFileURL.lastPathComponent)
        }
    }
    
    private func createFolder(name: String, in targetURL: URL?) {
        let targetDirectory = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        
        // 生成唯一的文件夹名，处理重复文件夹
        let uniqueFolderURL = generateUniqueFolderURL(baseName: name, in: targetDirectory)
        
        NSLog("RightKit: Creating folder '%@' at: %@", uniqueFolderURL.lastPathComponent, targetDirectory.path)
        
        do {
            try FileManager.default.createDirectory(at: uniqueFolderURL, withIntermediateDirectories: false, attributes: nil)
            NSLog("RightKit: Successfully created folder: %@", uniqueFolderURL.lastPathComponent)
            
            // 激活重命名功能
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.activateFileRename(for: uniqueFolderURL)
            }
        } catch {
            NSLog("RightKit: Error creating folder: %@", error.localizedDescription)
        }
    }
    
    /// 生成唯一的文件URL，处理重复文件名
    private func generateUniqueFileURL(baseName: String, in directory: URL) -> URL {
        let fileManager = FileManager.default
        let baseURL = directory.appendingPathComponent(baseName)
        
        // 如果文件不存在，直接返回原始名称
        if !fileManager.fileExists(atPath: baseURL.path) {
            return baseURL
        }
        
        // 分离文件名和扩展名
        let nameWithoutExtension = (baseName as NSString).deletingPathExtension
        let fileExtension = (baseName as NSString).pathExtension
        
        // 生成带数字后缀的唯一文件名
        var counter = 1
        var uniqueURL: URL
        
        repeat {
            let uniqueName: String
            if fileExtension.isEmpty {
                uniqueName = "\(nameWithoutExtension) \(counter)"
            } else {
                uniqueName = "\(nameWithoutExtension) \(counter).\(fileExtension)"
            }
            uniqueURL = directory.appendingPathComponent(uniqueName)
            counter += 1
        } while fileManager.fileExists(atPath: uniqueURL.path)
        
        return uniqueURL
    }
    
    /// 生成唯一的文件夹URL，处理重复文件夹名
    private func generateUniqueFolderURL(baseName: String, in directory: URL) -> URL {
        let fileManager = FileManager.default
        let baseURL = directory.appendingPathComponent(baseName)
        
        // 如果文件夹不存在，直接返回原始名称
        if !fileManager.fileExists(atPath: baseURL.path) {
            return baseURL
        }
        
        // 生成带数字后缀的唯一文件夹名
        var counter = 1
        var uniqueURL: URL
        
        repeat {
            let uniqueName = "\(baseName) \(counter)"
            uniqueURL = directory.appendingPathComponent(uniqueName)
            counter += 1
        } while fileManager.fileExists(atPath: uniqueURL.path)
        
        return uniqueURL
    }
    
    /// 激活文件/文件夹的重命名功能 - 使用有效的方法
    private func activateFileRename(for fileURL: URL) {
        NSLog("RightKit: Attempting to activate rename for: %@", fileURL.path)
        
        // 使用有效的方法：直接在目标目录中选中文件
        DispatchQueue.main.async {
            let targetDirectory = fileURL.deletingLastPathComponent()
            NSWorkspace.shared.selectFile(fileURL.path, inFileViewerRootedAtPath: targetDirectory.path)
            
            NSLog("RightKit: Successfully selected file using effective method")
            
            // 延迟后尝试发送回车键激活重命名
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                self.attemptKeyboardRename(for: fileURL)
            }
        }
    }
    
    /// 尝试发送键盘事件激活重命名
    private func attemptKeyboardRename(for fileURL: URL) {
        NSLog("RightKit: Attempting keyboard rename activation")
        
        // 尝试更简单的AppleScript，避免复杂的应用程序引用
        let script = """
        delay 0.2
        tell application "System Events"
            keystroke return
        end tell
        """
        
        if let appleScript = NSAppleScript(source: script) {
            var errorDict: NSDictionary?
            appleScript.executeAndReturnError(&errorDict)
            
            if let error = errorDict {
                NSLog("RightKit: Keyboard event failed: %@", error.description)
                self.showRenameInstructions(for: fileURL)
            } else {
                NSLog("RightKit: Successfully sent keyboard event")
            }
        } else {
            self.showRenameInstructions(for: fileURL)
        }
    }
    
    /// 显示重命名指导通知
    private func showRenameInstructions(for fileURL: URL) {
        NSLog("RightKit: Showing rename instructions to user")        
        // 确保文件在Finder中被选中
        let workspace = NSWorkspace.shared
        workspace.activateFileViewerSelecting([fileURL])
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
