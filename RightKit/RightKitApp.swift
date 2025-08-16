//
//  RightKitApp.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import SwiftUI

@main
struct RightKitApp: App {
    
    init() {
        // 在应用启动时初始化默认配置
        ConfigurationManager.initializeDefaultConfiguration()
        
        // 检查并请求“完全磁盘访问权限”
        PermissionManager.checkAndRequestFullDiskAccess()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
