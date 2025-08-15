//
//  Models.swift
//  RightKitExtension
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

/// 用于NSMenuItem的representedObject的Action类（支持NSCoding）
class MenuAction: NSObject, NSCoding {
    let type: ActionType
    let parameter: String?
    
    init(type: ActionType, parameter: String? = nil) {
        self.type = type
        self.parameter = parameter
        super.init()
        NSLog("MenuAction init - type: \(type.rawValue), parameter: \(parameter ?? "none")")
    }
    
    // MARK: - NSCoding
    required init?(coder: NSCoder) {
        NSLog("MenuAction init(coder:) called")
        
        guard let typeString = coder.decodeObject(forKey: "type") as? String else {
            NSLog("MenuAction init(coder:) - failed to decode type string")
            return nil
        }
        
        guard let actionType = ActionType(rawValue: typeString) else {
            NSLog("MenuAction init(coder:) - failed to create ActionType from: \(typeString)")
            return nil
        }
        
        self.type = actionType
        self.parameter = coder.decodeObject(forKey: "parameter") as? String
        
        super.init()
        
        NSLog("MenuAction init(coder:) success - type: \(type.rawValue), parameter: \(parameter ?? "none")")
    }
    
    func encode(with coder: NSCoder) {
        NSLog("MenuAction encode(with:) called - type: \(type.rawValue), parameter: \(parameter ?? "none")")
        coder.encode(type.rawValue, forKey: "type")
        if let parameter = parameter {
            coder.encode(parameter, forKey: "parameter")
        }
    }
    
    override var description: String {
        return "MenuAction(type: \(type.rawValue), parameter: \(parameter ?? "none"))"
    }
}

/// 动作类型枚举
enum ActionType: String, Codable {
    case createEmptyFile
    case createFileFromTemplate
    // 未来拓展...
    case copyFilePath
    case cutFile
    case runShellScript
}

/// 菜单配置根结构
struct MenuConfiguration: Codable {
    var version: String = "1.0"
    var items: [MenuItem]
}
