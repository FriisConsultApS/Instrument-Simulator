//
//  ContentView.swift
//  Instrument Simulator
//
//  Created by Per Friis on 14/09/2024.
//

import SwiftUI

struct ContentView: View {
    @Environment(InstrumentController.self) private var controller

    var body: some View {
        VStack {
            PadView(pad: .rIndex)
            PadView(pad: .rMiddle)
            PadView(pad: .rRing)
            Divider()
            PadView(pad: .lIndex)
            PadView(pad: .lMiddle)
            PadView(pad: .lRing)
            Spacer()
            PadView(pad: .lPinkyTop)
            PadView(pad: .lPinkyBottom)

            Text(controller.pads.name)

            Button(action: {
                controller.isAdvertising ?
                controller.stopAdvertising() :
                controller.startAdvertising()
            }) {
                Image(systemName: controller.isAdvertising ? "stop.circle.fill" : "play.circle.fill")
            }
        }
        .padding()
    }
}

#Preview {
    ContentView()
        .environment(InstrumentController())
}
