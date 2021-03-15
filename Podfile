source 'https://cdn.cocoapods.org/'
use_frameworks! :linkage => :static
inhibit_all_warnings!

install! 'cocoapods',
    :generate_multiple_pod_projects => true,
    :incremental_installation => true,
    :disable_input_output_paths => true

deployment_target = '12.4'
platform :ios, deployment_target

def pods
    pod 'Sentry'
    pod 'SVProgressHUD'
    pod 'InAppSettingsKit'
    pod 'MultiSelectSegmentedControl'
    pod 'CorePlot'
    pod 'DZNEmptyDataSet'
    pod 'DeviceKit'

    pod 'SwiftyDropbox', :git => "https://github.com/gereons/SwiftyDropbox"
    pod 'Alamofire'
    pod 'AlamofireImage'
    pod 'AlamofireNetworkActivityIndicator'
    pod 'SwiftKeychainWrapper'
    pod 'SDCAlertView'
    pod 'EasyTipView'
    pod 'SwiftyUserDefaults', '~> 3'
    pod 'ColorCompatibility'
end

target 'NetDeck' do
    pods
end

target 'NetDeckTests' do
    pods
end

post_install do |installer|
    require 'fileutils'
    system("awk -f ackhtml.awk <'Pods/Target Support Files/Pods-NetDeck/Pods-NetDeck-acknowledgements.markdown' >NetDeck/Acknowledgements.html")

    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = deployment_target
                config.build_settings.delete('ARCHS')
            end
        end
        project.build_configurations.each do |config|
            config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = deployment_target
            config.build_settings.delete('ARCHS')
        end
    end
end
