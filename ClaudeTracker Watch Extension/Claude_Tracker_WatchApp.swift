//
//  Claude_Tracker_WatchApp.swift
//  Claude Tracker Watch Watch App
//
//  Created by Cristian Paniagua on 27/03/2026.
//

import SwiftUI

@main
struct Claude_Tracker_Watch_Watch_AppApp: App {
    @State private var store = TokenStore()
    @State private var receiver: WatchSessionReceiver?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .onAppear {
                    if receiver == nil {
                        receiver = WatchSessionReceiver(store: store)
                    }
                }
        }
    }
}
