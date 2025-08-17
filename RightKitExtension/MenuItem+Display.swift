// filepath: /Volumes/sym10_apfs/Code/RightKit/RightKitExtension/MenuItem+Display.swift
//
//  MenuItem+Display.swift
//  RightKitExtension
//
//  Adds dynamic display title logic for menu items, including Cut/Paste toggle.
//

import Foundation

extension MenuItem {
    /// 动态显示标题：当为剪切动作时，根据当前剪切状态在“剪切文件”和“粘贴文件”之间切换
    var displayTitle: String {
        if let action = self.action, action.type == .cutFile {
            return CutPasteState.shared.hasPendingCut() ? "粘贴文件" : "剪切文件"
        }
        return self.name
    }
}
