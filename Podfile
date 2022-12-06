platform :ios, '13.0'
use_frameworks!
inhibit_all_warnings!

target 'TDCDemoDJI' do
  pod 'DJI-SDK-iOS'
  pod 'DJI-UXSDK-iOS'
  pod 'DJIWidget'
  pod 'DJIFlySafeDatabaseResource'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['ENABLE_BITCODE'] = 'NO'
      end
    end
end


