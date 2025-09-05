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
        // 初始化模板文件夹（如未配置则弹窗让用户选择路径获取权限）
        TemplateManager.initializeTemplateFolder()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 1000, idealWidth: 1000, minHeight: 750, idealHeight: 750)
        }
    }
}
