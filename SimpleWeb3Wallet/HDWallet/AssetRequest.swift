//
//  AssetRequest.swift
//  SimpleWeb3Wallet
//
//  Created by Quach Ha Chan Thanh on 1/1/24.
//

import Foundation

func getTokenBalance(address: String, completion: @escaping (Result<TokenBalanceResponse, Error>) -> Void) {
let urlString = "https://www.oklink.com/api/v5/explorer/address/address-balance-fills?chainShortName=ETH&address=\(address)&protocolType=token_20&limit=10"

var request = URLRequest(url: URL(string: urlString)!)
request.setValue("894a3abb-39ed-4d97-9bb8-9a30a7c67bb4", forHTTPHeaderField: "Ok-Access-Key")

URLSession.shared.dataTask(with: request) { data, response, error in
    guard let data = data, error == nil else {
        completion(.failure(error ?? NetworkError.unknown))
        return
    }

    do {
        let decoder = JSONDecoder()
        let result = try decoder.decode(TokenBalanceResponse.self, from: data)
        completion(.success(result))
    } catch {
        completion(.failure(error))
    }
}
.resume()
}

enum NetworkError: Error {
    case invalidURL
    case unknown
}

struct TokenBalanceResponse: Codable {
    let code: String
    let msg: String
    let data: [TokenBalanceData]
}

struct TokenBalanceData: Codable {
    let limit, page, totalPage: String
    let tokenList: [TokenInfo]
}

struct TokenInfo: Codable {
    let tokenContractAddress, holdingAmount: String
    let priceUsd, valueUsd, token: String
}
