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
    public static let actionAwareLinearAccelerometerSyncCompletion  = Notification.Name(LinearAccelerometerSensor.ACTION_AWARE_LINEAR_ACCELEROMETER_SYNC_COMPLETION)
}

extension LinearAccelerometerSensor{
    public static let TAG = "AWARE::LinearAcc"
    
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER = "ACTION_AWARE_LINEAR_ACCELEROMETER"
    
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER_START = "com.awareframework.sensor.linearaccelerometer.SENSOR_START"
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER_STOP = "com.awareframework.sensor.linearaccelerometer.SENSOR_STOP"
    
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER_SET_LABEL = "com.awareframework.sensor.linearaccelerometer.ACTION_AWARE_LINEAR_ACCELEROMETER_SET_LABEL"
    public static let EXTRA_LABEL = "label"
    
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER_SYNC = "com.awareframework.sensor.linearaccelerometer.SENSOR_SYNC"
    
    public static let ACTION_AWARE_LINEAR_ACCELEROMETER_SYNC_COMPLETION = "com.awareframework.ios.sensor.linearaccelerometer.SENSOR_SYNC_COMPLETION"
    public static let EXTRA_STATUS = "status"
    public static let EXTRA_ERROR = "error"
}

public protocol LinearAccelerometerObserver {
    func onDataChanged(data:LinearAccelerometerData)
}

public class LinearAccelerometerSensor: AwareSensor {
    public var CONFIG = LinearAccelerometerSensor.Config()
    var motion = CMMotionManager()
    var LAST_DATA:CMDeviceMotion?
    var LAST_TS:Double   = Date().timeIntervalSince1970
    var LAST_SAVE:Double = Date().timeIntervalSince1970
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
        
        public override func set(config: Dictionary<String, Any>){
            super.set(config: config)
            if let period = config["period"] as? Double {
                self.period = period
            }
            
            if let threshold = config ["threshold"] as? Double {
                self.threshold = threshold
            }
            
            if let frequency = config["frequency"] as? Int {
                self.frequency = frequency
            }
        }
        
        public func apply(closure: (_ config: LinearAccelerometerSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }
    
    public override convenience init(){
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
                    data.label = self.CONFIG.label
                    
                    if let observer = self.CONFIG.sensorObserver {
                        observer.onDataChanged(data: data)
                    }
                    
                    self.dataBuffer.append(data)
                    
                    // print(currentTime, self.LAST_SAVE + (self.CONFIG.period * 60))
                    if currentTime < self.LAST_SAVE + (self.CONFIG.period * 60) {
                        return
                    }
                    
                    let dataArray = Array(self.dataBuffer)
                    
                    if let engine = self.dbEngine{
                        let queue = DispatchQueue(label: "com.awareframework.ios.sensor.linearaccelerometer.save.queue")
                        queue.async {
                            engine.save(dataArray) { (error) in
                                if error == nil {
                                    DispatchQueue.main.async {
                                        self.notificationCenter.post(name: .actionAwareLinearAccelerometer, object: self)
                                    }
                                }else{
                                    if self.CONFIG.debug { print(error!) }
                                }
                            }
                        }
                    }
                    self.dataBuffer.removeAll()
                    self.LAST_SAVE = currentTime
                }
            }
            if self.CONFIG.debug{ print(LinearAccelerometerSensor.TAG, "Linear Accelerometer active: \(self.CONFIG.frequency) hz") }
            self.notificationCenter.post(name: .actionAwareLinearAccelerometerStart, object:self)
        }
    }
    
    public override func stop() {
        if self.motion.isDeviceMotionAvailable && self.motion.isDeviceMotionActive {
            self.motion.stopDeviceMotionUpdates()
            if self.CONFIG.debug{ print(LinearAccelerometerSensor.TAG, "Linear Accelerometer terminated") }
            self.notificationCenter.post(name: .actionAwareLinearAccelerometerStop, object:self)
        }
    }
    
    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine{
            engine.startSync(LinearAccelerometerData.TABLE_NAME, LinearAccelerometerData.self, DbSyncConfig().apply{config in
                config.debug = self.CONFIG.debug
                config.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.linearaccelerometer.sync.queue")
                config.completionHandler = { (status, error) in
                    var userInfo: Dictionary<String,Any> = [LinearAccelerometerSensor.EXTRA_STATUS :status]
                    if let e = error {
                        userInfo[LinearAccelerometerSensor.EXTRA_ERROR] = e
                    }
                    self.notificationCenter.post(name: .actionAwareLinearAccelerometerSyncCompletion,
                                                 object: self,
                                                 userInfo:userInfo)
                }
            })
            self.notificationCenter.post(name: .actionAwareLinearAccelerometerSync, object:self)
        }
    }
    
    public override func set(label:String){
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionAwareLinearAccelerometerSetLabel,
                                     object: self,
                                     userInfo: [LinearAccelerometerSensor.EXTRA_LABEL:label])
    }
}
