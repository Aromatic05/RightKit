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
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
