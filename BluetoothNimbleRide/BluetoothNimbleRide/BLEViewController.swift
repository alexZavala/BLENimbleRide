//
//  BLEViewController.swift
//  BluetoothNimbleRide
//
//  Created by AlexZavala on 4/2/17.
//  Copyright © 2017 Alexander Zavala. All rights reserved.
//

import UIKit
import CoreBluetooth

//SERVICES
//Exposes manufacturer info  about the device.
let DEVICE_INFO_UUID = "0000FFE0-0000-1000-8000-00805F9B34FB"

//CHARACTERISTICS
let DEVICE_MANUFACTURER_UUID = "0000FFE1-0000-1000-8000-00805F9B34FB"

// Conform to CBCentralManagerDelegate, CBPeripheralDelegate protocols
class BLEViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Core Bluetooth properties
    var centralManager:CBCentralManager!//responsible for scanning, discovering and connecting peripherals.
    var sensorTag:CBPeripheral?//B/c we're only using one peripheral.

    @IBOutlet weak var statusLabel: UILabel!
    
    var keepScanning = false

    let sensorTagName = "BLE_SHD"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        // configure initial UI
        statusLabel.text = "Searching"
        //centralManager.scanForPeripherals(withServices: nil, options: nil)//Might need to use here instead of in didUpdateState function.
    }

    
    // MARK: - CBCentralManagerDelegate methods
    
    // Invoked when the central manager’s state is updated.
    //Once initialization, CBCentralManager calls this method.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOff {
            print("CoreBluetooth BLE hardware is powered off")
        }
        else if central.state == .poweredOn {
            print("CoreBluetooth BLE hardware is powered on and ready")
        }
        else if central.state == .unauthorized {
            print("CoreBluetooth BLE state is unauthorized")
        }
        else if central.state == .unknown {
            print("CoreBluetooth BLE state is unknown")
        }
        else if central.state == .unsupported {
            print("CoreBluetooth BLE hardware is unsupported on this platform")
        }

        centralManager.scanForPeripherals(withServices: nil, options: nil)

    }
    
    //if peripheral is on, CBCentrealManager will discover it and call this method.
    //This is where you check for the data. Where the developer inspects to see if we found what we are looking for.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("centralManager Discovered Peripheral. CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("NEXT PERIPHERAL NAME: \(peripheralName)")
            print("NEXT PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            statusLabel.text = "Found BLE DEVICE"
            
            if peripheralName == sensorTagName {
                print("SENSOR TAG FOUND! ADDING \(peripheralName) NOW!!!")
                //// to save power, stop scanning for other devices
                //keepScanning = false
                //disconnectButton.isEnabled = true
                centralManager?.stopScan()
                
                // save a reference to the sensor tag
                sensorTag = peripheral
                sensorTag!.delegate = self //set delegate to be the view controller.
                
                // Request a connection to the peripheral
                centralManager.connect(sensorTag!, options: nil)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO SENSOR TAG!!!")
        
        sensorTag?.delegate = self
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("**** CONNECTION TO SENSOR TAG FAILED!!!")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("**** DISCONNECTED FROM SENSOR TAG!!!")

        if error != nil {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        sensorTag = nil
    }
    
    
    //MARK: - CBPeripheralDelegate methods

    // When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if error != nil {
            print("ERROR DISCOVERING SERVICES: \(error?.localizedDescription)")
            return
        }

        if let services = peripheral.services {
            for service: CBService in services {
                print("Discovered service \(service.uuid)")
                // If discover the characteristics for those services.
                if (service.uuid == CBUUID(string: DEVICE_INFO_UUID)){
                    print("****SERVICE TEST****")
                    peripheral.discoverCharacteristics(nil, for: service)
                    statusLabel.text = "FOUND SERVICE"
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        
        if error != nil {
            print("ERROR DISCOVERING CHARACTERISTICS: \(error?.localizedDescription)")
            return
        }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                // Temperature Data Characteristic
                if characteristic.uuid == CBUUID(string: DEVICE_MANUFACTURER_UUID) {
                    statusLabel.text = "FOUND CHARACTERISTIC"
                    print("Found a device manufacturer characterisitc")
                    print("Discovered Characteristic \(characteristic.uuid)")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(error?.localizedDescription)")
            return
        }

        if characteristic.uuid == CBUUID(string: DEVICE_MANUFACTURER_UUID){
            getManufacturerName(characteristic)
  
        }
    }

    //    // MARK: - TI Sensor Tag Utility Methods
    func getManufacturerName(_ characteristic: CBCharacteristic) {
        let manufacturerName = String(data: characteristic.value!, encoding: String.Encoding.utf8)
        _ = "Manufacturer: \(manufacturerName)"
        return
    }
}
