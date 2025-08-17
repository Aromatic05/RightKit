// filepath: /Volumes/sym10_apfs/Code/RightKit/RightKitExtension/CutPasteState.swift
//
//  CutPasteState.swift
//  RightKitExtension
//
//  Tracks pending cut operations and validates against the pasteboard.
//

import Foundation
import AppKit

final class CutPasteState {
    static let shared = CutPasteState()
    private init() {}
    
    // App Group user defaults for shared state
    private var defaults: UserDefaults {
        if let suite = UserDefaults(suiteName: ConfigurationManager.appGroupID) {
            return suite
        }
        return UserDefaults.standard
    }
    
    private let cutFilesKey = "RightKit.CutFiles"
    private let cutTokenKey = "RightKit.CutToken"
    private let cutPBChangeKey = "RightKit.CutPBChangeCount"
    private let pasteboardMarkerType = NSPasteboard.PasteboardType("com.aromatic.RightKit.cut")
    
    /// Start a cut operation for the given files. Writes a marker to the pasteboard.
    func beginCut(urls: [URL]) {
        let paths = urls.map { $0.path }
        defaults.set(paths, forKey: cutFilesKey)
        let token = UUID().uuidString
        defaults.set(token, forKey: cutTokenKey)
        defaults.synchronize()
        
        let pb = NSPasteboard.general
        pb.clearContents()
        // Write URLs for interoperability
        _ = pb.writeObjects(urls as [NSPasteboardWriting])
        // Write our cut marker token
        pb.setString(token, forType: pasteboardMarkerType)
        defaults.set(pb.changeCount, forKey: cutPBChangeKey)
        defaults.synchronize()
        
        NSLog("RightKit: Cut started for %d item(s)", paths.count)
    }
    
    /// Clear any recorded cut state.
    func clear() {
        defaults.removeObject(forKey: cutFilesKey)
        defaults.removeObject(forKey: cutTokenKey)
        defaults.removeObject(forKey: cutPBChangeKey)
        defaults.synchronize()
        
        // Do not clear pasteboard globally; users may need it.
    }
    
    /// Returns the pending cut file URLs if valid; otherwise clears and returns empty.
    func pendingCutURLs() -> [URL] {
        guard let paths = defaults.array(forKey: cutFilesKey) as? [String],
              let token = defaults.string(forKey: cutTokenKey) else {
            return []
        }
        // Validate pasteboard still contains our marker token
        let pb = NSPasteboard.general
        if let pbToken = pb.string(forType: pasteboardMarkerType), pbToken == token {
            return paths.map { URL(fileURLWithPath: $0) }
        } else {
            // Pasteboard changed or marker missing; cut was interrupted.
            NSLog("RightKit: Pending cut invalidated by pasteboard change")
            clear()
            return []
        }
    }
    
    /// Whether there is a valid pending cut operation.
    func hasPendingCut() -> Bool {
        return !pendingCutURLs().isEmpty
    }
    
    /// 切换剪切/粘贴：有待粘贴则执行粘贴，否则开始剪切
    func cutOrPaste(targetURL: URL?, selectedItems: [URL]) {
        if hasPendingCut() {
            pasteFiles(to: targetURL)
        } else {
            beginCut(urls: selectedItems)
        }
    }

    /// 粘贴：将待剪切文件移动到目标目录，处理冲突与跨卷
    private func pasteFiles(to targetURL: URL?) {
        let pending = pendingCutURLs()
        guard !pending.isEmpty else {
            NSLog("RightKit: No pending cut to paste")
            return
        }
        let destDir = resolvePasteDestination(targetURL)
        NSLog("RightKit: Pasting %d item(s) to: %@", pending.count, destDir.path)
        
        var movedTargets: [URL] = []
        for src in pending {
            do {
                let dest = makeUniqueDestination(for: src, in: destDir)
                try moveItemSmart(from: src, to: dest)
                movedTargets.append(dest)
                NSLog("RightKit: Moved '%@' -> '%@'", src.lastPathComponent, dest.lastPathComponent)
            } catch {
                NSLog("RightKit: Paste failed for '%@': %@", src.path, error.localizedDescription)
            }
        }
        
        // 清除剪切状态
        clear()
        
        // 在 Finder 中选中粘贴后的项目
        if let first = movedTargets.first {
            let root = first.deletingLastPathComponent().path
            for url in movedTargets {
                NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: root)
            }
        }
    }

    private func resolvePasteDestination(_ targetURL: URL?) -> URL {
        let fm = FileManager.default
        var dir = targetURL ?? URL(fileURLWithPath: NSHomeDirectory())
        var isDir: ObjCBool = false
        if fm.fileExists(atPath: dir.path, isDirectory: &isDir), !isDir.boolValue {
            dir = dir.deletingLastPathComponent()
        }
        return dir
    }

    private func makeUniqueDestination(for source: URL, in directory: URL) -> URL {
        let fm = FileManager.default
        var isDir: ObjCBool = false
        fm.fileExists(atPath: source.path, isDirectory: &isDir)
        let baseName = source.lastPathComponent
        if isDir.boolValue {
            return generateUniqueFolderURL(baseName: baseName, in: directory)
        } else {
            return generateUniqueFileURL(baseName: baseName, in: directory)
        }
    }

    /// Move with cross-volume fallback (copy+remove)
    private func moveItemSmart(from src: URL, to dst: URL) throws {
        let fm = FileManager.default
        do {
            try fm.moveItem(at: src, to: dst)
        } catch {
            do {
                try fm.copyItem(at: src, to: dst)
                try fm.removeItem(at: src)
            } catch {
                throw error
            }
        }
    }

    /// 生成唯一的文件夹URL，处理重复文件夹名
    private func generateUniqueFolderURL(baseName: String, in directory: URL) -> URL {
        let fileManager = FileManager.default
        let baseURL = directory.appendingPathComponent(baseName)
        if !fileManager.fileExists(atPath: baseURL.path) {
            return baseURL
        }
        var counter = 1
        var uniqueURL: URL
        repeat {
            let uniqueName = "\(baseName) \(counter)"
            uniqueURL = directory.appendingPathComponent(uniqueName)
            counter += 1
        } while fileManager.fileExists(atPath: uniqueURL.path)
        return uniqueURL
    }

    /// 生成唯一的文件URL，处理重复文件名
    private func generateUniqueFileURL(baseName: String, in directory: URL) -> URL {
        let fileManager = FileManager.default
        let baseURL = directory.appendingPathComponent(baseName)
        if !fileManager.fileExists(atPath: baseURL.path) {
            return baseURL
        }
        let nameWithoutExtension = (baseName as NSString).deletingPathExtension
        let fileExtension = (baseName as NSString).pathExtension
        var counter = 1
        var uniqueURL: URL
        repeat {
            let uniqueName: String
            if fileExtension.isEmpty {
                uniqueName = "\(nameWithoutExtension) \(counter)"
            } else {
                uniqueName = "\(nameWithoutExtension) \(counter).\(fileExtension)"
            }
            uniqueURL = directory.appendingPathComponent(uniqueName)
            counter += 1
        } while fileManager.fileExists(atPath: uniqueURL.path)
        return uniqueURL
    }
}
