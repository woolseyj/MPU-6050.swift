/*
   MPU-6050.swift

   Copyright (c) 2017 Umberto Raimondi
   Modified by John Woolsey
   Licensed under the MIT license, as follows:

   Permission is hereby granted, free of charge, to any person obtaining a copy
   of this software and associated documentation files (the "Software"), to deal
   in the Software without restriction, including without limitation the rights
   to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
   copies of the Software, and to permit persons to whom the Software is
   furnished to do so, subject to the following conditions:

   The above copyright notice and this permission notice shall be included in all
   copies or substantial portions of the Software.

   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
   OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
   SOFTWARE.)
*/

import SwiftyGPIO  // Comment this when not using the package manager


public class MPU6050 {
    // Registers
    public let XA_OFFS_H: UInt8 = 0x06
    public let YA_OFFS_H: UInt8 = 0x08
    public let ZA_OFFS_H: UInt8 = 0x0A
    public let XG_OFFS_USRH: UInt8 = 0x13
    public let YG_OFFS_USRH: UInt8 = 0x15
    public let ZG_OFFS_USRH: UInt8 = 0x17
    public let GYRO_CONFIG: UInt8 = 0x1B
    public let ACCEL_CONFIG: UInt8 = 0x1C
    public let ACCEL_XOUT_H: UInt8 = 0x3B
    public let ACCEL_YOUT_H: UInt8 = 0x3D
    public let ACCEL_ZOUT_H: UInt8 = 0x3F
    public let TEMP_OUT_H: UInt8 = 0x41
    public let GYRO_XOUT_H: UInt8 = 0x43
    public let GYRO_YOUT_H: UInt8 = 0x45
    public let GYRO_ZOUT_H: UInt8 = 0x47
    public let PWR_MGMT_1: UInt8 = 0x6B

    public let i2c: I2CInterface
    public let address: Int

    // Initializer
    public init(_ i2c: I2CInterface, address: Int = 0x68) {
       self.i2c = i2c
       self.address = address
    }

    // Read 2's compliment word
    func readWord2c(register: UInt8) -> Int {
        var rv = UInt16(i2c.readByte(address, command: register)) << 8
        rv |= UInt16(i2c.readByte(address, command: register + 1))
        if (rv >= 0x8000) {
            return -(Int((UInt16.max - rv) + 1))
        } else {
            return Int(rv)
        }
    }

    // Write 2's compliment word
    func writeWord2c(register: UInt8, value: Int) {
        let raw: UInt16
        if (value < 0) {
            raw = UInt16.max - UInt16(-value) + 1
        } else {
            raw = UInt16(value)
        }
        let high = UInt8(raw >> 8)
        let low = UInt8(raw & 0xFF)
        i2c.writeByte(address, command: register, value: high)
        i2c.writeByte(address, command: register + 1, value: low)
    }

    // X accelerometer sensor data
    public var AccelX: Int {
        return readWord2c(register: ACCEL_XOUT_H)
    }

    // Y accelerometer sensor data
    public var AccelY: Int {
        return readWord2c(register: ACCEL_YOUT_H)
    }

    // Z accelerometer sensor data
    public var AccelZ: Int {
        return readWord2c(register: ACCEL_ZOUT_H)
    }

    // Temperature sensor data from -40 to +85 degrees Celsius
    public var Temp: Float {
        var rv = UInt16(i2c.readByte(address, command: TEMP_OUT_H)) << 8
        rv |= UInt16(i2c.readByte(address, command: TEMP_OUT_H + 1))
        return Float(Int16(bitPattern:rv)) / 340 + 36.53
    }

    // Enables or disables the device
    public func enable(_ on: Bool) {
        // PWR_MGMT_1 register, SLEEP bit, CLKSEL[2:0] bits
        i2c.writeByte(address, command: PWR_MGMT_1, value: UInt8(on ? 0x01 : 0x40))
    }

    // Resets the device
    public func reset() {
        // PWR_MGMT_1 register, DEVICE_RESET bit
        let tmp = i2c.readByte(address, command: PWR_MGMT_1)
        i2c.writeByte(address, command: PWR_MGMT_1, value: UInt8(0x80))
        i2c.writeByte(address, command: PWR_MGMT_1, value: tmp)
    }

    // X gyroscope sensor data
    public var GyroX: Int {
        return readWord2c(register: GYRO_XOUT_H)
    }

    // Y gyroscope sensor data
    public var GyroY: Int {
        return readWord2c(register: GYRO_YOUT_H)
    }

    // Z gyroscope sensor data
    public var GyroZ: Int {
        return readWord2c(register: GYRO_ZOUT_H)
    }

    // X accelerometer sensor offset
    public var AccelOffsetX: Int {
        get {
            return readWord2c(register: XA_OFFS_H)
        }
        set(newOffset) {
            writeWord2c(register: XA_OFFS_H, value: newOffset)
        }
    }

    // Y accelerometer sensor offset
    public var AccelOffsetY: Int {
        get {
            return readWord2c(register: YA_OFFS_H)
        }
        set(newOffset) {
            writeWord2c(register: YA_OFFS_H, value: newOffset)
        }
    }

    // Z accelerometer sensor offset
    public var AccelOffsetZ: Int {
        get {
            return readWord2c(register: ZA_OFFS_H)
        }
        set(newOffset) {
            writeWord2c(register: ZA_OFFS_H, value: newOffset)
        }
    }

    // X gyroscope sensor offset
    public var GyroOffsetX: Int {
        get {
            return readWord2c(register: XG_OFFS_USRH)
        }
        set(newOffset) {
            writeWord2c(register: XG_OFFS_USRH, value: newOffset)
        }
    }

    // Y gyroscope sensor offset
    public var GyroOffsetY: Int {
        get {
            return readWord2c(register: YG_OFFS_USRH)
        }
        set(newOffset) {
            writeWord2c(register: YG_OFFS_USRH, value: newOffset)
        }
    }

    // Z gyroscope sensor offset
    public var GyroOffsetZ: Int {
        get {
            return readWord2c(register: ZG_OFFS_USRH)
        }
        set(newOffset) {
            writeWord2c(register: ZG_OFFS_USRH, value: newOffset)
        }
    }

    // Get all sensor readings
    public func getAll() -> (AccelX: Int, AccelY: Int, AccelZ: Int, Temp: Float, GyroX: Int, GyroY:Int , GyroZ: Int) {
        return (self.AccelX,self.AccelY,self.AccelZ,self.Temp,self.GyroX,self.GyroY,self.GyroZ)
    }
}
