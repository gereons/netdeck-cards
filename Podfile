source 'https://github.com/CocoaPods/Specs.git'
use_frameworks!
inhibit_all_warnings!
platform :ios, '9.2'
target 'NetDeck' do
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'DTCoreText'
    pod 'SVProgressHUD'
    pod 'InAppSettingsKit'
    pod 'MultiSelectSegmentedControl'
    pod 'CorePlot'
    pod 'DZNEmptyDataSet'
    pod 'DeviceKit'

    pod 'SwiftyDropbox', '~> 4.0'
    pod 'Alamofire'
    pod 'AlamofireImage'
    pod 'AlamofireNetworkActivityIndicator'
    pod 'SwiftKeychainWrapper'
    pod 'Marshal'
    pod 'SDCAlertView'
    pod 'EasyTipView'
    pod 'SwiftyUserDefaults'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'EasyTipView' || target.name == 'AlamofireImage'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '3.0'
            end
        end
        if target.name == 'CorePlot'
            target.build_configurations.each do |config|
                config.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'NO'
            end
        end
    end

    require 'fileutils'
    system("awk -f ackhtml.awk <'Pods/Target Support Files/Pods-NetDeck/Pods-NetDeck-acknowledgements.markdown' >NetDeck/Acknowledgements.html")
end
