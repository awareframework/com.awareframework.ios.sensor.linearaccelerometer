# Aware Linear Accelerometer

[![CI Status](https://img.shields.io/travis/awareframework/com.awareframework.ios.sensor.linearaccelerometer.svg?style=flat)](https://travis-ci.org/awareframework/com.awareframework.ios.sensor.linearaccelerometer)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.linearaccelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.linearaccelerometer)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.linearaccelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.linearaccelerometer)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.linearaccelerometer.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.linearaccelerometer)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements
iOS 10 or later

## Installation

com.awareframework.ios.sensor.linearaccelerometer is available through [CocoaPods](https://cocoapods.org). 

1. To install it, simply add the following line to your Podfile:
```ruby
pod 'com.awareframework.ios.sensor.linearaccelerometer'
```

2. Import com.awareframework.ios.sensor.linearaccelerometer library into your source code.
```swift
import com_awareframework_ios_sensor_linearaccelerometer
```

## Public functions

### LinearAccelerometerSensor

+ `init(config:LinearAccelerometerSensor.Config?)` : Initializes the linear-accelerometer sensor with the optional configuration.
+ `start()`: Starts the gyroscope sensor with the optional configuration.
+ `stop()`: Stops the service.

### LinearAccelerometerSensor.Config

Class to hold the configuration of the sensor.

#### Fields
+ `sensorObserver: LinearAccelerometerObserver`: Callback for live data updates.
+ `frequency: Int`: Data samples to collect per second (Hz). (default = 5)
+ `period: Double`: Period to save data in minutes. (default = 1)
+ `threshold: Double`: If set, do not record consecutive points if change in value is less than the set value.
+ `enabled: Boolean` Sensor is enabled or not. (default = `false`)
+ `debug: Boolean` enable/disable logging to Xcode console. (default = `false`)
+ `label: String` Label for the data. (default = "")
+ `deviceId: String` Id of the device that will be associated with the events and the sensor. (default = "")
+ `dbEncryptionKey` Encryption key for the database. (default = `null`)
+ `dbType: Engine` Which db engine to use for saving data. (default = `Engine.DatabaseType.NONE`)
+ `dbPath: String` Path of the database. (default = "aware_gyroscope")
+ `dbHost: String` Host for syncing the database. (default = `null`)

## Broadcasts

### Fired Broadcasts

+ `LinearAccelerometerSensor.ACTION_AWARE_GYROSCOPE` fired when gyroscope saved data to db after the period ends.

### Received Broadcasts

+ `LinearAccelerometerSensor.ACTION_AWARE_LINEAR_ACCELEROMETER_START`: received broadcast to start the sensor.
+ `LinearAccelerometerSensor.ACTION_AWARE_LINEAR_ACCELEROMETER_STOP`: received broadcast to stop the sensor.
+ `LinearAccelerometerSensor.ACTION_AWARE_LINEAR_ACCELEROMETER_SYNC`: received broadcast to send sync attempt to the host.
+ `LinearAccelerometerSensor.ACTION_AWARE_LINEAR_ACCELEROMETER_SET_LABEL`: received broadcast to set the data label. Label is expected in the `LinearAccelerometerSensor.EXTRA_LABEL` field of the intent extras.

## Data Representations

### LinearAccelerometer Data

Contains the raw sensor data.

| Field     | Type   | Description                                                     |
| --------- | ------ | --------------------------------------------------------------- |
| x         | Double  | value of X axis                                                 |
| y         | Double  | value of Y axis                                                 |
| z         | Double  | value of Z axis                                                 |
| label     | String | Customizable label. Useful for data calibration or traceability |
| deviceId  | String | AWARE device UUID                                               |
| label     | String | Customizable label. Useful for data calibration or traceability |
| timestamp | Int64   | unixtime milliseconds since 1970                                |
| timezone  | Int    | Raw timezone offset of the device                          |
| os        | String | Operating system of the device (ex. ios)                    |

## Example usage
```siwft
var linearAccSensor = LinearAccelerometerSensor.init(LinearAccelerometerSensor.Config().apply{config in
    config.debug    = true
    config.dbType   = .REALM
    config.sensorObserver = Observer()
})
linearAccSensor.start()
```

```swift
class Observer:LinearAccelerometerObserver{
    func onDataChanged(data: LinearAccelerometerData) {
        // Your code here...
    }
}
```

## Author

Yuuki Nishiyama, tetujin@ht.sfc.keio.ac.jp

## License

Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
