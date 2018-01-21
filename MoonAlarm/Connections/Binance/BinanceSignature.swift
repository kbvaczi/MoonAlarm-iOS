//
//  BinanceSignature.swift
//  MoonAlarm
//
//  Created by Kenneth Vaczi on 1/14/18.
//  Copyright © 2018 Vaczoway Solutions. All rights reserved.
//

import Foundation
import Alamofire
import CryptoSwift

extension Dictionary where Key == String, Value == Any {
    
    // HMAC SHA256 Signature used to sign requests
//    SIGNED endpoints require an additional parameter, signature, to be sent in the query string or request body.
//    Endpoints use HMAC SHA256 signatures. The HMAC SHA256 signature is a keyed HMAC SHA256 operation. Use your secretKey as the key and totalParams as the value for the HMAC operation.
//    The signature is not case sensitive.
//    totalParams is defined as the query string concatenated with the request body.
    
    func signForBinance(withSecretKey secretKey: String) -> Parameters {
        
        let encoding = URLEncoding.queryString
        let url = URL(string: "https://nothing.com/")
        let request = URLRequest(url: url!)
        do {
            let encoded = try encoding.encode(request, with: self)
            let queryString = String(describing: encoded).split(separator: "?").last
            if let qString = queryString {
                print(qString)
                let qStringData = String(qString).bytes
                let sigBytes = try HMAC(key: secretKey, variant: .sha256).authenticate(qStringData)
                let sigData = Data(bytes: sigBytes)
                let sigString = sigData.toHexString()
                var signedParams = self
                signedParams["signature"] = sigString
                return signedParams
            }
        } catch {
            print("error calculating HMAC signature")
        }
        return self
    }
    
}

// Remove square brackets for GET request
struct BinanceSignedEncoding: ParameterEncoding {
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        
        guard   var params = parameters,
                let signature = params["signature"] as? String else {
            print("no signature found")
            return try URLEncoding().encode(urlRequest, with: parameters)
        }

        params.removeValue(forKey: "signature")
        var request = try URLEncoding().encode(urlRequest, with: params)

        guard   let urlString = request.url?.absoluteString else { return request }
        
        let urlStringWithSignature = urlString + "&signature=" + signature
        request.url = URL(string: urlStringWithSignature)
        
//        let signatureInUrl = urlString.matches(for: "(/?|&)signature=.{64}").first else { return request }
//        let urlWithoutSignature = urlString.replacingOccurrences(of: signatureInUrl, with: "")
//        let urlWithSignatureAtEnd = urlWithoutSignature + signatureInUrl
        
        return request
    }
}

/*
 
 Testing in Terminal
 
 echo -n "symbol=LTCBTC&timestamp=1515968188109" | openssl dgst -sha256 -hmac "jKqjRkhF3NlXI5Ss5MfDVZWz8jJ0Xrfq1PhO1QzRptkQyg4JLvQpjXHB9Uyo4jF5"
 
 */
