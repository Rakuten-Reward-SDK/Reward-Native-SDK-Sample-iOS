//
//  MissionLiteList.swift
//  SampleAppPub
//
//  Created by Derick, Derick | RASIA on 7/11/24.
//

import SwiftUI
import RakutenRewardNativeSDK

struct MissionLiteListView: View {
    
    @Binding var missions: [MissionLite]
    @State private var showAlert = false
    @State private var currentSelectedActionCode = ""
        
    var body: some View {
        VStack {
            Text("Mission List")
            List(Array(missions.enumerated()), id: \.0) { index, mission in
                Button(action: {
                    currentSelectedActionCode = mission.actionCode
                    showAlert = true
                }) {
                    Text(mission.name)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Options"),
                    message: Text(""),
                    primaryButton: .default(Text("Log Action"), action: {
                        logAction(actionCode: currentSelectedActionCode)
                    }),
                    secondaryButton: .default(Text("Get Mission Details"), action: {
                        getMissionDetails(actionCode: currentSelectedActionCode)
                    })
                )
            }
        }
        .padding()
    }
    
    func logAction(actionCode: String) {
        RakutenReward.shared.logAction(actionCode: actionCode) { result in
            switch result {
            case .success():
                print("Log action succcessful")
            case .failure(let error):
                print("Log action failed")
            }
        }
    }
    
    func getMissionDetails(actionCode: String) {
        RakutenReward.shared.getMissionDetails(actionCode: actionCode) { result in
            switch result {
            case .success(let missionDetails):
                print("Derickdebug mission details: \(missionDetails)")
            case .failure(let error):
                print("Derickdebug error: \(error.localizedDescription)")
            }
        }
    }
}

//#Preview {
//    MissionLiteListView(missions: [])
//}
