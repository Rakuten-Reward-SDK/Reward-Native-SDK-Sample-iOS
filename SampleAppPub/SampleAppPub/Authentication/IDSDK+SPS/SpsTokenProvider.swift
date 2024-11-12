//
//  SpsTokenProvider.swift
//  SampleAppPub
//
//  Created by Derick, Derick | RASIA on 12/11/24.
//

import UIKit
import RakutenRewardNativeSDK
import ScreenSDKCore
import RakutenOneAuthClaims
import RakutenOneAuthCore
import RakutenOneAuthDeviceCheckAssertions

class TokenProvider: SdkTokenProvider {
        
    static let shared = TokenProvider()
    
    let spsAudience = "" // TODO: set value here
    let spsScope: Set = [""] // TODO: set value here
    var session: Session?
    
    func getSpsCompatToken(completionHandler: @escaping (SpsCompatToken?, Error?) -> Void) {
        getSpsToken { exchangeToken, error in
            
            if let error = error {
                print("SPS - isSpsUser. Compat get exchange token error: \(error.localizedDescription).")
                completionHandler(nil, error)
                return
            }
            
            if let token = exchangeToken {
                print("SPS - isSpsUser. Compat get exchange token: \(exchangeToken).")
                completionHandler(SpsCompatToken.CatExchange(tokenValue: token), nil)
                return
            }
            
            completionHandler(nil, nil)
        }
    }
    
    func getExchangeToken() async throws -> String? {
        return try await withCheckedThrowingContinuation { continuation in
            getSpsToken { (exchangeToken, error) in
                if let error = error {
                    print("SPS - isSpsUser. get exchange token error: \(error.localizedDescription).")
                    continuation.resume(throwing: error)
                } else if let exchangeToken = exchangeToken {
                    print("SPS - isSpsUser. get exchange token: \(exchangeToken).")
                    continuation.resume(returning: exchangeToken)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    func getSpsToken(completion: @escaping (String?, Error?) -> Void) {
        print("SPS - isSpsUser. Getting exchange token...")
        let audience = self.spsAudience
        if let request = try? ArtifactRequestBuilder()
            .set(specifications:
                    ExchangeTokenConfigurationBuilder()
                .set(audience: spsAudience)
                .set(scope: spsScope)
                .build()
            ).build() {
            if let session = self.session {
                session.artifacts(request: request) { result in
                    if case let .success(response) = result {
                        if let exchangeToken = response.exchangeToken(audience: audience) {
                            completion(exchangeToken.value, nil)
                            return
                        }
                    } else if case let .failure(error) = result {
                        completion(nil, error)
                        return
                    }
                }
            } else {
                print("SPS - isSpsUser. session is empty...")
            }
        }
    }
}
