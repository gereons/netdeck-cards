//
//  DropboxWrapper
//  NetDeck
//
//  Created by Gereon Steffens on 13.02.16.
//  Copyright © 2016 Gereon Steffens. All rights reserved.
//

// obj-c callable interface to the new swift-based dropbox API

import SwiftyDropbox

class DropboxWrapper: NSObject {
    
    class func setup() {
        DropboxClientsManager.setupWithAppKey("4mhw6piwd9wqti3")
        
        // let clientOk = Dropbox.authorizedClient != nil
        // print("dropbox setup, clientOk=\(clientOk)")
    }

    class func handleURL(_ url: URL) -> Bool {
        if let authResult = DropboxClientsManager.handleRedirectURL(url) {
            switch authResult {
            case .success:
                print("Success! User is logged into Dropbox.")
                return true
            case .error(let error, let description):
                print("Error: \(error) \(description)")
                return false
            case .cancel:
                print("Cancelled")
                return false
            }
        }
        
        return false
    }
    
    class func authorizeFromController(_ controller: UIViewController) {
        if (DropboxClientsManager.authorizedClient == nil) {
            DropboxClientsManager.authorizeFromController(UIApplication.shared,
                                                          controller: controller,
                                                          openURL: { url in UIApplication.shared.openURL(url) },
                                                          browserAuth: false)
        } else {
            print("User is already authorized!")
        }
    }
    
    class func unlinkClient() {
        DropboxClientsManager.unlinkClient()
    }
    
    class func listDropboxFiles(_ completion: @escaping ([String])->() ) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        
        let _ = client.files.listFolder(path: "").response { response, error in
            if let result = response {
                var names = [String]()
                for entry in result.entries {
                    names.append(entry.name)
                }
                completion(names)
            }
        }
    }
    
    class func downloadDropboxFiles(_ names: [String], toDirectory: String, completion: @escaping ()->() ) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        
        var count = 0
        for name in names {
            let _ = client.files.download(path: "/" + name, destination: { (url, response) -> URL in
                let path = toDirectory.stringByAppendingPathComponent(name)
                let destination = URL(fileURLWithPath: path)
                return destination
            }).response { response, error in
                count += 1
                if count == names.count {
                    completion()
                }
                if let (metadata, _) = response {
                    let attrs = [ FileAttributeKey.modificationDate: metadata.serverModified ]
                    let path = toDirectory.stringByAppendingPathComponent(name)
                    _ = try? FileManager.default.setAttributes(attrs, ofItemAtPath: path)
                }
            }
        }
    }
    
    class func saveFileToDropbox(_ content: String, filename: String, completion: @escaping (Bool)->() ) {
        guard let client = DropboxClientsManager.authorizedClient else { return }
        
        if let data = content.data(using: String.Encoding.utf8) {
            print("\(data)")
            let _ = client.files.upload(path: "/" + filename, mode: .overwrite, autorename: false, clientModified: nil, mute: false, input: data).response { response, error in
                completion(error == nil)
            }
        } else {
            completion(false)
        }
    }
}
