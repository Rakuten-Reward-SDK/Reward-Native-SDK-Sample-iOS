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
    @State private var currentSelectedActionCode = ""
    
    @State private var showOptionsAlert = false
    
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        VStack {
            Text("Mission List")
                .alert(isPresented: $showOptionsAlert) {
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
            List(Array(missions.enumerated()), id: \.0) { index, mission in
                Button(action: {
                    currentSelectedActionCode = mission.actionCode
                    showOptionsAlert = true
                }) {
                    Text(mission.name)
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text(alertTitle), message: Text(alertMessage))
            }
        }
        .padding()
    }
    
    func logAction(actionCode: String) {
        alertTitle = ""
        alertMessage = ""
        
        RakutenReward.shared.logAction(actionCode: actionCode) { result in
            switch result {
            case .success():
                alertTitle = "Log action successful"
            case .failure(let error):
                alertTitle = "Log action failed. Error: \(error.localizedDescription)"
            }
            showAlert = true
        }
    }
    
    func getMissionDetails(actionCode: String) {
        alertTitle = ""
        alertMessage = ""
        
        RakutenReward.shared.getMissionDetails(actionCode: actionCode) { result in
            switch result {
            case .success(let missionDetails):
                alertTitle = "Get mission details successful"
                alertMessage = "\(missionDetails)"
            case .failure(let error):
                alertTitle = "Get mission details failed. Error: \(error.localizedDescription)"
            }
            showAlert = true
        }
    }
}
