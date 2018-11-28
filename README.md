# AWARE: Significant Motion

[![CI Status](https://img.shields.io/travis/awareframework/com.awareframework.ios.sensor.significantmotion.svg?style=flat)](https://travis-ci.org/awareframework/com.awareframework.ios.sensor.significantmotion)
[![Version](https://img.shields.io/cocoapods/v/com.awareframework.ios.sensor.significantmotion.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.significantmotion)
[![License](https://img.shields.io/cocoapods/l/com.awareframework.ios.sensor.significantmotion.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.significantmotion)
[![Platform](https://img.shields.io/cocoapods/p/com.awareframework.ios.sensor.significantmotion.svg?style=flat)](https://cocoapods.org/pods/com.awareframework.ios.sensor.significantmotion)

This sensor is used to track device significant motion. Also used internally by AWARE if available to save battery when the device is still with high-frequency sensors. SignificantMotionSensor.Observer allows programmers to take actions on detection of a significant motion.

Based of: [sensorplatforms/open-sensor-platform/significantmotiondetector.c](https://github.com/sensorplatforms/open-sensor-platform)

## Requirements
iOS 10 or later

## Installation

com.awareframework.ios.sensor.significantmotion is available through [CocoaPods](https://cocoapods.org). 

1. To install it, simply add the following line to your Podfile:

```ruby
pod 'com.awareframework.ios.sensor.significantmotion'
```

2. Import com.awareframework.ios.sensor.barometer library into your source code.
```swift
import com_awareframework_ios_sensor_significantmotion
```

## Public functions

### SignificantMotioneSensor

+ `init(config:SignificantMotioneSensor.Config?)` : Initializes the significant motioneSensor sensor with the optional configuration.
+ `start()`: Starts the significant motion sensor with the optional configuration.
+ `stop()`: Stops the service.

###  SignificantMotioneSensor.Config

Class to hold the configuration of the sensor.

#### Fields

+ `sensorObserver: SignificantMotionObserver`: Callback for live data updates.
+ `enabled: Boolean` Sensor is enabled or not. (default = `false`)
+ `debug: Boolean` enable/disable logging to `Logcat`. (default = `false`)
+ `label: String` Label for the data. (default = "")
+ `deviceId: String` Id of the device that will be associated with the events and the sensor. (default = "")
+ `dbEncryptionKey` Encryption key for the database. (default = `null`)
+ `dbType: Engine` Which db engine to use for saving data. (default = `Engine.DatabaseType.NONE`)
+ `dbPath: String` Path of the database. (default = "aware_significantmotion")
+ `dbHost: String` Host for syncing the database. (default = `null`)

## Broadcasts

### Fired Broadcasts

+ `SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_STARTED` fired when there is a significant motion.
+ `SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_ENDED` fired when the significant motion has ended.

### Received Broadcasts

+ `SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_START`: received broadcast to start the sensor.
+ `SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_STOP`: received broadcast to stop the sensor.
+ `SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_SYNC`: received broadcast to send sync attempt to the host.
+ `SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_SET_LABEL`: received broadcast to set the data label. Label is expected in the `SignificantMotionSensor.EXTRA_LABEL` field of the intent extras.

## Data Representations

### SignificantMotion Data

Contains the motion changes.

| Field     | Type    | Description                                                     |
| --------- | ------- | --------------------------------------------------------------- |
| moving    | Boolean | Indicates that a significant motion was detected or not.        |
| label     | String  | Customizable label. Useful for data calibration or traceability |
| deviceId  | String  | AWARE device UUID                                               |
| label     | String  | Customizable label. Useful for data calibration or traceability |
| timestamp | Long    | unixtime milliseconds since 1970                                |
| timezone  | Int     | Ttimezone of the device                          |
| os        | String  | Operating system of the device (ex. android)                    |

## Example usage
```swift
    let sensor = SignificantMotionSensor.init(SignificantMotionSensor.Config().apply{config in
        config.sensorObserver = Observer()
        config.debug  = true
        config.dbType = .REALM
    })
    sensor.start()
    sensor.stop()
}
```

```swift
class Observer:SignificantMotionObserver{
    func onSignificantMotionStart() {
        // Your code here...
    }

    func onSignificantMotionEnd() {
        // Your code here...
    }
}
```

## Author

Yuuki Nishiyama, yuuki.nishiyama@oulu.fi

## License

Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
