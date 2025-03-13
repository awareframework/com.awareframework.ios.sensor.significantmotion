# AWARE: Significant Motion

[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)


This sensor is used to track device significant motion. Also used internally by AWARE if available to save battery when the device is still with high-frequency sensors. SignificantMotionSensor.Observer allows programmers to take actions on detection of a significant motion.

Based of: [sensorplatforms/open-sensor-platform/significantmotiondetector.c](https://github.com/sensorplatforms/open-sensor-platform)

## Requirements
iOS 13 or later

## Installation

You can integrate this framework into your project via Swift Package Manager (SwiftPM) or CocoaPods.

### SwiftPM
1. Open Package Manager Windows
    * Open `Xcode` -> Select `Menu Bar` -> `File` -> `App Package Dependencies...` 

2. Find the package using the manager
    * Select `Search Package URL` and type `git@github.com:awareframework/com.awareframework.ios.sensor.significantmotion.git`

3. Import the package into your target.

4. Import com.awareframework.ios.sensor.barometer library into your source code.
```swift
import com_awareframework_ios_sensor_significantmotion
```


### CocoaPods

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

Yuuki Nishiyama (The University of Tokyo), nishiyama@csis.u-tokyo.ac.jp 

## License

Copyright (c) 2018 AWARE Mobile Context Instrumentation Middleware/Framework (http://www.awareframework.com)

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0 Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
