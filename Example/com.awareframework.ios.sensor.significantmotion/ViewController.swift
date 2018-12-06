//
//  ViewController.swift
//  com.awareframework.ios.sensor.significantmotion
//
//  Created by tetujin on 11/20/2018.
//  Copyright (c) 2018 tetujin. All rights reserved.
//

import UIKit
import com_awareframework_ios_sensor_significantmotion

class ViewController: UIViewController {

    var sensor:SignificantMotionSensor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        sensor = SignificantMotionSensor.init(SignificantMotionSensor.Config().apply{config in
//            config.debug = true
//            config.sensorObserver = Observer()
//        })
//        sensor?.start()
    }

    class Observer:SignificantMotionObserver {
        func onSignificantMotionStart() {
            print("====start====")
        }
        
        func onSignificantMotionEnd() {
            print("====stop====")
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

