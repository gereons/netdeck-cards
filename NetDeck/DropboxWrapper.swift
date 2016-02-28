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
        Dropbox.setupWithAppKey("4mhw6piwd9wqti3")
        
        // let clientOk = Dropbox.authorizedClient != nil
        // print("dropbox setup, clientOk=\(clientOk)")
    }

    class func handleURL(url: NSURL) -> Bool {
        if let authResult = Dropbox.handleRedirectURL(url) {
            switch authResult {
            case .Success:
                print("Success! User is logged into Dropbox.")
                return true
            case .Error(let error, let description):
                print("Error: \(error) \(description)")
                return false
            }
        }
        
        return false
    }
    
    class func authorizeFromController(controller: UIViewController) {
        if (Dropbox.authorizedClient == nil) {
            Dropbox.authorizeFromController(controller)
        } else {
            print("User is already authorized!")
        }
    }
    
    class func unlinkClient() {
        Dropbox.unlinkClient()
    }
    
    class func listDropboxFiles(completion: ([String])->() ) {
        guard let client = Dropbox.authorizedClient else { return }
        
        client.files.listFolder(path: "").response { response, error in
            if let result = response {
                var names = [String]()
                for entry in result.entries {
                    names.append(entry.name)
                }
                completion(names)
            }
        }
    }
    
    class func downloadDropboxFiles(names: [String], toDirectory: String, completion: ()->() ) {
        guard let client = Dropbox.authorizedClient else { return }
        
        var count = 0
        for name in names {
            client.files.download(path: "/" + name, destination: { (url, response) -> NSURL in
                let path = toDirectory.stringByAppendingPathComponent(name)
                let destination = NSURL(fileURLWithPath: path)
                return destination
            }).response { response, error in
                ++count
                if count == names.count {
                    completion()
                }
                if let (metadata, _) = response {
                    let attrs = [ NSFileModificationDate: metadata.serverModified ]
                    let path = toDirectory.stringByAppendingPathComponent(name)
                    _ = try? NSFileManager.defaultManager().setAttributes(attrs, ofItemAtPath: path)
                }
            }
        }
    }
    
    class func saveFileToDropbox(content: String, filename: String, completion: (Bool)->() ) {
        guard let client = Dropbox.authorizedClient else { return }
        
        if let data = content.dataUsingEncoding(NSUTF8StringEncoding) {
            client.files.upload(path: "/" + filename, mode: .Overwrite, autorename: false, clientModified: nil, mute: false, body: data).response { response, error in
                completion(error == nil)
            }
        } else {
            completion(false)
        }
    }
}
