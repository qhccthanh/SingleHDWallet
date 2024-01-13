//
//  PrivateKey.swift
//  SimpleWeb3Wallet
//
//  Created by Quach Ha Chan Thanh on 1/1/24.
//

import Foundation
import BigInt
import CryptoKit

struct PrivateKey {
    let raw: Data
    let chainCode: Data
    let index: UInt32
    
    init(seed: Data) {
        print("Seed: \(seed.hexString)")
        
        let output = HMACSHA512(key: "Bitcoin seed".data(using: .ascii)!, data: seed)
        self.raw = output[0..<32]
        
        print("Master key: \(raw.hexString)")
        self.chainCode = output[32..<64]
        self.index = 0
    }
    
    private init(privateKey: Data, chainCode: Data, index: UInt32) {
        self.raw = privateKey
        self.chainCode = chainCode
        self.index = index
    }
    
    var publicKey: PublicKey {
        return PublicKey(privateKey: raw)
    }
    
    func get() -> String {
        return self.raw.hexString
    }
    
    func derived(at node: DerivationNode) -> PrivateKey {
        let edge: UInt32 = 0x80000000
        guard (edge & node.index) == 0
        else { fatalError("Invalid child index") }
        
        var data = Data()
        switch node {
        case .hardened:
            data += UInt8(0)
            data += raw
        case .notHardened:
            data += raw.generatePublicKey(compressed: true)
        }
        
        let derivingIndex = CFSwapInt32BigToHost(node.hardens ? (edge | node.index) : node.index)
        data += derivingIndex
        
        let digest = HMACSHA512(key: chainCode, data: data)
        let factor = BInt(data: digest[0..<32])
        
        let curveOrder = BInt(hex: "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141")!
        let derivedPrivateKey = ((BInt(data: raw) + factor) % curveOrder).data
        let derivedChainCode = digest[32..<64]
        
        return PrivateKey(
            privateKey: derivedPrivateKey,
            chainCode: derivedChainCode,
            index: derivingIndex
        )
    }
}

enum DerivationNode {
    case hardened(UInt32)
    case notHardened(UInt32)
    
    public var index: UInt32 {
        switch self {
        case .hardened(let index):
            return index
        case .notHardened(let index):
            return index
        }
    }
    
    public var hardens: Bool {
        switch self {
        case .hardened:
            return true
        case .notHardened:
            return false
        }
    }
}

protocol BinaryConvertible {
    static func +(lhs: Data, rhs: Self) -> Data
    static func +=(lhs: inout Data, rhs: Self)
}

extension BinaryConvertible {
    static func +(lhs: Data, rhs: Self) -> Data {
        var value = rhs
        let data = Data(buffer: UnsafeBufferPointer(start: &value, count: 1))
        return lhs + data
    }
    
    static func +=(lhs: inout Data, rhs: Self) {
        lhs = lhs + rhs
    }
}

extension UInt16: BinaryConvertible {}
extension UInt64: BinaryConvertible {}
extension UInt32: BinaryConvertible {}
extension UInt8: BinaryConvertible {}
extension Int16: BinaryConvertible {}
extension Int32: BinaryConvertible {}
extension Int64: BinaryConvertible {}
extension Int: BinaryConvertible {}

func HMACSHA512(key: Data, data: Data) -> Data {
    return HMAC<SHA512>.authenticationCode(for: data, using: .init(data: key.bytes))
        .withUnsafeBytes { Data($0) }
}
