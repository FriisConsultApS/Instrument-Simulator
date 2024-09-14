//
//  PadView.swift
//  Instrument Simulator
//
//  Created by Per Friis on 14/09/2024.
//

import SwiftUI

struct PadView: View {
    @Environment(InstrumentController.self) private var controller
    var pad: SaxophonePads

    var body: some View {
        ZStack{
            if controller.pads.contains(pad) {
                Circle()
                    .fill(Color.red)
            }
            Circle()
                .stroke(style: StrokeStyle(lineWidth: 8))
        }
        .background(Color.gray, in: Circle())
        .padding(4)
        .gesture(DragGesture(minimumDistance: 0)
            .onChanged({ _ in
                guard !controller.pads.contains(pad) else { return }
                controller.pads.insert(pad)
                performHapticFeedback()
                controller.play()
            })
                .onEnded({ _ in
                    guard controller.pads.contains(pad) else { return }
                    controller.pads.remove(pad)
                    performHapticFeedback()
                })
        )
    }

    private func performHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

}

#Preview {
    VStack {
        PadView(pad: .rIndex)
        PadView(pad: .rMiddle)
        PadView(pad: .rRing)
        Divider()
        PadView(pad: .lIndex)
        PadView(pad: .lMiddle)
        PadView(pad: .lRing)
        PadView(pad: .lPinkyTop)
        PadView(pad: .lPinkyBottom)
    }
    .environment(InstrumentController())
}
