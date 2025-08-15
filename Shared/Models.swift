//
//  Models.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import Foundation

/// 菜单项数据模型
struct MenuItem: Codable {
    var name: String          // 菜单项名称
    var icon: String?         // 图标名称 (SF Symbols 或内置资源)
    var action: Action?       // 关联的动作
    var children: [MenuItem]? // 子菜单
}

/// 动作数据模型
struct Action: Codable {
    var type: ActionType      // 动作类型
    var parameter: String?    // 动作参数
}

/// 动作类型枚举
enum ActionType: String, Codable {
    case createEmptyFile
    case createFileFromTemplate
    case createFolder        // 添加创建文件夹动作
    case openTerminal        // 添加打开终端动作
    case copyFilePath
    case cutFile
    case runShellScript
}

/// 菜单配置根结构
struct MenuConfiguration: Codable {
    var version: String = "1.0"
    var items: [MenuItem]
}
