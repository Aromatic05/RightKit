import Foundation
import CryptoKit

enum FileHashType: String, CaseIterable {
    case md5 = "MD5"
    case sha1 = "SHA1"
    case sha256 = "SHA256"
    case sha512 = "SHA512"
}

struct FileHashResult {
    let type: FileHashType
    let value: String
}

class FileHashUtils {
    static func calculateHashes(for url: URL, types: [FileHashType]) -> [FileHashResult] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        var results: [FileHashResult] = []
        for type in types {
            let value: String
            switch type {
            case .md5:
                value = Insecure.MD5.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
            case .sha1:
                value = Insecure.SHA1.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
            case .sha256:
                value = SHA256.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
            case .sha512:
                value = SHA512.hash(data: data).map { String(format: "%02hhx", $0) }.joined()
            }
            results.append(FileHashResult(type: type, value: value))
        }
        return results
    }
}
