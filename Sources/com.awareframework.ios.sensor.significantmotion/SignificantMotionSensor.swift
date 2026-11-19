//
//  SignificantMotionSensor.swift
//  com.aware.ios.sensor.significantmotion
//
//  Created by Yuuki Nishiyama on 2018/10/26.
//

import UIKit
import CoreMotion
import com_awareframework_ios_core

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

    /// Accelerometer samples (50 Hz) are received and processed here, not on the main thread.
    /// Serial, so `buffer` and the motion state are only touched by one sample at a time.
    private let motionQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.name = "com.awareframework.ios.sensor.significantmotion.motion"
        queue.maxConcurrentOperationCount = 1
        queue.qualityOfService = .utility
        return queue
    }()
    
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
        super.syncConfig = DbSyncConfig().apply { c in
            c.dispatchQueue = DispatchQueue(label: "com.awareframework.ios.sensor.significantmotion.sync.queue")
        }
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
            // Samples arrive on motionQueue; observers and notifications are still called on the main thread
            self.motion.startAccelerometerUpdates(to: motionQueue) { (accData, error) in
                if let data = accData {
                    let x = data.acceleration.x
                    let y = data.acceleration.y
                    let z = data.acceleration.z
                    // print("[\(x),\(y),\(z)],")
                    self.detectSignificantMotion(x:x, y:y, z:z)
                }
            }
            postOnMain(.actionAwareSignificantMotionStart)
        }
    }
    
    public override func stop() {
        if self.CONFIG.debug { print(SignificantMotionSensor.TAG, #function) }
        if self.motion.isAccelerometerAvailable{
            self.motion.stopAccelerometerUpdates()
            postOnMain(.actionAwareSignificantMotionStop)
        }
    }
    
    public override func sync(force: Bool = false) {
        if self.CONFIG.debug { print(SignificantMotionSensor.TAG, #function) }
        guard let engine = self.dbEngine, let syncConfig = self.syncConfig else { return }
        syncConfig.debug = self.CONFIG.debug
        syncConfig.completionHandler = { (status, error) in
            var userInfo: Dictionary<String,Any> = [SignificantMotionSensor.EXTRA_STATUS: status]
            if let e = error { userInfo[SignificantMotionSensor.EXTRA_ERROR] = e }
            self.postOnMain(.actionAwareSignificantMotionSyncCompletion, userInfo: userInfo)
        }
        engine.startSync(syncConfig)
        postOnMain(.actionAwareSignificantMotionSync)
    }
    
    public override func set(label:String) {
        if self.CONFIG.debug { print(SignificantMotionSensor.TAG, #function) }
        self.CONFIG.label = label
        postOnMain(.actionAwareSignificantMotionSetLabel, userInfo: [SignificantMotionSensor.EXTRA_LABEL: label])
    }
    
    /// Posts a notification on the main thread (right away when already on it).
    private func postOnMain(_ name: Notification.Name, userInfo: [AnyHashable: Any]? = nil) {
        if Thread.isMainThread {
            notificationCenter.post(name: name, object: self, userInfo: userInfo)
        } else {
            DispatchQueue.main.async {
                self.notificationCenter.post(name: name, object: self, userInfo: userInfo)
            }
        }
    }

    /// Processes one accelerometer sample. Called on `motionQueue` (or by tests on their own thread).
    /// The row is saved on the calling thread; observers and notifications are called on the main thread.
    func detectSignificantMotion(x:Double, y:Double, z:Double){
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
                var data = SignificantMotionData()
                data.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
                data.moving = self.currentSignificantMotionState
                data.label  = self.CONFIG.label
                
                if let engine = self.dbEngine {
                    engine.save([data])
                }
                
                let moving = self.currentSignificantMotionState
                if self.CONFIG.debug { print(SignificantMotionSensor.TAG, "moving:", moving) }
                DispatchQueue.main.async {
                    if moving {
                        self.CONFIG.sensorObserver?.onSignificantMotionStart()
                        self.notificationCenter.post(name: .actionAwareSignificantMotionStarted, object: self)
                    } else {
                        self.CONFIG.sensorObserver?.onSignificantMotionEnd()
                        self.notificationCenter.post(name: .actionAwareSignificantMotionEnded, object: self)
                    }
                }
            }
            self.lastSignificantMotionState = self.currentSignificantMotionState
        }
    }
}
