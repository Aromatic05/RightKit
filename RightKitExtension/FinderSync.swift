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
        
        // 监听配置更改通知（使用 DistributedNotificationCenter 和正确的通知名）
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(configurationDidChange),
            name: NSNotification.Name("com.aromatic.RightKit.configUpdated"),
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
        // 配置更改时重新加载菜单
        MenuBuilder.shared.reloadConfiguration()
    }
    
    deinit {
        DistributedNotificationCenter.default().removeObserver(self)
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
        let selectedItems = FIFinderSyncController.default().selectedItemURLs() ?? []
        let isMultiSelection = selectedItems.count > 1
        var contextType: DisplayCondition = .all
        if isMultiSelection {
            contextType = .all
        } else if selectedItems.count == 1 {
            let url = selectedItems[0]
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
                contextType = isDir.boolValue ? .folder : .file
            } else {
                contextType = .file // fallback
            }
        } else {
            // 右键背景
            contextType = .folder
        }
        return MenuBuilder.shared.buildMenu(contextType: contextType, isMultiSelection: isMultiSelection)
    }
    
    @IBAction func menuItemClicked(_ sender: AnyObject?) {
        guard let menuItem = sender as? NSMenuItem else {
            NSLog("RightKit: menuItemClicked - sender is not NSMenuItem")
            return
        }
        
        NSLog("RightKit: menuItemClicked called for: %@", menuItem.title)
        
        let target = FIFinderSyncController.default().targetedURL()
        let selectedItems = FIFinderSyncController.default().selectedItemURLs() ?? []
        
        // 优先从 representedObject 读取动作字符串，回退到标题映射
        let actionString = (menuItem.representedObject as? String) ?? MenuBuilder.shared.getAction(for: menuItem.title)
        
        if let actionString = actionString {
            NSLog("RightKit: Processing action: %@", actionString)
            ActionHandler.shared.handleAction(actionString: actionString, targetURL: target, selectedItems: selectedItems)
        } else {
            NSLog("RightKit: No action found for menu item title")
        }
    }
    
    // MARK: - Additional Menu Actions
    
    @objc func openConfigApp(_ sender: NSMenuItem) {
        NSLog("Opening RightKit configuration app")
        let bundleIdentifier = "com.aromatic.RightKit"
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
                if let error = error {
                    NSLog("Failed to open RightKit configuration app: %@", error.localizedDescription)
                } else {
                    NSLog("RightKit configuration app opened successfully")
                }
            }
        } else {
            NSLog("Could not find RightKit app with bundle identifier: %@", bundleIdentifier)
        }
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
