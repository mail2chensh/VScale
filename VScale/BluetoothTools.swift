//
//  BluetoothManager.swift
//  BlueDemo
//
//  Created by dev on 2017/2/15.
//  Copyright © 2017年 Chensh. All rights reserved.
//

import UIKit
import CoreBluetooth

// 发现外设
let K_CENTRAL_MANAGER_DID_DISCOVER_PERIPHERAL = "K_CENTRAL_MANAGER_DID_DISCOVER_PERIPHERAL"
// 连接外设成功
let K_CENTRAL_MANAGER_DID_CONNECT_PERIPHERAL = "K_CENTRAL_MANAGER_DID_CONNECT_PERIPHERAL"
// 连接外设失败
let K_CENTRAL_MANAGER_DID_FAIL_CONNECT_PERIPHERAL = "K_CENTRAL_MANAGER_DID_FAIL_CONNECT_PERIPHERAL"
// 失去外设连接
let K_CENTRAL_MANAGER_DID_DISCONNECT_PERIPHERAL = "K_CENTRAL_MANAGER_DID_DISCONNECT_PERIPHERAL"


@objc protocol BluetoothToolsDelegate: NSObjectProtocol {
    
    //
    @objc optional func centralManagerDidUpdateState()
    
    //
    @objc optional func centralManagerDidDiscoverPeripheral(peripheral: CBPeripheral)
    
    //
    @objc optional func centralManagerDidConnectPeripheral(peripheral: CBPeripheral)
    //
    @objc optional func centralManagerDidFailConnectPeripheral(peripheral: CBPeripheral, error: Error?)
    //
    @objc optional func centralManagerDidDisconnectPeripheral(peripheral: CBPeripheral, error: Error?)
}



class BluetoothTools: NSObject, CBCentralManagerDelegate {

    private static var _instance: BluetoothTools? = nil
    static var shared: BluetoothTools {
        if _instance == nil {
            _instance = BluetoothTools.init()
        }
        return _instance!
    }
    
    var centralManager: CBCentralManager!
    var peripheralDataArray: NSMutableArray = NSMutableArray.init()
    var characteristicPropertiesDict: [[String : Any]] = []
    
    private var _delegateArray: [[String : Any]] = []
    var isScaning: Bool = false

    override init() {
        super.init()
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
        
        characteristicPropertiesDict = [["key" : CBCharacteristicProperties.broadcast, "name" : "广播"],
                                        ["key" : CBCharacteristicProperties.read, "name" : "可读"],
                                        ["key" : CBCharacteristicProperties.writeWithoutResponse, "name" : "无响应写"],
                                        ["key" : CBCharacteristicProperties.write, "name" : "可写"],
                                        ["key" : CBCharacteristicProperties.notify, "name" : "通知"],
                                        ["key" : CBCharacteristicProperties.indicate, "name" : "指示"],
                                        ["key" : CBCharacteristicProperties.authenticatedSignedWrites, "name" : "授权写"],
                                        ["key" : CBCharacteristicProperties.extendedProperties, "name" : "扩展"],
                                        ["key" : CBCharacteristicProperties.notifyEncryptionRequired, "name" : "通知加密"],
                                        ["key" : CBCharacteristicProperties.indicateEncryptionRequired, "name" : "指示加密"]]
    }
    
    
    
    func addDelegate(delegate: BluetoothToolsDelegate, peripheralName: String) {
        let dict: [String : Any] = ["name" : peripheralName, "delegate" : delegate]
        if !isDelegateExist(delegate: delegate) {
            _delegateArray.append(dict)
        }
    }
    
    func removeDelegate(delegate: BluetoothToolsDelegate) {
        for index in 0..<_delegateArray.count {
            let dict: [String: Any] = _delegateArray[index]
            if dict["delegate"] == delegate as! _OptionalNilComparisonType {
                _delegateArray.remove(at: index)
                break
            }
        }
    }
    
    private func isDelegateExist(delegate: BluetoothToolsDelegate) -> Bool {
        for item in _delegateArray {
            if item["delegate"] == delegate as! _OptionalNilComparisonType {
                return true
            }
        }
        return false
    }
    
    
    private func checkPeripheralNameSame(peripheral: CBPeripheral, dict: [String: Any]) -> Bool {
        let name = (dict["name"] as! String).lowercased()
        if var pName = peripheral.name {
            pName = pName.lowercased()
            if pName.hasPrefix(name) {
                return true
            }
        }
        return false
    }
    
    
    // 返回属性值对应的名称
    func characteristicPropertyString(_ properties: CBCharacteristicProperties) -> String {
        
        let array : NSMutableArray = NSMutableArray.init()
        
        for dict in self.characteristicPropertiesDict {
            let property = dict["key"] as! CBCharacteristicProperties
            if (properties.rawValue & property.rawValue) != 0 {
                array.add(dict["name"] as! String)
            }
        }
        
        let str = array.componentsJoined(by: ",")
        return str
    }

    
    
    // ==================================================
    // Delegate
    // ==================================================
    
    // 初始化后回调
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        self.isScaning = false
        
