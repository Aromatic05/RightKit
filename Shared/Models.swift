//
//  Models.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import Foundation
import SwiftUI

/// 菜单项数据模型
struct MenuItem: Codable, Equatable, Identifiable {
    var id: UUID = UUID() // 唯一标识符
    var name: String          // 菜单项名称
    var icon: String?         // 图标名称 (SF Symbols 或内置资源)
    var action: Action?       // 关联的动作
    var children: [MenuItem]? // 子菜单
}

/// 动作数据模型
struct Action: Codable, Equatable {
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
    case openWithApp        // 添加打开应用动作
    case sendToDesktop      // 添加发送到桌面动作
    case hashFile           // 添加计算文件哈希值动作
    case deleteFile         // 添加删除文件动作
    case showHiddenFiles    // 添加显示隐藏文件动作
    case separator          // 添加分隔线动作
}

/// 菜单配置根结构
struct MenuConfiguration: Codable {
    var version: String = "1.0"
    var items: [MenuItem]
}

/// 模板信息数据模型
struct TemplateInfo: Codable, Identifiable, Equatable, Transferable, Hashable {
    let id = UUID()
    var fileName: String      // 模板文件名
    var displayName: String   // 显示名称
    var iconName: String?     // 图标名称
    
    private enum CodingKeys: String, CodingKey {
        case fileName, displayName, iconName
    }
    
    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .data)
    }
}

// MARK: - UI Extensions

extension MenuItem {    
    /// 判断是否为分隔线
    var isSeparator: Bool {
        return action?.type == .separator
    }
}
