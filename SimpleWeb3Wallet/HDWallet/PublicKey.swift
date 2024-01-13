//
//  PublicKey.swift
//  SimpleWeb3Wallet
//
//  Created by Quach Ha Chan Thanh on 1/1/24.
//

import Foundation
import secp256k1
import SwiftKeccak

struct PublicKey {
    let compressedPublicKey: Data
    let uncompressedPublicKey: Data
    
    init(privateKey: Data) {
        self.compressedPublicKey = privateKey.generatePublicKey(compressed: true)
        self.uncompressedPublicKey = privateKey.generatePublicKey(compressed: false)
    }
    
    func generateEthAddress() -> String {
        let formattedData = uncompressedPublicKey.dropFirst()
        let addressData = keccak256(formattedData).suffix(20)
        return "0x" + addressData.hexString
    }
}

extension Data {
    func generatePublicKey(compressed: Bool) -> Data {
        let encrypter = EllipticCurveEncrypterSecp256k1()
        var publicKey = encrypter.createPublicKey(privateKey: self)
        return encrypter.export(publicKey: &publicKey, compressed: compressed)
    }
}
