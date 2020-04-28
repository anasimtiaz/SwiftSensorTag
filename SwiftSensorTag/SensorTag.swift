//
//  SensorTag.swift
//  SwiftSensorTag
//
//  Created by Anas Imtiaz on 13/11/2015.
//  Copyright © 2015 Anas Imtiaz. All rights reserved.
//

import Foundation
import CoreBluetooth


let deviceName = "SensorTag"

// Service UUIDs
let IRTemperatureServiceUUID = CBUUID(string: "F000AA00-0451-4000-B000-000000000000")
let HumidityServiceUUID      = CBUUID(string: "F000AA20-0451-4000-B000-000000000000")
let BarometerServiceUUID     = CBUUID(string: "F000AA40-0451-4000-B000-000000000000")
let LuxometerServiceUUID     = CBUUID(string: "F000AA70-0451-4000-B000-000000000000")
let MovementServiceUUID      = CBUUID(string: "F000AA80-0451-4000-B000-000000000000")

// Characteristic UUIDs
let IRTemperatureDataUUID   = CBUUID(string: "F000AA01-0451-4000-B000-000000000000")
let IRTemperatureConfigUUID = CBUUID(string: "F000AA02-0451-4000-B000-000000000000")
let HumidityDataUUID        = CBUUID(string: "F000AA21-0451-4000-B000-000000000000")
let HumidityConfigUUID      = CBUUID(string: "F000AA22-0451-4000-B000-000000000000")
let BarometerDataUUID       = CBUUID(string: "F000AA41-0451-4000-B000-000000000000")
let BarometerConfigUUID     = CBUUID(string: "F000AA42-0451-4000-B000-000000000000")
let LuxometerDataUUID       = CBUUID(string: "F000AA71-0451-4000-B000-000000000000")
let LuxometerConfigUUID     = CBUUID(string: "F000AA72-0451-4000-B000-000000000000")
let MovementDataUUID        = CBUUID(string: "F000AA81-0451-4000-B000-000000000000")
let MovementConfigUUID      = CBUUID(string: "F000AA82-0451-4000-B000-000000000000")


class SensorTag {
    
    // Check name of device from advertisement data
    class func sensorTagFound (advertisementData: [String : Any]!) -> Bool {
        if (advertisementData["kCBAdvDataLocalName"]) != nil {
            let advData = advertisementData["kCBAdvDataLocalName"] as! String
            return(advData.range(of: deviceName) != nil)
        }
        return false
    }
    
    
    // Check if the service has a valid UUID
    class func validService (service : CBService) -> Bool {
        if service.uuid == IRTemperatureServiceUUID || service.uuid == MovementServiceUUID ||
            service.uuid == HumidityServiceUUID || service.uuid == LuxometerServiceUUID ||
            service.uuid == BarometerServiceUUID  {
                return true
        }
        else {
            return false
        }
    }
    
    
    // Check if the characteristic has a valid data UUID
    class func validDataCharacteristic (characteristic : CBCharacteristic) -> Bool {
        if characteristic.uuid == IRTemperatureDataUUID || characteristic.uuid == MovementDataUUID ||
            characteristic.uuid == HumidityDataUUID || characteristic.uuid == LuxometerDataUUID ||
            characteristic.uuid == BarometerDataUUID {
                return true
        }
        else {
            return false
        }
    }
    
    
    // Check if the characteristic has a valid config UUID
    class func validConfigCharacteristic (characteristic : CBCharacteristic) -> Bool {
        if characteristic.uuid == IRTemperatureConfigUUID || characteristic.uuid == MovementConfigUUID ||
            characteristic.uuid == HumidityConfigUUID || characteristic.uuid == LuxometerConfigUUID ||
            characteristic.uuid == BarometerConfigUUID {
                return true
        }
        else {
            return false
        }
    }
    
    
    // Get labels of all sensors
    class func getSensorLabels () -> [String] {
        let sensorLabels : [String] = [
            "Ambient Temperature",
            "Object Temperature",
            "Accelerometer X",
            "Accelerometer Y",
            "Accelerometer Z",
            "Relative Humidity",
            "Magnetometer X",
            "Magnetometer Y",
            "Magnetometer Z",
            "Gyroscope X",
            "Gyroscope Y",
            "Gyroscope Z"
        ]
        return sensorLabels
    }
    
    
    
    // Process the values from sensor
    
    
    // Convert NSData to array of bytes
    class func dataToSignedBytes16(value : NSData, count: Int) -> [Int16] {
        var array = [Int16](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<Int16>.size)
        return array
    }
    
    class func dataToUnsignedBytes16(value : NSData, count: Int) -> [UInt16] {
        var array = [UInt16](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<UInt16>.size)
        return array
    }
    
    class func dataToSignedBytes8(value : NSData, count: Int) -> [Int8] {
        var array = [Int8](repeating: 0, count: count)
        value.getBytes(&array, length:count * MemoryLayout<Int8>.size)
        return array
    }
    
    // Get ambient temperature value
    class func getTemperatureData(value : NSData) -> [Double] {
        // The TMP007 IR Temperature sensor is not fitted on SensorTags produced after June 2017.
        let dataFromSensor = dataToSignedBytes16(value: value, count: 2)
        let ambientTemperature = Double(dataFromSensor[1])/128
        let Vobj2 = Double(dataFromSensor[0]) * 0.00000015625
        
        let Tdie2 = ambientTemperature + 273.15
        let Tref  = 298.15
        
        let S0 = 6.4e-14
        let a1 = 1.75E-3
        let a2 = -1.678E-5
        let b0 = -2.94E-5
        let b1 = -5.7E-7
        let b2 = 4.63E-9
        let c2 = 13.4
        
        let S = S0*(1+a1*(Tdie2 - Tref)+a2*pow((Tdie2 - Tref),2))
        let Vos = b0 + b1*(Tdie2 - Tref) + b2*pow((Tdie2 - Tref),2)
        let fObj = (Vobj2 - Vos) + c2*pow((Vobj2 - Vos),2)
        let tObj = pow(pow(Tdie2,4) + (fObj/S),0.25)
        
        let objectTemperature = (tObj - 273.15)
        
        return [objectTemperature, ambientTemperature]
    }
    
    // Get Accelerometer values
    class func getMovementData(value: NSData) -> [Double] {
        let dataFromSensor = dataToSignedBytes16(value: value, count: 9)
        let gx = Double(dataFromSensor[0]) * 500.0 / 65536.0
        let gy = Double(dataFromSensor[1]) * 500.0 / 65536.0
        let gz = Double(dataFromSensor[2]) * 500.0 / 65536.0
        let range = 2.0
        let ax = Double(dataFromSensor[3]) * range / 32768.0
        let ay = Double(dataFromSensor[4]) * range / 32768.0
        let az = Double(dataFromSensor[5]) * range / 32768.0
        let mx = Double(dataFromSensor[6])
        let my = Double(dataFromSensor[7])
        let mz = Double(dataFromSensor[8])
        return [gx, gy, gz, ax, ay, az, mx, my, mz]
    }
    
    // Get Relative Humidity
    class func getRelativeHumidity(value: NSData) -> Double {
        let dataFromSensor = dataToUnsignedBytes16(value: value, count: 2)
        let humidity = -6 + 125/65536 * Double(dataFromSensor[1])
        return humidity
    }
}
