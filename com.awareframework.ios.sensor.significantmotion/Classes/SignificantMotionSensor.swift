//
//  SignificantMotionSensor.swift
//  com.aware.ios.sensor.significantmotion
//
//  Created by Yuuki Nishiyama on 2018/10/26.
//

import UIKit
import CoreMotion
import com_awareframework_ios_sensor_core

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
    public static let actionAwareSignificantMotionSyncCompletion     = Notification.Name(SignificantMotionSensor.ACTION_AWARE_SIGNIFICANT_MOTION_SYNC_COMPLETION)
}

public extension SignificantMotionSensor{
    static let TAG = "AWARE::Significant"
    
    /**
     * Fired when there is significant motion
     */
    static let ACTION_AWARE_SIGNIFICANT_MOTION_STARTED = "ACTION_AWARE_SIGNIFICANT_MOTION_STARTED"
    static let ACTION_AWARE_SIGNIFICANT_MOTION_ENDED = "ACTION_AWARE_SIGNIFICANT_MOTION_ENDED"
    
    static let ACTION_AWARE_SIGNIFICANT_MOTION_START = "com.awareframework.ios.sensor.significantmotion.SENSOR_START"
    static let ACTION_AWARE_SIGNIFICANT_MOTION_STOP = "com.awareframework.ios.sensor.significantmotion.SENSOR_STOP"
    
    static let ACTION_AWARE_SIGNIFICANT_MOTION_SET_LABEL = "com.awareframework.ios.sensor.significantmotion.ACTION_AWARE_SIGNIFICANT_MOTION_SET_LABEL"
    static let EXTRA_LABEL = "label"
    
    static let ACTION_AWARE_SIGNIFICANT_MOTION_SYNC = "com.awareframework.ios.sensor.significantmotion.SENSOR_SYNC"
    static let ACTION_AWARE_SIGNIFICANT_MOTION_SYNC_COMPLETION = "com.awareframework.ios.sensor.significantmotion.SENSOR_SYNC_COMPLETION"
    static let EXTRA_STATUS = "status"
    static let EXTRA_ERROR = "error"

}

public class SignificantMotionSensor: AwareSensor {
    /**
     * For real-time observation of the sensor data collection.
     */
    public var CONFIG = Config()
    
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
        
        public func apply(closure:(_ config: SignificantMotionSensor.Config) -> Void) -> Self {
            closure(self)
            return self
        }
    }
    
    public init(_ config: SignificantMotionSensor.Config){
        super.init()
        CONFIG = config
        initializeDbEngine(config: config)
        if config.debug { print(SignificantMotionSensor.TAG, #function) }
    }
    
    public override func start() {
        if self.CONFIG.debug { print(SignificantMotionSensor.TAG, #function) }
        if self.motion.isAccelerometerAvailable {
            /**
             * SensorManager.SENSOR_DELAY_FASTEST   0ms
             * SensorManager.SENSOR_DELAY_GAME     20ms
             * SensorManager.SENSOR_DELAY_UI       60ms
             * SensorManager.SENSOR_DELAY_NORMAL  200ms
             */
            let interval = 20.0 / 1000.0
            self.motion.accelerometerUpdateInterval = interval
            self.motion.startAccelerometerUpdates(to: .main) { (accData, error) in
                if let data = accData {
                    let x = data.acceleration.x
                    let y = data.acceleration.y
                    let z = data.acceleration.z
                    // print("[\(x),\(y),\(z)],")
                    self.detectSignificantMotion(x:x, y:y, z:z)
                }
            }
            self.notificationCenter.post(name: .actionAwareSignificantMotionStart, object: self)
        }
    }
    
    public override func stop() {
        if self.CONFIG.debug { print(SignificantMotionSensor.TAG, #function) }
        if self.motion.isAccelerometerAvailable{
            self.motion.stopAccelerometerUpdates()
            self.notificationCenter.post(name: .actionAwareSignificantMotionStop, object: self)
        }
    }
    
    public override func sync(force: Bool = false) {
        if self.CONFIG.debug { print(SignificantMotionSensor.TAG, #function) }
        if let engine = self.dbEngine {
            engine.startSync(SignificantMotionData.TABLE_NAME, SignificantMotionData.self, DbSyncConfig.init().apply{config in
                config.debug = self.CONFIG.debug
                config.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.significantmotion.sync.queue")
                config.completionHandler = { (status, error) in
                    var userInfo: Dictionary<String,Any> = [SignificantMotionSensor.EXTRA_STATUS :status]
                    if let e = error {
                        userInfo[SignificantMotionSensor.EXTRA_ERROR] = e
                    }
                    self.notificationCenter.post(name: .actionAwareSignificantMotionSyncCompletion,
                                                 object: self,
                                                 userInfo:userInfo)
                }
            })
        }
        self.notificationCenter.post(name: .actionAwareSignificantMotionSync, object: self)
    }
    
    public override func set(label:String) {
        if self.CONFIG.debug { print(SignificantMotionSensor.TAG, #function) }
        self.CONFIG.label = label
        self.notificationCenter.post(name: .actionAwareSignificantMotionSetLabel, object: self, userInfo: [SignificantMotionSensor.EXTRA_LABEL: label])
    }
    
    func detectSignificantMotion(x:Double, y:Double, z:Double){
        if self.CONFIG.debug { print(SignificantMotionSensor.TAG, #function) }
        /**
         * The algorithm information
         * https://developer.android.com/reference/android/hardware/SensorManager
         * https://developer.android.com/guide/topics/sensors/sensors_motion
         * GRAVITY_EARTH = Earth's gravity in SI units (m/s^2) = Constant Value: 9.80665
         * val mSignificantEnergy = sqrt(x * x + y * y + z * z) - SensorManager.GRAVITY_EARTH
         * buffer.add(abs(mSignificantEnergy))
         *
         * iOS specific information
         * https://developer.apple.com/documentation/coremotion/getting_raw_accelerometer_events
         * iOS Accelerometer provides data which unit is G(9.8 meters per second).
         * For removing earth's gravity, "-1.0" is requred.
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
                data.label  = self.CONFIG.label
                
                if let engine = self.dbEngine {
                    engine.save(data)
                }
                
                if (self.currentSignificantMotionState){
                    if let observer = self.CONFIG.sensorObserver{
                        observer.onSignificantMotionStart()
                    }
                    self.notificationCenter.post(name: .actionAwareSignificantMotionStarted, object: self)
                }else{
                    if let observer = self.CONFIG.sensorObserver{
                        observer.onSignificantMotionEnd()
                    }
                    self.notificationCenter.post(name: .actionAwareSignificantMotionEnded, object: self)
                }
            }
            self.lastSignificantMotionState = self.currentSignificantMotionState
        }
    }
}
