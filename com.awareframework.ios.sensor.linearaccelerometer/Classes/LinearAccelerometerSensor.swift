//
//  LinearAccelerometerSensor.swift
//  com.aware.ios.sensor.linearaccelerometer
//
//  Created by Yuuki Nishiyama on 2018/10/31.
//

import UIKit
import CoreMotion
import SwiftyJSON
import com_awareframework_ios_sensor_core

extension Notification.Name{
    public static let actionAwareLinearAccelerometer      = Notification.Name(LinearAccelerometerSensor.ACTION_AWARE_LINEAR_ACCELEROMETER)
    public static let actionAwareLinearAccelerometerStart = Notification.Name(LinearAccelerometerSensor.ACTION_AWARE_LINEAR_ACCELEROMETER_START)
    public static let actionAwareLinearAccelerometerStop  = Notification.Name(LinearAccelerometerSensor.ACTION_AWARE_LINEAR_ACCELEROMETER_STOP)
    public static let actionAwareLinearAccelerometerSync  = Notification.Name(LinearAccelerometerSensor.ACTION_AWARE_LINEAR_ACCELEROMETER_SYNC)
    public static let actionAwareLinearAccelerometerSetLabel = Notification.Name(LinearAccelerometerSensor.ACTION_AWARE_LINEAR_ACCELEROMETER_SET_LABEL)
}

extension LinearAccelerometerSensor{
    public static let TAG = "AWARE::LinearAcc"
    
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER = "ACTION_AWARE_LINEAR_ACCELEROMETER"
    
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER_START = "com.awareframework.android.sensor.linearaccelerometer.SENSOR_START"
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER_STOP = "com.awareframework.android.sensor.linearaccelerometer.SENSOR_STOP"
    
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER_SET_LABEL = "com.awareframework.android.sensor.linearaccelerometer.ACTION_AWARE_LINEAR_ACCELEROMETER_SET_LABEL"
    public static let EXTRA_LABEL = "label"
    
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER_SYNC = "com.awareframework.android.sensor.linearaccelerometer.SENSOR_SYNC"
}

public protocol LinearAccelerometerObserver {
    func onDataChanged(data:LinearAccelerometerData)
}

public class LinearAccelerometerSensor: AwareSensor {
    var CONFIG = LinearAccelerometerSensor.Config()
    var motion = CMMotionManager()
    var LAST_DATA:CMDeviceMotion?
    var LAST_TS:Double   = 0.0
    var LAST_SAVE:Double = 0.0
    public var dataBuffer = Array<LinearAccelerometerData>()
    
    public class Config:SensorConfig{
        /**
         * For real-time observation of the sensor data collection.
         */
        public var sensorObserver: LinearAccelerometerObserver? = nil
        
        /**
         * Linear accelerometer interval in hertz per second: e.g.
         *
         * 0 - fastest
         * 1 - sample per second
         * 5 - sample per second
         * 20 - sample per second
         */
        public var frequency: Int = 5
        
        /**
         * Period to save data in minutes. (optional)
         */
        public var period: Double = 1
        
        /**
         * Linear accelerometer threshold (float).  Do not record consecutive points if
         * change in value is less than the set value.
         */
        public var threshold: Double = 0.0
        
        public override init(){}
        public init(_ json:JSON){
            
        }
        
        public func apply(closure: (_ config: LinearAccelerometerSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }
    
    override convenience init(){
        self.init(Config())
    }
    
    public init(_ config:LinearAccelerometerSensor.Config){
        super.init()
        self.CONFIG = config
        self.initializeDbEngine(config: config)
        if config.debug{ print(LinearAccelerometerSensor.TAG, "Linear Accelerometer is created.") }
    }
    
    public override func start() {
        if self.motion.isDeviceMotionAvailable && !self.motion.isDeviceMotionActive {
            self.motion.deviceMotionUpdateInterval = 1.0/Double(self.CONFIG.frequency)
            self.motion.startDeviceMotionUpdates(to: .main) { (deviceMotionData, error) in
                if let dmData = deviceMotionData {
                    let x = dmData.userAcceleration.x
                    let y = dmData.userAcceleration.y
                    let z = dmData.userAcceleration.z
                    if let lastData = self.LAST_DATA {
                        if self.CONFIG.threshold > 0 &&
                            abs(x - lastData.userAcceleration.x) < self.CONFIG.threshold &&
                            abs(y - lastData.userAcceleration.y) < self.CONFIG.threshold &&
                            abs(z - lastData.userAcceleration.z) < self.CONFIG.threshold {
                            return
                        }
                    }
                    
                    self.LAST_DATA = dmData
                    
                    let currentTime:Double = Date().timeIntervalSince1970
                    self.LAST_TS = currentTime
                    
                    let data = LinearAccelerometerData()
                    data.timestamp = Int64(currentTime*1000)
                    data.x = x
                    data.y = y
                    data.z = z
                    data.eventTimestamp = Int64(dmData.timestamp*1000)
                    
                    if let observer = self.CONFIG.sensorObserver {
                        observer.onDataChanged(data: data)
                    }
                    
                    self.dataBuffer.append(data)
                    
                    if currentTime > self.LAST_SAVE + (self.CONFIG.period * 60) {
                        return
                    }
                    
                    let dataArray = Array(self.dataBuffer)
                    self.dbEngine?.save(dataArray, LinearAccelerometerData.TABLE_NAME)
                    self.notificationCenter.post(name: .actionAwareLinearAccelerometer, object: nil)
                    
                    self.dataBuffer.removeAll()
                    self.LAST_SAVE = currentTime
                }
            }
            if self.CONFIG.debug{ print(LinearAccelerometerSensor.TAG, "Gyroscope sensor active: \(self.CONFIG.frequency) hz") }
            self.notificationCenter.post(name: .actionAwareLinearAccelerometerStart, object:nil)
        }
    }
    
    public override func stop() {
        if self.motion.isGyroAvailable{
            if self.motion.isGyroActive{
                self.motion.stopGyroUpdates()
                if self.CONFIG.debug{ print(LinearAccelerometerSensor.TAG, "Gyroscope sensor terminated") }
                self.notificationCenter.post(name: .actionAwareLinearAccelerometerStop, object:nil)
            }
        }
    }
    
    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine{
            engine.startSync(LinearAccelerometerData.TABLE_NAME, DbSyncConfig().apply{config in
                config.debug = self.CONFIG.debug
            })
            self.notificationCenter.post(name: .actionAwareLinearAccelerometerSync, object:nil)
        }
    }
}