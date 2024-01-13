//
//  ContentView.swift
//  SimpleWeb3Wallet
//
//  Created by Quach Ha Chan Thanh on 25/12/23.
//

import SwiftUI
import Combine
import URLImage

struct ContentView: View {
    var body: some View {
        NavigationView {
            MainView(viewModel: MainViewModel())
        }
    }
}

struct MainView: View {
    
    @StateObject var viewModel: MainViewModel
    
    var body: some View {
        VStack {
            if let cachedMmemonic = viewModel.cachedMmemonic {
                VStack {
                    Button {
                        viewModel.reset()
                    } label: {
                        Text("Rest Mmemonic")
                    }
                    
                    CreateHDWallet(mnemonicWords: cachedMmemonic.components(separatedBy: " "))
                }
            } else {
                Button {
                    viewModel.generateNewMnemonic()
                } label: {
                    Text("Generate New Mmemonic")
                }

            }
        }
        
    }
}

class MainViewModel: ObservableObject {
    
    @Published private(set) var cachedMmemonic: String?
    private let cacheKey = "cache_Mmemonic"
    
    init() {
        loadCachedMnemonic()
    }
    
    func loadCachedMnemonic() {
        guard let saved = UserDefaults.standard.string(forKey: cacheKey) else {
            cachedMmemonic = "truck under trouble disease become myth three almost bicycle jaguar coyote horror"
            return
        }
            
        cachedMmemonic = saved
    }
    
    func generateNewMnemonic() {
        // Mnemonic => Seed
        let hdWallet = HDWallet(myEntrophy: Data.random(count: 16))
        let cachedMmemonic = hdWallet.generateMnemonic().joined(separator: " ")
        print("cachedMmemonic: \(cachedMmemonic)")
        self.cachedMmemonic = cachedMmemonic
    }
    
    func reset() {
        self.cachedMmemonic = nil
    }
}

struct CreateHDWallet: View {
    let mnemonicWords: [String]
    @State var ethereumAddress: String?
    @State var tokenBalanceList: [TokenInfo]?
    let definedTokenSymbolImage: [String: URL] = [
        "OKB": .init(string: "https://static.oklink.com/cdn/wallet/logo/okb.png")!,
        "TUSD": .init(string: "https://static.oklink.com/cdn/wallet/logo/tusd01.png")!,
    ]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Mnemonic words: ")
                .font(.title)
                .padding(.bottom, 16)
            
            VStack(alignment: .center) {
                ForEach(0..<mnemonicWords.count / 2, id: \.self) { row in
                    HStack(spacing: 20) {
                        Spacer()
                        
                        let leftIndex = row
                        Text("\(leftIndex + 1). " + mnemonicWords[leftIndex])
                            .font(.title3)
                            .padding(4)
                        
                        Spacer()
                        
                        let rightIndex = (mnemonicWords.count / 2) + row
                        Text("\(rightIndex + 1). " + mnemonicWords[rightIndex])
                            .font(.title3)
                            .padding(4)
                        
                        Spacer()
                    }
                }
            }
            .background(Color.gray)
            .cornerRadius(8)
            .padding(.bottom, 16)
            
            Text("Ethereum Address: ")
                .font(.title)
                .padding(.bottom, 10)
            
            if let ethereumAddress {
                Text(ethereumAddress)
                    .font(.title3)
                    .padding(.all, 10)
                    .background(Color.cyan)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Text("Assets: ")
                .font(.title)
                .padding(.bottom, 10)
            
            if let tokenBalanceList {
                ForEach(tokenBalanceList, id: \.token) { item in
                    VStack {
                        HStack(spacing: 10) {
                            if let url = definedTokenSymbolImage[item.token.uppercased()] {
                                URLImage(url) { image in
                                    image
                                        .resizable()
                                        .frame(width: 32, height: 32)
                                        .aspectRatio(contentMode: .fit)
                                        .clipShape(Circle()) // Clip the image into a circle
                                        .overlay(Circle().stroke(Color.white, lineWidth: 0.5))
                                }
                            }
                            
                            VStack(alignment: .leading) {
                                Text(item.token)
                                    .font(.title2)
                                    .multilineTextAlignment(.leading)
                                
                                Text(item.priceUsd.prefix(6))
                                    .font(.callout)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            VStack(alignment: .trailing) {
                                Text(item.holdingAmount)
                                    .font(.title2)
                                    .multilineTextAlignment(.trailing)
                                Text(item.valueUsd.prefix(6))
                                    .font(.callout)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                        
                        Rectangle()
                            .frame(height: 0.5)
                            .padding(.vertical, 5)
                    }
                    
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .onAppear {

            let seed = Mnemonic.createSeed(mnemonic: self.mnemonicWords.joined(separator: " "))
            let (priv, pub, address) = try! HDWallet.generateEthereumKeyPair(seed: seed)
            
            print("Pub: \(pub.hexString)")
            print("Priv: \(priv.hexString)")
            ethereumAddress = address
            
            getTokenBalance(address: address) { result in
                switch result {
                case .success(let response):
                    print("Code: \(response.code)")
                    print("Message: \(response.msg)")
                    self.tokenBalanceList = response.data.first?.tokenList
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


