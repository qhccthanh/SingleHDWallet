//
//  EllipticCurveEncrypterSecp256k1.swift
//  SimpleWeb3Wallet
//
//  Created by Quach Ha Chan Thanh on 31/12/23.
//

import Foundation
import CryptoKit
import secp256k1

public class EllipticCurveEncrypterSecp256k1 {
    // holds internal state of the c library
    private let context: OpaquePointer
    
    public init() {
        context = secp256k1_context_create(UInt32(SECP256K1_CONTEXT_SIGN | SECP256K1_CONTEXT_VERIFY))!
    }
    
    deinit {
        secp256k1_context_destroy(context)
    }
    
    /// Recovers public key from the PrivateKey. Use import(signature:) to convert signature from bytes.
    ///
    /// - Parameters:
    ///   - privateKey: private key bytes
    /// - Returns: public key structure
    public func createPublicKey(privateKey: Data) -> secp256k1_pubkey {
        let privateKey = privateKey.bytes
        var publickKey = secp256k1_pubkey()
        _ = SecpResult(secp256k1_ec_pubkey_create(context, &publickKey, privateKey))
        return publickKey
    }
    
    /// Converts public key from library's data structure to bytes
    ///
    /// - Parameters:
    ///   - publicKey: public key structure to convert.
    ///   - compressed: whether public key should be compressed.
    /// - Returns: If compression enabled, public key is 33 bytes size, otherwise it is 65 bytes.
    public func export(publicKey: inout secp256k1_pubkey, compressed: Bool) -> Data {
        var output = Data(count: compressed ? 33 : 65)
        var outputLen: Int = output.count
        let compressedFlags = compressed ? UInt32(SECP256K1_EC_COMPRESSED) : UInt32(SECP256K1_EC_UNCOMPRESSED)
        output.withUnsafeMutableBytes { pointer -> Void in
            guard let p = pointer.bindMemory(to: UInt8.self).baseAddress else { return }
            secp256k1_ec_pubkey_serialize(context, p, &outputLen, &publicKey, compressedFlags)
        }
        return output
    }
}

enum SecpResult {
    case success
    case failure
    
    init(_ result:Int32) {
        switch result {
        case 1:
            self = .success
        default:
            self = .failure
        }
    }
}

extension Data {
    func toBinaryString() -> String {
        return reduce("") { result, byte in
            return result + String(byte, radix: 2).padLeft(toLength: 8, withPad: "0")
        }
    }
}

extension String {
    func padLeft(toLength length: Int, withPad pad: String) -> String {
        let padding = String(repeating: pad, count: max(0, length - count))
        return padding + self
    }
}

extension String {
    func dataFromBinaryString() -> Data? {
        let binaryString = self
        var data = Data()
        var currentIndex = binaryString.startIndex

        while currentIndex < binaryString.endIndex {
            let endIndex = binaryString.index(currentIndex, offsetBy: 8)
            guard let byte = UInt8(binaryString[currentIndex..<endIndex], radix: 2) else {
                return nil // Invalid binary string
            }
            data.append(byte)
            currentIndex = endIndex
        }

        return data
    }
}
