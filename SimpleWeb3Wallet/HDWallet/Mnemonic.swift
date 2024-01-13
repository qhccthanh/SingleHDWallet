//
//  Mnemonic.swift
//  SimpleWeb3Wallet
//
//  Created by Quach Ha Chan Thanh on 1/1/24.
//

import Foundation
import CryptoKit
import CommonCrypto

class Mnemonic {
    static func createSeed(mnemonic: String, withPassphrase passphrase: String = "") -> Data {
        guard let password = mnemonic.decomposedStringWithCompatibilityMapping.data(using: .utf8) else {
            fatalError("Nomalizing password failed in \(self)")
        }
        
        guard let salt = ("mnemonic" + passphrase).decomposedStringWithCompatibilityMapping.data(using: .utf8) else {
            fatalError("Nomalizing salt failed in \(self)")
        }
        
        return PBKDF2SHA512(password: password.bytes, salt: salt.bytes)
    }
}

func PBKDF2SHA512(password: [UInt8], salt: [UInt8]) -> Data {
    var derivedKey = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))

    _ = password.withUnsafeBytes { passwordPtr in
        salt.withUnsafeBytes { saltPtr in
            CCKeyDerivationPBKDF(
                CCPBKDFAlgorithm(kCCPBKDF2),
                passwordPtr.baseAddress!.assumingMemoryBound(to: Int8.self),
                password.count,
                saltPtr.baseAddress!.assumingMemoryBound(to: UInt8.self),
                salt.count,
                CCPBKDFAlgorithm(kCCPRFHmacAlgSHA512),
                UInt32(2048),
                &derivedKey,
                derivedKey.count
            )
        }
    }

    return Data(derivedKey)
}