        switch central.state {
        case .unknown:
            print("CBCentralManager state:", "unknown")
            break
        case .resetting:
            print("CBCentralManager state:", "resetting")
            break
        case .unsupported:
            print("CBCentralManager state:", "unsupported")
            break
        case .unauthorized:
            print("CBCentralManager state:", "unauthorized")
            break
        case .poweredOff:
            print("CBCentralManager state:", "poweredOff")
            break
        case .poweredOn:
            print("CBCentralManager state:", "poweredOn")
            
            // 蓝牙开启扫描
            // services： 通过服务筛选
            // dict: 通过条件筛选
            //centralManager.scanForPeripherals(withServices: nil, options: nil)
            //self.isScaning = true
            
            break
        }
        
        for index in 0..<_delegateArray.count {
            let dict = _delegateArray[index]
            let delegate = dict["delegate"] as? BluetoothToolsDelegate
            if delegate != nil && (delegate?.responds(to: #selector(BluetoothToolsDelegate.centralManagerDidUpdateState)))! {
                delegate?.centralManagerDidUpdateState!()
            }
        }
        
    }
    
    
    // 搜索外围设备
    // advertisementData： 外设携带的数据
    // rssi: 外设的蓝牙信号强度
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
//        print(#function, #line)
//        print(central)
//        print(peripheral)
//        print(advertisementData)
//        print(RSSI)
        
        /*
         
         * peripheral:
         <CBPeripheral: 0x15fd951b0, identifier = 2DE9CDCF-64B7-C7CA-302F-13EF73A61CDB, name = Chensh的MacBook Pro, state = disconnected>
         
         * advertisementData:
         ["kCBAdvDataIsConnectable": 1, "kCBAdvDataLocalName": MI, "kCBAdvDataManufacturerData": <5701002c 9b349956 7afbaf5a 21000655 07c61200 880f107e c4c4>, "kCBAdvDataServiceUUIDs": <__NSArrayM 0x14f542de0>(
         FEE0,
         FEE7
         )
         , "kCBAdvDataServiceData": {
         FEE0 = <0b000000>;
         }]
         
         */
        
        // 将注册的查询外设进行通知
        for index in 0..<_delegateArray.count {
            let dict = _delegateArray[index]
            if self.checkPeripheralNameSame(peripheral: peripheral, dict: dict) {
                
                print(#function, #line)
                print(central)
                print(peripheral)
                print(advertisementData)
                print(RSSI)
                
                let delegate = dict["delegate"] as? BluetoothToolsDelegate
                if delegate != nil && (delegate?.responds(to: #selector(BluetoothToolsDelegate.centralManagerDidDiscoverPeripheral(peripheral:))))! {
                    delegate?.centralManagerDidDiscoverPeripheral!(peripheral: peripheral)
                }
            }
        }
        
//        let uuidString = peripheral.identifier.uuidString
//        let aDict: [String : Any] = ["peripheral" : peripheral,
//                                     "advertisementData" : advertisementData,
//                                     "rssi" : RSSI]
//        
//        // 判断是否已经存在列表里
//        var exist: Bool = false
//        for index in 0..<self.peripheralDataArray.count {
//            let dict: [String : Any] = self.peripheralDataArray.object(at: index) as! [String : Any]
//            let pItem: CBPeripheral = dict["peripheral"] as! CBPeripheral
//            if pItem.identifier.uuidString == uuidString {
//                exist = true
//                self.peripheralDataArray.replaceObject(at: index, with: aDict)
//                break
//            }
//        }
//        if !exist {
//            self.peripheralDataArray.add(aDict)
//        }
//        
//        // 通知发现外设
//        NotificationCenter.default.post(name: NSNotification.Name.init(K_CENTRAL_MANAGER_DID_DISCOVER_PERIPHERAL), object: nil)
        
    }
    
    
    // 连接外设成功
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        for index in 0..<_delegateArray.count {
            let dict = _delegateArray[index]
            if self.checkPeripheralNameSame(peripheral: peripheral, dict: dict) {
                print("========== 连接外设成功： \(peripheral.name)")
                    
                let delegate = dict["delegate"] as? BluetoothToolsDelegate
                if delegate != nil && (delegate?.responds(to: #selector(BluetoothToolsDelegate.centralManagerDidConnectPeripheral(peripheral:))))! {
                    delegate?.centralManagerDidConnectPeripheral!(peripheral: peripheral)
                }
            }
        }
    }
    
    // 连接外设失败
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {

        for index in 0..<_delegateArray.count {
            let dict = _delegateArray[index]
            if self.checkPeripheralNameSame(peripheral: peripheral, dict: dict) {
                print("========== 连接外设失败： \(peripheral.name), \(error)")
                
                let delegate = dict["delegate"] as? BluetoothToolsDelegate
                if delegate != nil && (delegate?.responds(to: #selector(BluetoothToolsDelegate.centralManagerDidFailConnectPeripheral(peripheral:error:))))! {
                    delegate?.centralManagerDidFailConnectPeripheral!(peripheral: peripheral, error: error)
                }
            }
        }
    }
    
    // 丢失连接
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        for index in 0..<_delegateArray.count {
            let dict = _delegateArray[index]
            if self.checkPeripheralNameSame(peripheral: peripheral, dict: dict) {
                print("========== 丢失连接： \(peripheral.name), \(error)")
                
                let delegate = dict["delegate"] as? BluetoothToolsDelegate
                if delegate != nil && (delegate?.responds(to: #selector(BluetoothToolsDelegate.centralManagerDidDisconnectPeripheral(peripheral:error:))))! {
                    delegate?.centralManagerDidDisconnectPeripheral!(peripheral: peripheral, error: error)
                }
            }
        }
    }

    

    
    
}
