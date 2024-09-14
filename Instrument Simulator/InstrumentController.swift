//
//  InstrumentController.swift
//  Instrument Simulator
//
//  Created by Per Friis on 14/09/2024.
//

import Foundation
import AVKit
import CoreBluetooth
import OSLog

@Observable class InstrumentController: NSObject {
    let audionEngine: AVAudioEngine
    let intrument:  AVAudioUnitSampler

    var pads: SaxophonePads = []

    var isAdvertising: Bool = false
    var peripheralManager: CBPeripheralManager!
    var nodeCharacteristic: CBMutableCharacteristic?
    var bluetoothManagerState = CBManagerState.poweredOff

    private static let serviceUUID = CBUUID(string: "E56A082E-C49B-47CA-A2AB-389127B8CBE3")
    private static let nodeCharacteristicUUID = "0xFFF0"
    private var debugLog = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "\(InstrumentController.self)")

    override init() {
        audionEngine = AVAudioEngine()
        intrument = AVAudioUnitSampler()
        audionEngine.attach(intrument)
        audionEngine.connect(intrument, to: audionEngine.mainMixerNode, format: audionEngine.mainMixerNode.outputFormat(forBus: 0))
        super.init()
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: [CBPeripheralManagerOptionShowPowerAlertKey: true])

        do {
            if let url = Bundle.main.url(forResource: "SAX", withExtension: "WAV") {
                try intrument.loadAudioFiles(at: [url])
            }
            try audionEngine.start()
        } catch {
            debugLog.error("error: \(error as NSError)")
        }

    }

    func play() {
        if let nodeCharacteristic, peripheralManager.state == .poweredOn {

            peripheralManager.updateValue(pads.data, for: nodeCharacteristic, onSubscribedCentrals: nil)
        }
        intrument.startNote(pads.node, withVelocity: 120, onChannel: 0)
    }

    func startAdvertising() {
        guard bluetoothManagerState == .poweredOn else {
            debugLog.critical("Manager is not ready")
            return
        }

        var advertisementData = [String: Any]()
        advertisementData[CBAdvertisementDataLocalNameKey] = "Saxophone"
        advertisementData[CBAdvertisementDataServiceUUIDsKey] = [Self.serviceUUID]
        let nodeService = CBMutableService(type: Self.serviceUUID, primary: true)

        let nodeCharacteristic = CBMutableCharacteristic(type: .init(string: Self.nodeCharacteristicUUID), properties: [.read, .write], value: nil, permissions: .readable)
        nodeService.characteristics = [nodeCharacteristic]
        self.nodeCharacteristic = nodeCharacteristic
        peripheralManager.add(nodeService)

        peripheralManager.startAdvertising(advertisementData)
        isAdvertising = true
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func stopAdvertising() {
        guard bluetoothManagerState == .poweredOn else {
            return
        }

        peripheralManager.stopAdvertising()
        peripheralManager.removeAllServices()

        debugLog.info("Stopped advertising")
        isAdvertising = false
        UIApplication.shared.isIdleTimerDisabled = false
    }

}


// MARK: CBCentralManagerDelegate implementation
extension InstrumentController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        bluetoothManagerState = peripheral.state
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: (any Error)?) {
        debugLog.info("Started advertising")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        guard request.characteristic.uuid == CBUUID(string: Self.nodeCharacteristicUUID) else {
            return
        }

        request.value = pads.data
        peripheralManager.respond(to: request, withResult: .success)
    }

    func peripheralManagerIsReady(toUpdateSubscribers peripheral: CBPeripheralManager) {
        guard let nodeCharacteristic else { return }

        peripheralManager.updateValue(pads.data, for: nodeCharacteristic, onSubscribedCentrals: nil)
    }

}


struct SaxophonePads: OptionSet {
    var rawValue: UInt16

    static let rIndex = SaxophonePads(rawValue: 1 << 0)
    static let rMiddle = SaxophonePads(rawValue: 1 << 1)
    static let rRing = SaxophonePads(rawValue: 1 << 2)

    static let lIndex = SaxophonePads(rawValue: 1 << 4)
    static let lMiddle = SaxophonePads(rawValue: 1 << 5)
    static let lRing = SaxophonePads(rawValue: 1 << 6)
    static let lPinkyTop = SaxophonePads(rawValue: 1 << 7)
    static let lPinkyBottom = SaxophonePads(rawValue: 1 << 8)

    static let c4: SaxophonePads = [.rIndex, .rMiddle, .rRing,  .lIndex, .lMiddle, .lRing, .lPinkyBottom]
    static let d4: SaxophonePads = [.rIndex, .rMiddle, .rRing,  .lIndex, .lMiddle, .lRing]
    static let e4: SaxophonePads = [.rIndex, .rMiddle, .rRing,  .lIndex, .lMiddle]
    static let f4: SaxophonePads = [.rIndex, .rMiddle, .rRing,  .lIndex]
    static let g4: SaxophonePads = [.rIndex, .rMiddle, .rRing]
    static let a4: SaxophonePads = [.rIndex, .rMiddle]
    static let b4: SaxophonePads = [.rIndex]
    static let c5: SaxophonePads = [.rMiddle]

    var name: String {
        switch self {
        case .c4: "C4"
        case .d4: "D4"
        case .e4: "E4"
        case .f4: "F4"
        case .g4: "G4"
        case .a4: "A4"
        case .b4: "B4"
        case .c5: "C5"

        default: "to advanced for me"
        }
    }

    var node: UInt8 {
        switch self {
        case .c4: 60
        case .d4: 62
        case .e4: 64
        case .f4: 65
        case .g4: 67
        case .a4: 69
        case .b4: 71
        case .c5: 71

        default : 60
        }
    }

    var data: Data {
        Data([node])
    }


}
