//
//  SignificantMotionData.swift
//  com.aware.ios.sensor.significantmotion
//
//  Created by Yuuki Nishiyama on 2018/10/26.
//

import UIKit
@testable import com_awareframework_ios_sensor_core

public class SignificantMotionData: AwareObject {
    public static var TABLE_NAME = "significantMotionData"
    
    @objc dynamic public var moving:Bool = false
    
    public override func toDictionary() -> Dictionary<String, Any> {
        var dict = super.toDictionary()
        dict["moving"] = moving
        return dict
    }
}
