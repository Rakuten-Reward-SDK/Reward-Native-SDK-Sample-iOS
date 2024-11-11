//
//  IDSDKLoginView.swift
//  SampleAppPub
//
//  Created by Derick, Derick | RASIA on 7/11/24.
//

import SwiftUI
import RakutenRewardNativeSDK
import RakutenOneAuthClaims
import RakutenOneAuthCore
import RakutenOneAuthDeviceCheckAssertions
import RakutenOneAuthRAE
import SwiftyJSON

class IDSDKLogin {
    let kClientID = "reward_sdk" // need remove
    let kIssuer = "https://login.account.rakuten.com"
    let kExTokenAudience = "https://prod.api-catalogue.gateway-api.global.rakuten.com"
    let kExTokenScopes: Set = ["mission-sdk"]
    
    var gracePeriod: TimeInterval = 0
    var userPresenceCheckDisabled: Bool = false
    var client: Client?
    var idProviderUrl: URL?
    var additionalScopes: String?
    var requestedAuthenticationMethod: String?
    var idLiteEnabled: Bool = false
    var silentLogin: Bool = false
    var requiredUerInfo: String?
    var proxyAudience: String?
    var deviceCheckTimeout: TimeInterval = 0
    
    var receiveAccessTokenHandler: ((String) -> Void)?
    var didUpdateinformationText: ((String) -> Void)?
    
    var session: Session? {
        didSet {
            //updateUI()
        }
    }
    
    init() {
        reset()
        setupDefaults()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(self.updateDefault),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
        
        updateDefault()
//        updateUI()
        prepareClient()
//        initSps()
    }
    
    // MARK: - Setup default settings

