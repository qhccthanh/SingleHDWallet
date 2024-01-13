//
//  HDWallet.swift
//  SimpleWeb3Wallet
//
//  Created by Quach Ha Chan Thanh on 25/12/23.
//

import Foundation
import CryptoKit
import Crypto
import BigInt
import secp256k1
import CommonCrypto
import SwiftKeccak

class HDWallet {
    struct GenerateResult {
        let masterPrivKey: Data
        let chainCode: Data
    }
    
    let myEntrophy: Data
    
    init(myEntrophy: Data) { // entrophy
        self.myEntrophy = myEntrophy
    }
    
    func generateMnemonic() -> [String] {
        // 1. Create checksum
        let entropy = Data.random(count: 16).toBinaryString()
        let sha256Data = myEntrophy.sha256().toBinaryString()
        let checksum = String(sha256Data.prefix(entropy.count / 32))
        
        // 2. Combine entropy + checksum = 128 bit + 4 bit = 132
        let full = entropy + checksum
        
        // 3. Split into strings of 11 bits = 132/11 = 12 words
        var currentIndex = full.startIndex
        var pieces = [Substring]()
        while currentIndex < full.endIndex {
            let endIndex = full.index(currentIndex, offsetBy: min(11, full.distance(from: currentIndex, to: full.endIndex)))
            pieces.append(full[currentIndex..<endIndex])
            currentIndex = endIndex
        }
        
        // 4. Mapping pieces of 11 bit to a word to get the wordlist as an array
        var sentence = [String]()
        for piece in pieces {
            if let i = Int(piece, radix: 2), i < wordArray.count {
                let word = wordArray[i].trimmingCharacters(in: .whitespacesAndNewlines)
                sentence.append(word)
            }
        }
        return "cousin grass grief dance orange helmet hurry kitten cook lend loud breeze".components(separatedBy: " ")
    }
    
    private var wordArray: [String] {
        guard let wordListPath = Bundle.main.path(forResource: "bip39-wordlist", ofType: "txt"),
              let wordArray = try? String(contentsOfFile: wordListPath).components(separatedBy: "\n")
        else { return [] }
        
        return wordArray
    }
    
    static func generateEthereumKeyPair(seed: Data) throws -> (privateKey: Data, publicKey: Data, address: String) {
        // 1. Create seed from Mnemonics
        let seed = Mnemonic.createSeed(mnemonic: "cousin grass grief dance orange helmet hurry kitten cook lend loud breeze")
        
        // 2. Create Derive key => Child private key
        // In Web3, BIP-44 is a protocol that's followed by
        // Most of Wallet software to generate addresses
        let privateKey = PrivateKey(seed: seed)
            .derived(at: .hardened(44)) // Purpose such as 44, 49, 84
            .derived(at: .hardened(60)) // CoinType such as 60(Ethereum), 0 (BTC)
            .derived(at: .hardened(0)) // Account number
            .derived(at: .notHardened(0)) // Receiving
            .derived(at: .notHardened(0)) // Change
        
        // 3. Generate address in Ethereum chain
        let formattedData = privateKey.raw
            .generatePublicKey(compressed: false)
            .dropFirst()
        let addressData = keccak256(formattedData).suffix(20)
        let ethAddress = "0x" + addressData.hexString
        print("aa \(ethAddress)")
        
        return (privateKey.raw, privateKey.publicKey.uncompressedPublicKey, address: ethAddress)
    }
}


// Extension to convert Data to hex string for better logging
extension Data {
    var hexString: String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    func sha256() -> Data {
        return Data(SHA256.hash(data: self))
    }
    
}

extension Data {
    static func random(count: Int) -> Data {
        var data = Data(count: count)
        _ = data.withUnsafeMutableBytes {
            SecRandomCopyBytes(kSecRandomDefault, count, $0.baseAddress!)
        }
        return data
    }
}

extension SymmetricKey {
    // MARK: - Instance Methods
    /// Serializes a `SymmetricKey` to a Base64-encoded `String`.
    func serialize() -> Data {
        return withUnsafeBytes { ptr in
            Data(bytes: ptr.baseAddress!, count: ptr.count)
        }
    }
}
