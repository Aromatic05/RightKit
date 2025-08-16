import Foundation
import SwiftUI

struct ActionTypeUtils {
    static func displayName(for type: ActionType) -> String {
        switch type {
        case .createEmptyFile: return "新建空文件"
        case .createFileFromTemplate: return "模板文件"
        case .createFolder: return "新建文件夹"
        case .openTerminal: return "打开终端"
        case .copyFilePath: return "复制路径"
        case .cutFile: return "剪切文件"
        case .runShellScript: return "运行脚本"
        case .separator: return "分隔线"
        }
    }
    static func icon(for type: ActionType) -> String {
        switch type {
        case .createEmptyFile: return "doc"
        case .createFileFromTemplate: return "doc.badge.plus"
        case .createFolder: return "folder"
        case .openTerminal: return "terminal"
        case .copyFilePath: return "doc.on.doc"
        case .cutFile: return "scissors"
        case .runShellScript: return "play"
        case .separator: return "minus"
        }
    }
    static func parameterLabel(for type: ActionType) -> String {
        switch type {
        case .createEmptyFile:
            return "文件扩展名"
        case .createFileFromTemplate:
            return "模板文件名"
        case .runShellScript:
            return "脚本命令"
        default:
            return "参数"
        }
    }
    static func parameterPlaceholder(for type: ActionType) -> String {
        switch type {
        case .createEmptyFile:
            return "txt"
        case .createFileFromTemplate:
            return "template.txt"
        case .runShellScript:
            return "echo 'Hello World'"
        default:
            return "参数值"
        }
    }
    static func shouldShowParameterEditor(for type: ActionType) -> Bool {
        switch type {
        case .createEmptyFile, .createFileFromTemplate, .runShellScript:
            return true
        default:
            return false
        }
    }
}
