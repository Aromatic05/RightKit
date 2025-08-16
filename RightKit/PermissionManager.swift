//
//  PermissionManager.swift
//  RightKit
//
//  Created by Yiming Sun on 2025/8/16.
//

import SwiftUI
import AppKit

struct PermissionManager {
    
    /// 检查并请求完全磁盘访问权限。
    static func checkAndRequestFullDiskAccess() {
        if hasFullDiskAccess() {
            print("✅ 应用已拥有完全磁盘访问权限。")
            return
        }
        
        print("⚠️ 应用尚未获得完全磁盘访问权限。开始执行触发与引导流程。")

        // 尝试访问一个受保护的目录以触发系统将应用添加到隐私列表中。
        let protectedPath = NSHomeDirectory() + "/Library/Safari"
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: protectedPath)
        } catch {
            print("访问被拒绝（预期行为），这会促使系统将应用添加到隐私列表中。")
        }

        // 确保 UI 操作在主线程上执行
        DispatchQueue.main.async {
            promptUserToGrantAccess()
        }
    }
    
    /// 通过尝试访问一个明确受系统保护的目录来检查权限。
    private static func hasFullDiskAccess() -> Bool {
        let protectedPath = NSHomeDirectory() + "/Library/Safari"
        do {
            _ = try FileManager.default.contentsOfDirectory(atPath: protectedPath)
            return true
        } catch {
            return false
        }
    }
    
    /// 显示一个标准的系统提示窗口，并根据 macOS 版本打开正确的设置页面。
    private static func promptUserToGrantAccess() {
        let alert = NSAlert()
        alert.messageText = "需要“完全磁盘访问权限”"
        alert.informativeText = """
        为了让“右键新建文件”功能在所有文件夹中都能正常工作，RightKit 需要您的授权。

        请点击“打开系统设置”，在“隐私与安全性”中找到“完全磁盘访问权限”，然后开启“RightKit”的开关。
        """
        alert.addButton(withTitle: "打开系统设置")
        alert.addButton(withTitle: "稍后")
        alert.alertStyle = .informational

        if alert.runModal() == .alertFirstButtonReturn {
            // --- 关键修改在这里 ---
            // 根据操作系统版本选择正确的 URL
            let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
            
            if let url = URL(string: urlString) {
                NSWorkspace.shared.open(url)
            } else {
                 print("无法创建URL: \(urlString)")
            }
        }
    }
}
