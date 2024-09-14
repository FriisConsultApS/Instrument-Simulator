//
//  Instrument_SimulatorApp.swift
//  Instrument Simulator
//
//  Created by Per Friis on 14/09/2024.
//

import SwiftUI

@main
struct Instrument_SimulatorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environment(InstrumentController())
    }
}
