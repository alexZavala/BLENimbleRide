//
//  BLEViewController.swift
//  BluetoothNimbleRide
//
//  Created by AlexZavala on 4/2/17.
//  Copyright © 2017 Alexander Zavala. All rights reserved.
//

import UIKit
import CoreBluetooth

//Device UUID from iPhone app: 30EBAF1A-42F5-4CBC-B51A-1A49FB699413
//Device SERVICE from iPhone app: 0xFFE0
//Device CHARACTERISTIC from iPhone app: 0xFFE1
//Advertiement Maufacturer data: <484de0e5 cfce8417>


//SERVICES
//Exposes manufacturer info  about the device.
let DEVICE_INFO_UUID = "0000FFE0-0000-1000-8000-00805F9B34FB" //0xFFE0

//CHARACTERISTICS
let DEVICE_MANUFACTURER_UUID = "0000FFE1-0000-1000-8000-00805F9B34FB" //0xFFE1

// Conform to CBCentralManagerDelegate, CBPeripheralDelegate protocols
class BLEViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    // Core Bluetooth properties
    var centralManager:CBCentralManager!    //responsible for scanning, discovering and connecting peripherals.
    var SJOne:CBPeripheral?                 //B/c we're only using one peripheral.
    var cadenceCharecteristic: CBCharacteristic?

    @IBOutlet weak var statusLabel: UILabel!
    
    var keepScanning = false

    //let bleDeviceName = "BLE_SHD"
    let bleDeviceName = "HMSoft"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Creates the CBCentralManager object. Assignes the viewController as its delegate. Tells it to dispatch central role events using the main queue.
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
            //centralManager.scanForPeripherals(withServices: nil, options: nil)

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

        //nil means we are looking for any peripheral with any service. 
        //Pass an array of CBServices in the first parameter to scan for only those peripherals that support those Services with which you wish to interact.
        //Will call didDiscoverPeripheral if peripheral is on and found.
        centralManager.scanForPeripherals(withServices: nil, options: nil)

    }
    
    //if peripheral is on, CBCentrealManager will discover it and call this method.
    //This is where you check for the data. Where the developer inspects to see if we found what we are looking for.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("centralManager Discovered Peripheral. CBAdvertisementDataLocalNameKey is \"\(CBAdvertisementDataLocalNameKey)\"")
        
        // Retrieve the peripheral name from the advertisement data using the "kCBAdvDataLocalName" key
        if let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            print("PERIPHERAL NAME: \(peripheralName)")
            print("PERIPHERAL UUID: \(peripheral.identifier.uuidString)")
            statusLabel.text = "Found BLE DEVICE"
            
            if peripheralName == bleDeviceName {
                print("FOUND DEVICE! ADDING \(peripheralName) NOW!!!")
                //// to save power, stop scanning for other devices
                //keepScanning = false
                //disconnectButton.isEnabled = true
                centralManager?.stopScan()
                
                // save a reference to the sensor tag
                SJOne = peripheral
                SJOne!.delegate = self //set view controller to be the delegate.
                
                // Request a connection to the peripheral. This enables us to discover the services available on the device.
                centralManager.connect(SJOne!, options: nil)
            }
        }
    }
    
    //Called when connected to the peripheral from centralManager.connect(SJOne!, option: nil)
    //If called, we can discover the services that the CBPeripheral object supports.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("**** SUCCESSFULLY CONNECTED TO BLE DEVICE!!!")
        statusLabel.text = "Connected to BLE device"
        
        SJOne?.delegate = self
        peripheral.discoverServices(nil) //Passing nil discovers all of the Services that the device supports,though you can supply an array of Service UUIDs that the device exposes
    }
    
    //Called if problem during the connection occurs.
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("**** CONNECTION TO BLE DEVICE FAILED!!!")
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("**** DISCONNECTED FROM BLE DEVICE!!!")

        if error != nil {
            print("****** DISCONNECTION DETAILS: \(error!.localizedDescription)")
        }
        SJOne = nil
    }
    
    
    //MARK: - CBPeripheralDelegate methods

    // When the specified services are discovered, the peripheral calls the peripheral:didDiscoverServices: method of its delegate object.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if error != nil {
            print("ERROR DISCOVERING SERVICES: \(String(describing: error?.localizedDescription))")
            return
        }

        if let services = peripheral.services {
            for service: CBService in services {
                print("Discovered service \(service.uuid)")
                // If discover the characteristics for those services.
                if (service.uuid == CBUUID(string: DEVICE_INFO_UUID)){
                    peripheral.discoverCharacteristics(nil, for: service)
                    statusLabel.text = "FOUND SERVICE"
                }
            }
        }
    }
    
    //Gets invoked when the BLE device finds a service.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?){
        
        if error != nil {
            print("ERROR DISCOVERING CHARACTERISTICS: \(String(describing: error?.localizedDescription))")
            return
        }
        
        if let characteristics = service.characteristics {
            //var enableValue:UInt8 = 1
            //let enableBytes = Data(bytes: UnsafePointer<Int8>(&enableValue), count: sizeof(Int8))
            
            for characteristic in characteristics {
                print("Discovered characteristic \(characteristic.uuid)")
                if characteristic.uuid == CBUUID(string: DEVICE_MANUFACTURER_UUID) {
                    statusLabel.text = "FOUND CHARACTERISTIC"
                    print("Found a device manufacturer characterisitc")
                    
                    
                    cadenceCharecteristic = characteristic
                    //SJOne?.setNotifyValue(true, for: characteristic)
                    SJOne?.readValue(for: characteristic)
                    //print("Discovered Characteristic \(characteristic.uuid)")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {

        
        if error != nil {
            print("ERROR ON UPDATING VALUE FOR CHARACTERISTIC: \(characteristic) - \(String(describing: error?.localizedDescription))")
            return
        }

        if characteristic.uuid == CBUUID(string: DEVICE_MANUFACTURER_UUID){
            print("test: \(characteristic)")
            
            //getManufacturerName(characteristic)
  
        }
    }

    //    // MARK: - TI Sensor Tag Utility Methods
    func getManufacturerName(_ characteristic: CBCharacteristic) {
        let manufacturerName = String(data: characteristic.value!, encoding: String.Encoding.utf8)
        _ = "Manufacturer: \(String(describing: manufacturerName))"
        return
    }
}
