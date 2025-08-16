//
//  Models.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/15.
//

import Foundation
import SwiftUI

/// 菜单项数据模型
struct MenuItem: Codable, Equatable {
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
    case separator          // 添加分隔线动作
}

/// 菜单配置根结构
struct MenuConfiguration: Codable {
    var version: String = "1.0"
    var items: [MenuItem]
}

/// 模板信息数据模型
struct TemplateInfo: Codable, Identifiable, Equatable, Transferable {
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

extension MenuItem: Identifiable {
    var id: String {
        return "\(name)-\(icon ?? "")-\(action?.type.rawValue ?? "")"
    }
    /// 获取菜单项的显示图标
    var displayIcon: String {
        if let icon = icon {
            return icon
        }
        
        // 根据动作类型返回默认图标
        if let action = action {
            switch action.type {
            case .createEmptyFile:
                return "doc"
            case .createFileFromTemplate:
                return "doc.badge.plus"
            case .createFolder:
                return "folder.badge.plus"
            case .openTerminal:
                return "terminal"
            case .copyFilePath:
                return "doc.on.clipboard"
            case .cutFile:
                return "scissors"
            case .runShellScript:
                return "terminal.fill"
            case .separator:
                return "minus"
            }
        }
        
        // 如果有子菜单，返回文件夹图标
        if children != nil && !(children?.isEmpty ?? true) {
            return "folder"
        }
        
        return "questionmark"
    }
    
    /// 获取菜单项的类型描述
    var typeDescription: String {
        if let action = action {
            switch action.type {
            case .createEmptyFile:
                return "新建空文件"
            case .createFileFromTemplate:
                return "模板文件"
            case .createFolder:
                return "新建文件夹"
            case .openTerminal:
                return "打开终端"
            case .copyFilePath:
                return "复制路径"
            case .cutFile:
                return "剪切文件"
            case .runShellScript:
                return "运行脚本"
            case .separator:
                return "分隔线"
            }
        }
        
        if children != nil && !(children?.isEmpty ?? true) {
            return "子菜单"
        }
        
        return "未知"
    }
    
    /// 判断是否为分隔线
    var isSeparator: Bool {
        return action?.type == .separator
    }
}
