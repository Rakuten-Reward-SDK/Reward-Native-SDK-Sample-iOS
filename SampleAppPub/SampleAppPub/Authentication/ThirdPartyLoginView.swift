//
//  ThirdPartyLoginView.swift
//  SampleAppPub
//
//  Created by Derick, Derick | RASIA on 5/11/24.
//

import SwiftUI
import RakutenRewardNativeSDK

struct ThirdPartyLoginView: View {
    
    var onDismiss: () -> Void
    let appcode = "anAuY28ucmFrdXRlbi5yZXdhcmQuaW9zLXNURkM4enBWRnI4eWxZekhHOW1QY1pLZDJTZEZiM1k5"
    
    var body: some View {
        VStack {
            Button(action: {
                openLoginPage()
            }) {
                Text("Open login page")
            }
            Button(action: {
                initSdkThirdPartyLogin()
            }) {
                Text("Init SDK / Start Session")
            }
        }
        .padding()
        .onDisappear {
            onDismiss()
        }
    }
    
    // MARK: - Initialize SDK Third Party
    
    func openLoginPage() {
        RakutenReward.shared.openLoginPage { loginPageCompletion in
            switch loginPageCompletion {
            case .logInCompleted:
                print("Open Third party login page - login completed")
            case .dismissByUser:
                print("Open Third party login page - login page dismissed by user")
            case .failToShowLoginPage:
                print("Open Third party login page - fail to show login page")
            @unknown default:
                break
            }
        }
    }
    
    func initSdkThirdPartyLogin() {
        RakutenReward.shared.startSession(appCode: appcode) { result in
            switch result {
            case .success(let sdkUser):
                print("Start session third party successful. User: \(sdkUser). You can now call SDK's APIs")
            case .failure(let rewardSdkSessionError):
                print("Start session third party failed. Error: \(rewardSdkSessionError.localizedDescription)")
            }
        }
    }
}

#Preview {
    ThirdPartyLoginView(onDismiss: {})
}
