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

//  HMAC SHA256 Signature used to sign requests
//  SIGNED endpoints require an additional parameter, signature, to be sent in the query string or request body.
//  Endpoints use HMAC SHA256 signatures. The HMAC SHA256 signature is a keyed HMAC SHA256 operation. Use your secretKey as the key and totalParams as the value for the HMAC operation.
//  The signature is not case sensitive.
//  totalParams is defined as the query string concatenated with the request body.

extension BinanceAPI {
    
    struct SignedEncoding: ParameterEncoding {
        func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
            
            // Check to see if there are parameters
            guard   let params = parameters
                    else { return try URLEncoding().encode(urlRequest, with: nil) }
            
            var request = try URLEncoding().encode(urlRequest, with: params)
            
            // Get bytes from query string
            var queryBytes = [UInt8]()
            guard   let urlString = request.url?.absoluteString,
                    let querySubString = urlString.matches(for: "[?].+").first?.dropFirst()
                    else {
                    print("error retrieving url string for signing")
                    return request
            }
            let queryString = String(querySubString)
            queryBytes = queryString.bytes
            
            // Get bytes from request body
            var bodyBytes = [UInt8]()
            if let bodyData = request.httpBody {
                bodyBytes = bodyData.bytes
            }

            let messageBytes = queryBytes + bodyBytes
            
            // Generate signature and add on end of query string
            if let signature = hmacSignature(forBytes: messageBytes) {
                let needToAddQMark = urlString.matches(for: "?").first == nil
                var urlStringWithSignature = ""
                if needToAddQMark {
                    urlStringWithSignature = urlString + "?signature=" + signature
                } else {
                    urlStringWithSignature = urlString + "&signature=" + signature
                }
                request.url = URL(string: urlStringWithSignature)
            }
            
            return request
        }
        
        private func hmacSignature(forBytes bytes: [UInt8]) -> String? {
            let secretKey = BinanceAPI.apiSecret
            do {
                let sigBytes = try HMAC(key: secretKey, variant: .sha256).authenticate(bytes)
                let sigData = Data(bytes: sigBytes)
                let sigString = sigData.toHexString()
                return sigString
            } catch {
                print("error calculating HMAC signature")
                return nil
            }
        }
    }
    
}



/*
 
 Testing in Terminal
 
 echo -n "symbol=LTCBTC&timestamp=1515968188109" | openssl dgst -sha256 -hmac "jKqjRkhF3NlXI5Ss5MfDVZWz8jJ0Xrfq1PhO1QzRptkQyg4JLvQpjXHB9Uyo4jF5"
 
 */