    func reset() {
        if UserDefaults.standard.bool(forKey: "reset_app") {
            UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            purgeIDSDKKeychainItems()
            setupDefaults()
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "Purge Key Chain Items", message: "Done.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                //self.present(alert, animated: true)
                self.session = nil
                //TokenProvider.shared.session = nil
            }
        }
    }

    func purgeIDSDKKeychainItems() {
        let secItemClasses = [
            kSecClassGenericPassword,
            kSecClassInternetPassword,
            kSecClassCertificate,
            kSecClassKey,
            kSecClassIdentity,
        ]
        for secItemClass in secItemClasses {
            let query = [kSecClass as CFString: secItemClass as CFString] as CFDictionary
            SecItemDelete(query)
        }
    }

    func setupDefaults() {
        if let settingsUrl = Bundle.main.url(forResource: "Root",
                                             withExtension: "plist",
                                             subdirectory: "Settings.bundle"),
            let settingsPlist = NSDictionary(contentsOf: settingsUrl),
            let preferences = settingsPlist["PreferenceSpecifiers"] as? [NSDictionary] {
            for prefSpecification in preferences {
                if let key = prefSpecification["Key"] as? String, let value = prefSpecification["DefaultValue"] {
                    // If key doesn't exists in userDefaults then register it, else keep original value
                    if UserDefaults.standard.value(forKey: key) == nil {
                        UserDefaults.standard.set(value, forKey: key)
                        NSLog("""
                        registerDefaultsFromSettingsBundle: Set following to UserDefaults \
                        - (key: \(key), value: \(value), type: \(type(of: value)))
                        """)
                    }
                }
            }
        }
    }

   @objc func updateDefault() {
        reset()
        let defaults = UserDefaults.standard
        if let url = defaults.string(forKey: "id_lite_provider_url") {
            idProviderUrl = URL(string: url)
        } else {
            idProviderUrl = nil
        }
        gracePeriod = defaults.double(forKey: "grace_period")
        additionalScopes = defaults.string(forKey: "additional_scopes")
        requestedAuthenticationMethod = defaults.string(forKey: "requested_authentication_method")
        silentLogin = defaults.bool(forKey: "silent_login")
        idLiteEnabled = defaults.bool(forKey: "id_lite_enable")
        requiredUerInfo = defaults.string(forKey: "required_user_info")
        proxyAudience = defaults.string(forKey: "proxy_audience")
        userPresenceCheckDisabled = defaults.bool(forKey: "user_presence_check_disabled")
        deviceCheckTimeout = defaults.double(forKey: "device_check_timeout")
    }
    
    // MARK: - Setup Session
    
    func prepareClient() {
        ServiceConfiguration.from(issuer: URL(string: kIssuer)!) { result in
            let serviceConfig: ServiceConfiguration
            switch result {
            case let .success(config):
                serviceConfig = config
            case let .failure(error):
                self.updateInfoText("Failed to retrieve ServiceConfiguration. Error: \(error.localizedDescription)")
                return
            }

            let securityPolicyBuilder = SecurityPolicyBuilder()
                .set(userPresenceGracePeriod: self.gracePeriod)

            if self.userPresenceCheckDisabled {
                securityPolicyBuilder.disableUserPresence()
            }

            if let client = try? DefaultClientBuilder()
                .set(clientId: self.kClientID)
                .set(serviceConfiguration: serviceConfig)
                .set(securityPolicy: securityPolicyBuilder.build())
                .build() {
                self.client = client
                self.loadSession()
            }
        }
    }
    
    func loadSession() {
        if let client = client {
            client.session(
                request: SessionRequestBuilder().build(),
                allowUserPresenceUI: true
            ) { result in
                switch result {
                case let .success(session):
                    self.session = session
                    self.updateInfoText("Session acquired!")
                    self.exchangeTokenRequest()
                    //self.sdkExchangeTokenRequest()
                    if let username = session.idToken.name {
                        self.updateInfoText("Session acquired! Welcome, username -> \(username)")
                    }
                    //self.updateUI()
                case let .failure(error):
                    switch error {
                    case is UserPresenceRequiredError:
                        self.updateInfoText("Session error: User presence is required")
                    case is MediationRequiredError:
                        self.updateInfoText("Session error: mediation is required. Please try to acquire a new session")
                    default:
                        self.updateInfoText("Session error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    // MARK: - Login logout

    func login() {
        if let client = client {
            DispatchQueue.global().async {
                var scopes: Set<String> = []

                if let additionalScopes = self.additionalScopes?.components(separatedBy: " ") {
                    scopes = scopes.union(Set(additionalScopes))
                }

                let requestBuilder = SessionRequestBuilder()
                    .useDeviceCheckClientAssertions(timeout: self.deviceCheckTimeout)
                    .set(scopes: scopes)

                if self.idLiteEnabled,
                   let url = self.idProviderUrl,
                   let rawToken = try? String(contentsOf: url),
                   let token = try? IDTokenBuilder().set(raw: rawToken).build() {
                    requestBuilder.set(federatedToken: token)
                    self.updateInfoText("Try request a new session with token: \(token.raw), token claims: \(token.claims)")
                }

                if let required = self.requiredUerInfo {
                    requestBuilder.set(requiredUserInfo: [required])
                }

                let mediationOptionsBuilder = MediationOptionsBuilder()
                    .set(presentationAnchorProvider: {
                        let windowScene = UIApplication.shared.connectedScenes.first as! UIWindowScene
                        let window = windowScene.windows.first!
                        return window
                    })

                if self.silentLogin {
                    mediationOptionsBuilder.silent()
                }

                if let requestedAuthenticationMethod = self.requestedAuthenticationMethod {
                    mediationOptionsBuilder.request(authorizationMethod: requestedAuthenticationMethod)
                }

                client.session(request: requestBuilder.build(),
                               mediationOptions: mediationOptionsBuilder.build()) { result in
                    if case let .success(session) = result {
                        //TokenProvider.shared.session = session
                        self.session = session
                        self.updateInfoText("Session loaded!")
                        self.exchangeTokenRequest()
                        if let userName = session.idToken.name {
                            self.updateInfoText("Welcome username -> \(userName)")
                        }
                        //self.updateUI()
                    } else if case let .failure(error) = result {
                        self.updateInfoText("Session error: \(error.localizedDescription)")
                    }
                }
            }
        }
    }

    func logout(session: Session) {
        session.logout { result in
            //TokenProvider.shared.session = nil
            self.session = nil
            self.updateInfoText("")
            if case let .failure(error) = result {
                self.updateInfoText("logout failed.\n\(error)")
                session.invalidate { _ in }
            }

            self.updateInfoText("logout sucessful")
            //self.updateUI()
        }
    }

    func refreshSession() {
        session?.refresh { result in
            switch result {
            case .success:
                self.updateInfoText("Session Refreshed.")
            case let .failure(error):
                self.updateInfoText("Refresh Session failed. Error: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Get Token
    
    func exchangeTokenRequest() {
        print("SDK exchange token request")
        let audience = kExTokenAudience
        if let request = try? ArtifactRequestBuilder()
            .set(specifications: ExchangeTokenConfigurationBuilder()
                .set(audience: audience)
                .set(scope: kExTokenScopes)
                .build())
            .build(),
            let session = self.session {
            session.artifacts(request: request) { result in
                if case let .success(response) = result {
                    if let exchangeToken = response.exchangeToken(audience: audience) {
                        self.updateInfoText("Exchange token artifacts request finished.\nExchange token expiration: \(exchangeToken.validUntil.description)\nExchange token value: \(exchangeToken.value)")
                        print("SDK exchange token request - received token successful")
                        self.getAccessTokenFromRPG(exchangeToken: exchangeToken.value) { result in
                            if let accessToken = result {
                                UserDefaults.standard.set(accessToken, forKey: "accessToken")
                                self.updateInfoText("Access token value: \(accessToken)")
                                print("SDK access token request - received token successful")
                                self.receiveAccessTokenHandler?(accessToken)
                                //self.getRzCookie()
                            } else {
                                self.updateInfoText("Get access token failed.")
                                print("SDK exchange token request - received token failed")
                            }
                        }
                    }
                } else if case let .failure(error) = result {
                    self.updateInfoText("Exchange token fail. Error: \(error.localizedDescription)")
                    print("SDK exchange token request - received token failed")
                }
            }
        }
    }

    func getAccessTokenFromRPG(exchangeToken:String, completion: @escaping (_ result: String?) -> ()) {
        let url = URL(string: "https://gateway-api.global.rakuten.com/RWDSDK/rpg-api/access_token")!
        var request = URLRequest(url: url)
        request.setValue(exchangeToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "GET"

        let task = URLSession(configuration: .default).dataTask(with: request) { (data, response, error) in
            if let error = error {
                self.updateInfoText("Access token error: \(error.localizedDescription)")
            } else {
                if let data = data {
                    do {
                        let dataJSON = try JSON(data: data)
                        completion(dataJSON["access_token"].description)
                    } catch {
                        self.updateInfoText("Access token error: \(error.localizedDescription)")
                    }
                }
            }
        }

        task.resume()
    }
    
    func updateInfoText(_ text: String) {
        didUpdateinformationText?(text)
    }
}


struct IDSDKLoginView: View {
    
    var onDismiss: () -> Void
    let appcode = "anAuY28ucmFrdXRlbi5yZXdhcmQuaW9zLXNURkM4enBWRnI4eWxZekhHOW1QY1pLZDJTZEZiM1k5"
    
    var idsdkLogin = IDSDKLogin()
    @State private var accessToken = ""
    @State private var informationText = ""
    
    var body: some View {
        VStack {
            Button(action: {
                idsdkLogin.login()
            }) {
                Text("Login")
            }
            Button(action: {
                initSdkIdSdk()
            }) {
                Text("Init SDK / Start Session")
            }
            Text(informationText)
        }
        .padding()
        .onAppear {
            idsdkLogin.receiveAccessTokenHandler = { accessToken in
                print("receive access token: \(accessToken)")
                self.accessToken = accessToken
            }
            
            idsdkLogin.didUpdateinformationText = { informationText in
                self.informationText = informationText
            }
        }
        .onDisappear {
            onDismiss()
        }
    }
    
    // MARK: - Initialize SDK ID SDK / RID
    
    func initSdkIdSdk() {
        RakutenReward.shared.startSession(appCode: appcode, accessToken: accessToken, tokenType: .rid) { result in
            switch result {
            case .success(let sdkUser):
                print("Start session IDSDK successful. User: \(sdkUser). You can now call SDK's APIs")
            case .failure(let rewardSdkSessionError):
                print("Start session IDSDK failed. Error: \(rewardSdkSessionError.localizedDescription)")
            }
        }
    }
    
    
}

#Preview {
    IDSDKLoginView(onDismiss: {})
}
