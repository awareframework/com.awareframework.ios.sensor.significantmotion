#
# Be sure to run `pod lib lint com.awareframework.ios.sensor.significantmotion.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'com.awareframework.ios.sensor.significantmotion'
  s.version       = '0.2.0'
  s.summary          = 'A Significant Motion Sensor Module for AWARE Framework.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  This sensor is used to track device significant motion. Also used internally by AWARE if available to save battery when the device is still with high-frequency sensors. SignificantMotionSensor.Observer allows programmers to take actions on detection of a significant motion.

                       DESC

  s.homepage         = 'https://github.com/awareframework/com.awareframework.ios.sensor.significantmotion'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'Apache2', :file => 'LICENSE' }
  s.author           = { 'tetujin' => 'tetujin@ht.sfc.keio.ac.jp' }
  s.source           = { :git => 'https://github.com/awareframework/com.awareframework.ios.sensor.significantmotion.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '10.0'
  
  s.swift_version = '4.2'

  s.source_files = 'com.awareframework.ios.sensor.significantmotion/Classes/**/*'
  
  # s.resource_bundles = {
  #   'com.awareframework.ios.sensor.significantmotion' => ['com.awareframework.ios.sensor.significantmotion/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'CoreMotion' #'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
  
  s.dependency 'com.awareframework.ios.sensor.core', '~> 0.3.1'
end
