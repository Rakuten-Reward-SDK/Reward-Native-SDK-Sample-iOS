//
//  UserSDKLoginView.swift
//  SampleAppPub
//
//  Created by Derick, Derick | RASIA on 7/11/24.
//

import RAuthenticationCore
import RAuthenticationUI
import UIKit
import SwiftUI
import RakutenRewardNativeSDK

struct UserSdkLoginView: UIViewControllerRepresentable {

    func makeUIViewController(context: Context) -> UserSdkLoginVC {
        let userSdkLoginVC = UserSdkLoginVC()
        return userSdkLoginVC
    }
    
    func updateUIViewController(_ uiViewController: UserSdkLoginVC, context: Context) {
        
    }
}

class UserSdkLoginVC: UIViewController {
    
    var currentUserAccount: RAuthenticationAccount? {
        didSet {
            if let token = currentUserAccount?.token, token.isValid() {
                self.accessToken = token.accessToken
                print("access token: \(accessToken)")
            }
        }
    }
    
    var accessToken: String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        
        // Handle user consent
        UserConsent.handleUserConsentFromSdkStatus()
    }
    
    func setupUI() {
        let loginButton = UIButton()
        view.addSubview(loginButton)
        loginButton.translatesAutoresizingMaskIntoConstraints = false
        loginButton.setTitle("Login User SDK", for: .normal)
        loginButton.setTitleColor(.systemBlue, for: .normal)
        
        NSLayoutConstraint.activate([
            loginButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loginButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            loginButton.widthAnchor.constraint(equalToConstant: 300),
            loginButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        loginButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(loginButtonTapped)))
        
        let startSessionButton = UIButton()
        view.addSubview(startSessionButton)
        startSessionButton.translatesAutoresizingMaskIntoConstraints = false
        startSessionButton.setTitle("Start Session", for: .normal)
        startSessionButton.setTitleColor(.systemBlue, for: .normal)
        
        NSLayoutConstraint.activate([
            startSessionButton.centerXAnchor.constraint(equalTo: loginButton.centerXAnchor),
            startSessionButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 16),
            startSessionButton.widthAnchor.constraint(equalToConstant: 300),
            startSessionButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        startSessionButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(startSessionButtonTapped)))
    }
    
    @objc func loginButtonTapped() {
        let settings = RAuthenticationSettings()
        let scopes: Set<String>
        settings.clientId = "" // TODO: set value here
        settings.clientSecret = "" // TODO: set value here
        settings.baseURL = URL(string: "")! // TODO: set value here
        scopes = Set("".split(separator: ",").map{ String($0) }) // TODO: set value here
        let loginDialog = RBuiltinLoginDialog(),
            accountSelectionDialog = RBuiltinAccountSelectionDialog()
        
        let presentationConfiguration = RBuiltinWorkflowPresentationConfiguration()
        presentationConfiguration.presenterViewController = self
        presentationConfiguration.presentationStyle = .fullScreen
        
        RBuiltinLoginWorkflow(
            authenticationSettings: settings,
            loginDialog: loginDialog,
            accountSelectionDialog: accountSelectionDialog,
            authenticatorFactory: RBuiltinJapanIchibaUserAuthenticatorFactory(scopes),
            presentationConfiguration: presentationConfiguration
        ) {
            [weak self] account, error in
            self?.currentUserAccount = account
        }.start()
    }
    
    @objc func startSessionButtonTapped() {
        guard let accessToken = accessToken else {
            print("Start session failed. Access token is nil")
            return
        }
        
        RakutenReward.shared.startSession(appCode: AppConstant.appcode, accessToken: accessToken, tokenType: .rae) { result in
            switch result {
            case .success(let user):
                print("Start session UserSdk successful. User: \(user)")
            case .failure(let sessionError):
                print("Start session UserSdk failed. Error: \(sessionError.localizedDescription)")
            }
        }
    }
}
