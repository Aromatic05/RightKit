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
        var urls = Set<URL>()
        let fm = FileManager.default

        // 添加用户主目录
        let homeURL = fm.homeDirectoryForCurrentUser
        urls.insert(homeURL)
        urls.insert(URL(fileURLWithPath: "/"))

        // 添加所有已挂载的卷（跳过隐藏卷）
        if let mounted = fm.mountedVolumeURLs(includingResourceValuesForKeys: [.isReadableKey], options: [.skipHiddenVolumes]) {
            for vol in mounted {
                urls.insert(vol)
            }
        }
        
        // 设置监控目录
        FIFinderSyncController.default().directoryURLs = Set(urls)
        
        NSLog("Monitoring directories for FinderSync: \(urls.map { $0.path }.joined(separator: ", "))")
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
        
        // 使用菜单标题来获取动作 - 这是最可靠的方法
        if let actionString = MenuBuilder.shared.getAction(for: menuItem.title) {
            NSLog("RightKit: Processing action: %@", actionString)
            ActionHandler.shared.handleAction(actionString: actionString, targetURL: target, selectedItems: selectedItems)
        } else {
            NSLog("RightKit: No action found for menu item title")
        }
    }
    
    // MARK: - Additional Menu Actions
    
    @objc func openConfigApp(_ sender: NSMenuItem) {
        NSLog("Opening RightKit configuration app")
        
        // 打开主应用
        let bundleIdentifier = "com.aromatic.RightKit"
        NSWorkspace.shared.launchApplication(withBundleIdentifier: bundleIdentifier,
                                           options: [],
                                           additionalEventParamDescriptor: nil,
                                           launchIdentifier: nil)
    }
    
    @objc func showAbout(_ sender: NSMenuItem) {
        NSLog("Showing RightKit about dialog")
        
        let alert = NSAlert()
        alert.messageText = "RightKit"
        alert.informativeText = "macOS 右键菜单增强工具\n版本 1.0\n\n© 2025 Aromatic"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}
