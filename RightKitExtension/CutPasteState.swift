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
}
