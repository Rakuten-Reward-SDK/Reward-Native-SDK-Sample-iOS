//
//  UserConsent.swift
//  SampleAppPub
//
//  Created by Derick, Derick | RASIA on 12/11/24.
//

import RakutenRewardNativeSDK

class UserConsent {
    static func handleUserConsentFromSdkStatus() {
        RakutenReward.shared.didUpdateStatus = { status in
            print("SDK - did update sdk status callback. Status: \(status)")
            DispatchQueue.main.async {
                if status == .userNotConsent {
                    print("SDK - User has not consent. Try requesting for consent")
                    RakutenReward.shared.requestForConsent { status in
                        print("SDK - consent status callback: \(status)")
                        if status == .consentProvided {
                            print("SDK - consent provided")
                        } else {
                            print("SDK - consent not provided")
                        }
                    }
                }
            }
        }
    }
}
