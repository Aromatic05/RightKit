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
        
        // 监控根目录，这样我们的右键菜单可以在任何地方出现
        // 注意：这并不会消耗大量资源，系统会为我们优化处理
        FIFinderSyncController.default().directoryURLs = [URL(fileURLWithPath: "/")]
        
        NSLog("RightKitExtension successfully launched.")
    }
    
    // MARK: - Menu support
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        // 创建一个菜单，作为我们所有自定义项的容器
        let menu = NSMenu(title: "")
        
        // 添加我们的第一个硬编码菜单项
        // action: 是点击后要执行的方法
        // keyEquivalent: 是快捷键，这里留空
        menu.addItem(withTitle: "Hello, RightKit!", action: #selector(helloAction(_:)), keyEquivalent: "")
        
        // 返回构建好的菜单，Finder会将其显示出来
        return menu
    }
    
    /// 我们自定义的菜单项点击后会调用的方法
    @IBAction func helloAction(_ sender: AnyObject?) {
        // FIFinderSyncController.default().targetedURL() 可以获取到你右键点击时鼠标指向的文件或文件夹的 URL
        let targetURL = FIFinderSyncController.default().targetedURL()
        
        // FIFinderSyncController.default().selectedItemURLs() 可以获取到所有被选中的文件/文件夹的 URL 数组
        let selectedURLs = FIFinderSyncController.default().selectedItemURLs()
        
        // 通过 NSLog 打印日志，方便我们调试
        NSLog("Hello, RightKit! action triggered.")
        NSLog("Targeted URL: \(targetURL?.path ?? "None")")
        NSLog("Selected URLs: \(selectedURLs?.map { $0.path } ?? [])")
    }
}
