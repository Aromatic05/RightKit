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
        return MenuBuilder.shared.buildMenu(for: menuKind)
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
            ActionHandler.shared.handleAction(actionString: actionString, targetURL: target, selectedItems: selectedItems)
        } else {
            NSLog("RightKit: No action found for menu item, attempting fallback")
            // Fallback：根据菜单标题推断动作
            ActionHandler.shared.handleFallbackAction(menuTitle: menuItem.title, targetURL: target, selectedItems: selectedItems)
        }
    }
}
