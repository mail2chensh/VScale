//
//  ViewController.swift
//  VScale
//
//  Created by dev on 2017/2/16.
//  Copyright © 2017年 Chensh. All rights reserved.
//

import UIKit
import CoreBluetooth


class ViewController: UIViewController, BluetoothToolsDelegate, CBPeripheralDelegate {

    @IBOutlet weak var tipsLabel: UILabel!
    @IBOutlet weak var weightLabel: UILabel!
    
    
    var aPeripheral: CBPeripheral? = nil
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //
        UIApplication.shared.setStatusBarStyle(.lightContent, animated: true)
        
        //
        UIApplication.shared.applicationSupportsShakeToEdit = true
        self.becomeFirstResponder()
        
        //
        BluetoothTools.shared.addDelegate(delegate: self, peripheralName: "VScale")
        
        //
        NotificationCenter.default.addObserver(self, selector: #selector(stopScan), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
    }
    
    deinit {
        //
        BluetoothTools.shared.removeDelegate(delegate: self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.stopScan()
    }

    // 摇一摇
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        // 如果已经在搜索状态，则返回
        if BluetoothTools.shared.isScaning {
            return
        }
        
        //
        self.weightLabel.text = "0"
        self.tipsLabel.text = "请上称"
        
        // 蓝牙开启扫描
        BluetoothTools.shared.centralManager.scanForPeripherals(withServices: nil, options: nil)
        BluetoothTools.shared.isScaning = true
    }
    
    
    // 停止扫描
    func stopScan() {
        
        print("================ 关闭蓝牙搜索")
        
        if self.aPeripheral != nil {
            BluetoothTools.shared.centralManager.cancelPeripheralConnection(self.aPeripheral!)
            self.aPeripheral?.delegate = nil
        }
        BluetoothTools.shared.centralManager.stopScan()
        BluetoothTools.shared.isScaning = false
        
        self.tipsLabel.text = "摇一摇开始称重"
        self.weightLabel.text = "0"
    }
    
    
    
    // ==================================================
    // Delegate
    // ==================================================
    
    //
    func centralManagerDidUpdateState() {
        switch BluetoothTools.shared.centralManager.state {
        case .poweredOff:
            self.tipsLabel.text = "请打开蓝牙"
        case .poweredOn:
            self.tipsLabel.text = "摇一摇开始称重"
        default:
            break
        }
    }
    
    
    // 发现外设
    func centralManagerDidDiscoverPeripheral(peripheral: CBPeripheral) {
        print(peripheral)
        //
        aPeripheral = peripheral
        aPeripheral?.delegate = self
        //
        BluetoothTools.shared.centralManager.connect(aPeripheral!, options: nil)
        
        //
        self.tipsLabel.text = "请上称"
    }
    
    
    // 连接外设
    func centralManagerDidConnectPeripheral(peripheral: CBPeripheral) {
//        peripheral.discoverServices(nil)
        peripheral.discoverServices([CBUUID.init(string: "F433BD80-75B8-11E2-97D9-0002A5D5C51B")])
    }
    
    func centralManagerDidDisconnectPeripheral(peripheral: CBPeripheral, error: Error?) {
        self.stopScan()
    }
    
    func centralManagerDidFailConnectPeripheral(peripheral: CBPeripheral, error: Error?) {
        self.stopScan()
    }
    
    
    // ==================================================
    // Delegate
    // ==================================================
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        for service in peripheral.services! {
            print("service: \(service.uuid)")
            peripheral.discoverCharacteristics([CBUUID.init(string: "1A2EA400-75B9-11E2-BE05-0002A5D5C51B")], for: service)
//            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        for characteristic in service.characteristics! {
            print("service: \(service.uuid), chara: \(characteristic.uuid)")
            if characteristic.uuid.uuidString == "1A2EA400-75B9-11E2-BE05-0002A5D5C51B" {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
        print("chara: \(characteristic.uuid), value: \(characteristic.value?.description)")
        if let value = characteristic.value {

            let array = value.uint8Array()
            if array.count > 5 {
                let weight: Int = (Int(array[4]) << 8) + Int(array[5])
                print(weight)
                self.weightLabel.text = String.init(format: "%.1f", CGFloat(weight) / 10.0)
                self.tipsLabel.text = "获取数据成功"
            }
        }
        
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        self.tipsLabel.text = "正在获取数据"
    }
    

}



extension Data {
    
    func uint8Array() -> [UInt8] {
        let array = self.withUnsafeBytes {
            [UInt8](UnsafeBufferPointer(start: $0, count: self.count))
        }
        return array
    }
}

