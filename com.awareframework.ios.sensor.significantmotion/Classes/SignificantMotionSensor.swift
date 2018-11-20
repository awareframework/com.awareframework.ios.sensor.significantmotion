//
//  SignificantMotionSensor.swift
//  com.aware.ios.sensor.significantmotion
//
//  Created by Yuuki Nishiyama on 2018/10/26.
//

import UIKit
import CoreMotion
import com_awareframework_ios_sensor_core
import SwiftyJSON

public protocol SignificantMotionObserver{
    func onSignificantMotionStart()
    func onSignificantMotionEnd()
}

extension Notification.Name {
    public static let actionAwareSignificantMotionStart = Notification.Name(SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_START)
    public static let actionAwareSignificantMotionStop  = Notification.Name(SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_STOP)
    
    public static let actionAwareSignificantMotionStarted  = Notification.Name(SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_STARTED)
    public static let actionAwareSignificantMotionEnded    = Notification.Name(SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_ENDED)
    public static let actionAwareSignificantMotionSetLabel = Notification.Name(SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_SET_LABEL)
    public static let actionAwareSignificantMotionSync     = Notification.Name(SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_SYNC)
}

public extension SignificantMotionSensor{
    public static let TAG = "AWARE::Significant"
    
    /**
     * Fired when there is significant motion
     */
    public static let ACTION_AWARE_SIGNIFICANT_MOTION_STARTED = "ACTION_AWARE_SIGNIFICANT_MOTION_STARTED"
    public static let ACTION_AWARE_SIGNIFICANT_MOTION_ENDED = "ACTION_AWARE_SIGNIFICANT_MOTION_ENDED"
    
    public static let ACTION_AWARE_SIGNIFICANT_MOTION_START = "com.awareframework.android.sensor.significantmotion.SENSOR_START"
    public static let ACTION_AWARE_SIGNIFICANT_MOTION_STOP = "com.awareframework.android.sensor.significantmotion.SENSOR_STOP"
    
    public static let ACTION_AWARE_SIGNIFICANT_MOTION_SET_LABEL = "com.awareframework.android.sensor.significantmotion.ACTION_AWARE_SIGNIFICANT_MOTION_SET_LABEL"
    public static let EXTRA_LABEL = "label"
    
    public static let ACTION_AWARE_SIGNIFICANT_MOTION_SYNC = "com.awareframework.android.sensor.significantmotion.SENSOR_SYNC"

}

public class SignificantMotionSensor: AwareSensor {
    
    /**
     * For real-time observation of the sensor data collection.
     */
    public var CONFIG = Config()
    
    var timer:Timer?
    var motion = CMMotionManager()
    var buffer:Array<Double> = Array<Double>()
    private var lastSignificantMotionState = false
    var currentSignificantMotionState = false
    private let significantMotionThreshold = 1.0
    
    var isSignificantMotionActive = false
    
    public class Config:SensorConfig {
        public var sensorObserver:SignificantMotionObserver? = nil
        
        public override init(){
            super.init()
            dbPath = "aware_significant_motion"
        }
        
        public convenience init(_ json:JSON){
            self.init()
        }
        
        public func apply(closure:(_ config: SignificantMotionSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }
    
    public init(_ config: SignificantMotionSensor.Config){
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
        if config.debug { print(SignificantMotionSensor.TAG, "SignificantMotion sensor is created") }
    }
    
    public override func start() {
        if self.motion.isAccelerometerAvailable {
            /**
             * SensorManager.SENSOR_DELAY_FASTEST   0ms
             * SensorManager.SENSOR_DELAY_GAME     20ms
             * SensorManager.SENSOR_DELAY_UI       60ms
             * SensorManager.SENSOR_DELAY_NORMAL  200ms
             */
            let interval = 20.0 / 1000.0
            self.motion.accelerometerUpdateInterval = interval
            self.motion.startAccelerometerUpdates(to: .main) { (data, error) in
                if let accData = data {
                    
                    let x = accData.acceleration.x
                    let y = accData.acceleration.y
                    let z = accData.acceleration.z

                    /**
                     * TODO: check an algorithm on Android
                     * https://developer.android.com/reference/android/hardware/SensorManager
                     * https://developer.android.com/guide/topics/sensors/sensors_motion
                     * GRAVITY_EARTH = Earth's gravity in SI units (m/s^2) = Constant Value: 9.80665
                     * val mSignificantEnergy = sqrt(x * x + y * y + z * z) - SensorManager.GRAVITY_EARTH
                     * buffer.add(abs(mSignificantEnergy))
                     *
                     * // iOS document
                     * https://developer.apple.com/documentation/coremotion/getting_raw_accelerometer_events
                     * iOS Accelerometer class provides data which unit is G(9.8 meters per second).
                     * For removing Earth's gravity, "-1.0" is requred.
                     */
                    let significantEnergy = abs(sqrt(x*x + y*y + z*z)) - 1.0
                    
                    self.buffer.append(significantEnergy)
                    // print(significantEnergy)
                    
                    if(self.buffer.count >= 40){
                        self.buffer.remove(at: 0)
                        
                        if let maxEnergy = self.buffer.max() {
                            if maxEnergy >= self.significantMotionThreshold {
                                self.currentSignificantMotionState = true
                            }else{
                                self.currentSignificantMotionState = false
                            }
                        }
                        
                        if (self.currentSignificantMotionState != self.lastSignificantMotionState){
                            let data = SignificantMotionData()
                            data.moving = self.currentSignificantMotionState
                            
                            if let engine = self.dbEngine {
                                engine.save(data, SignificantMotionData.TABLE_NAME)
                            }
                            
                            if (self.currentSignificantMotionState){
                                if let observer = self.CONFIG.sensorObserver{
                                    observer.onSignificantMotionStart()
                                }
                                self.notificationCenter.post(name: .actionAwareSignificantMotionStarted, object: nil)
                            }else{
                                if let observer = self.CONFIG.sensorObserver{
                                    observer.onSignificantMotionEnd()
                                }
                                self.notificationCenter.post(name: .actionAwareSignificantMotionEnded, object: nil)
                            }
                        }
                        self.lastSignificantMotionState = self.currentSignificantMotionState
                    }
                }
                self.notificationCenter.post(name: .actionAwareSignificantMotionStart, object: nil)
            }
        }else{
            
        }
    }
    
    public override func stop() {
        if self.motion.isAccelerometerAvailable{
            self.motion.stopAccelerometerUpdates()
            if let t = self.timer{
                t.invalidate()
                self.timer = nil
            }
            self.notificationCenter.post(name: .actionAwareSignificantMotionStop, object: nil)
        }
    }
    
    public override func sync(force: Bool = false) {
        if let engine = self.dbEngine {
            engine.startSync(SignificantMotionData.TABLE_NAME, DbSyncConfig.init().apply{config in
                config.debug = self.CONFIG.debug
            })
        }
        self.notificationCenter.post(name: .actionAwareSignificantMotionSync, object: nil)
    }
    
}
