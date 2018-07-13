
public struct EIP155Signer {
    
    private let chainID: Int
    
    public init(chainID: Int) {
        self.chainID = chainID
    }
    
    public func sign(_ rawTransaction: EthRawTransaction, privateKey: PrivateKey) throws -> Data {
        let transactionHash = try hash(rawTransaction: rawTransaction)
        let signiture = try privateKey.signEth(hash: transactionHash)
        
        let (r, s, v) = calculateRSV(signiture: signiture)
        return try RLP.encode([
            rawTransaction.nonce,
            rawTransaction.gasPrice,
            rawTransaction.gasLimit,
            rawTransaction.to.data,
            rawTransaction.value,
            rawTransaction.data,
            v, r, s
        ])
    }
    
    public func hash(rawTransaction: EthRawTransaction) throws -> Data {
        return Crypto.hashSHA3_256(try encode(rawTransaction: rawTransaction))
    }
    
    public func encode(rawTransaction: EthRawTransaction) throws -> Data {
        return try RLP.encode([
            rawTransaction.nonce,
            rawTransaction.gasPrice,
            rawTransaction.gasLimit,
            rawTransaction.to.data,
            rawTransaction.value,
            rawTransaction.data,
            chainID, 0, 0 // EIP155
        ])
    }
    
    public func calculateRSV(signiture: Data) -> (r: BInt, s: BInt, v: BInt) {
        return (
            r: BInt(str: signiture[..<32].toHexString(), radix: 16)!,
            s: BInt(str: signiture[32..<64].toHexString(), radix: 16)!,
            v: BInt(signiture[64]) + 35 + 2 * chainID
        )
    }

    public func calculateSignature(r: BInt, s: BInt, v: BInt) -> Data {
        let isOldSignitureScheme = [27, 28].contains(v)
        let suffix = isOldSignitureScheme ? v - 27 : v - 35 - 2 * chainID
        let sigHexStr = hex64Str(r) + hex64Str(s) + suffix.asString(withBase: 16)
        return Data(hex: sigHexStr)
    }

    private func hex64Str(_ i: BInt) -> String {
        let hex = i.asString(withBase: 16)
        return String(repeating: "0", count: 64 - hex.count) + hex
    }
}
