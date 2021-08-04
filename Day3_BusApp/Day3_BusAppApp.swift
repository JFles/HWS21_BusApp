//
//  Day3_BusAppApp.swift
//  Day3_BusApp
//
//  Created by Jeremy Fleshman on 8/4/21.
//

import SwiftUI

/// Injecting a data model as an EnvironmentObject
@MainActor
class UserData: ObservableObject {
    @Published var name = ""
    @Published var reference = ""

    var identifier: String {
        name + reference
    }
}

@main
struct Day3_BusAppApp: App {
    @StateObject private var userData = UserData()

    var body: some Scene {
        WindowGroup {
            TabView {
                ContentView()
                    .tabItem {
                        Label("Buses", systemImage: "bus")
                    }

                MyTicketView()
                    .tabItem {
                        Label("My Ticket", systemImage: "qrcode")
                    }
                    .badge(userData.identifier.isEmpty ? "!" : nil)
            }
            .environmentObject(userData)
        }
    }
}
