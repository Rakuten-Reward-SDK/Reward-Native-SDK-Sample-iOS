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
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
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
        .onAppear {
            // Handle user consent
            UserConsent.handleUserConsentFromSdkStatus()
        }
        .onDisappear {
            onDismiss()
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage))
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
        alertTitle = ""
        alertMessage = ""
        
        RakutenReward.shared.startSession(appCode: AppConstant.appcode) { result in
            switch result {
            case .success(let sdkUser):
                alertTitle = "Start session third party successful."
                alertMessage = " User: \(sdkUser). You can now call SDK's APIs"
                showAlert = true
            case .failure(let rewardSdkSessionError):
                alertTitle = "Start session third party failed. Error: \(rewardSdkSessionError.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    ThirdPartyLoginView(onDismiss: {})
}
