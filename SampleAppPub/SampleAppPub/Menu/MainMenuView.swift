//
//  ContentView.swift
//  SampleAppPub
//
//  Created by Derick, Derick | RASIA on 5/11/24.
//

import SwiftUI
import RakutenRewardNativeSDK

struct Menu: Identifiable {
    let id = UUID()
    let name: String
}

struct MainMenuView: View {
    
//    let appcode = "anAuY28ucmFrdXRlbi5yZXdhcmQuaW9zLXNURkM4enBWRnI4eWxZekhHOW1QY1pLZDJTZEZiM1k5"
    
    let menus = [
        Menu(name: "Third Party Login"),
        Menu(name: "RID Login"),
        Menu(name: "RAE Login"),
        Menu(name: "Logout"),
        Menu(name: "Open SDK Portal"),
        Menu(name: "Open SPS Portal"),
        Menu(name: "Mission List")
    ]
    
    @State private var isThirdPartyLoginViewPresented = false
    @State private var isIdSdkLoginViewPresented = false
    @State private var isMissionListPresented = false
    
    @State private var sdkStatusText = RakutenReward.shared.status.description
    
    // Missions
    @State private var missions: [MissionLite] = []
    
    var body: some View {
        VStack {
            Text("SDK status: \(sdkStatusText)")
            List(Array(menus.enumerated()), id: \.element.id) { index, menu in
                Button(action: {
                    switch index {
                    case 0:
                        isThirdPartyLoginViewPresented = true
                    case 1:
                        isIdSdkLoginViewPresented = true
                    case 3:
                        RakutenReward.shared.logout {
                            sdkStatusText = RakutenReward.shared.status.description
                        }
                    case 4:
                        RakutenReward.shared.openPortal { result in
                            switch result {
                            case .success():
                                print("Open SDK portal successful")
                            case .failure(let sdkError):
                                print("Open SDK portal error: \(sdkError.localizedDescription)")
                            }
                        }
                    case 5:
                        RakutenReward.shared.openSpsPortal { result in
                            switch result {
                            case .success():
                                print("Open SPS portal successful")
                            case .failure(let sdkError):
                                print("Open SPS portal error: \(sdkError.localizedDescription)")
                            }
                        }
                    case 6:
                        RakutenReward.shared.getMissionLiteList { result in
                            switch result {
                            case .success(let missions):
                                self.missions = missions
                                isMissionListPresented = true
                            case .failure(let error):
                                print("")
                            }
                        }
                    default:
                        break
                    }
                }) {
                    Text(menu.name)
                }
            }
        }
        .navigationTitle("Saas Sample")
        .sheet(isPresented: $isThirdPartyLoginViewPresented) {
            ThirdPartyLoginView {
                sdkStatusText = RakutenReward.shared.status.description
            }
        }
        .sheet(isPresented: $isIdSdkLoginViewPresented) {
            IDSDKLoginView {
                sdkStatusText = RakutenReward.shared.status.description
            }
        }
        .sheet(isPresented: $isMissionListPresented) {
            MissionLiteListView(missions: $missions)
        }
        .padding()
    }
}

#Preview {
    MainMenuView()
}
