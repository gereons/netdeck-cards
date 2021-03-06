//
//  ImageCache.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.03.16.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Alamofire
import AlamofireImage
import SwiftyUserDefaults

private class ImageMemCache {
    private var cache: NSCache<NSString, UIImage>

    init() {
        self.cache = NSCache()
        self.cache.countLimit = 1400
    }

    subscript(_ key: String) -> UIImage? {
        get {
            return self.cache.object(forKey: key as NSString)
        }

        set {
            if let img = newValue {
                self.cache.setObject(img, forKey: key as NSString)
            } else {
                self.cache.removeObject(forKey: key as NSString)
            }
        }
    }

    func removeAll() {
        self.cache.removeAllObjects()
    }
}

class ImageCache {
    static let imagesDirectory = "images"
    static let sharedInstance = ImageCache()
    
    static let trashIcon = UIImage(named: "cardstats_trash")!
    static let strengthIcon = UIImage(named: "cardstats_strength")!
    static let creditIcon = UIImage(named: "cardstats_credit")!
    static let muIcon = UIImage(named: "cardstats_mem")!
    static let apIcon = UIImage(named: "cardstats_points")!
    static let linkIcon = UIImage(named: "cardstats_link")!
    static let cardIcon = UIImage(named: "cardstats_decksize")!
    static let difficultyIcon = UIImage(named: "cardstats_difficulty")!
    static let influenceIcon = UIImage(named: "cardstats_influence")!
    
    static let hexTile = UIImage(named: "hex_background")!
    static let hexTileLight = UIImage(named: "hex_background_light")!

    static let runnerPlaceholder = UIImage(named: "RunnerPlaceholder")!
    static let corpPlaceholder = UIImage(named: "CorpPlaceholder")!
    
    static func placeholder(for role: Role) -> UIImage {
        return role == .runner ? self.runnerPlaceholder : self.corpPlaceholder
    }

    static let width: CGFloat = 300
    static let height: CGFloat = 418
    
    private static let debugLog = BuildConfig.debug && false
    private static let secondsPerDay = 24 * 60 * 60
    private static let successInterval = TimeInterval(30 * secondsPerDay)
    private static let errorInterval = TimeInterval(1 * secondsPerDay)
    
    private let memCache = ImageMemCache()
    
    // img keys we know aren't downloadable (yet)
    private var unavailableImages = ConcurrentSet<String>()
    
    // Last-Modified date of each image
    private var lastModifiedDates = ConcurrentMap<String, String>() // code -> last-modified
    
    // when to next check if an img was updated
    private var nextCheckDates = ConcurrentMap<String, Date>()      // code -> date

    // log of all current in-flight requests
    typealias ImageCallback = (Card, UIImage, Bool) -> Void
    private var pendingRequests = ConcurrentMap<String, [ImageCallback]>()
    private var queue = DispatchQueue(label: "ImageCache", attributes: .concurrent)

    private init() {
        if let lastMod = Defaults[.lastModifiedCache] {
            self.lastModifiedDates.set(lastMod)
        }
        
        if let nextCheck = Defaults[.nextCheck] {
            self.nextCheckDates.set(nextCheck)
        }
        
        if let imgs = Defaults[.unavailableImages] {
            self.unavailableImages.formUnion(imgs)
        }
        
        let now = Date.timeIntervalSinceReferenceDate
        let lastCheck = Defaults[.unavailableImagesDate] ?? now + 3600.0
        
        if lastCheck < now {
            self.unavailableImages.removeAll()
            Defaults[.unavailableImagesDate] = now + 12 * 3600
            Defaults[.unavailableImages] = self.unavailableImages.array
        }
    }

    private func initializeCache() {
        NSLog("init cache")
        for card in CardManager.allCards() {
            if let img = self.decodedImage(for: card.code) {
                self.memCache[card.code] = img
            }
        }
        NSLog("done")
    }

    /// called when we move to the background
    func resignActive() {
        Defaults[.lastModifiedCache] = self.lastModifiedDates.dict
        Defaults[.nextCheck] = self.nextCheckDates.dict
        Defaults[.unavailableImages] = self.unavailableImages.array
        
        self.memCache.removeAll()
    }
    
    func getImage(for card: Card, completion: @escaping (Card, UIImage, Bool) -> Void) {
        // uncomment to fake "no image available" for all cards
//        if true {
//            completion(card, ImageCache.placeholder(for: card.role), true)
//            return
//        }
        
        let key = card.code
        if let img = self.memCache[key] {
            completion(card, img, false)
            if Reachability.online {
                self.checkForImageUpdate(for: card, key: key)
            }
            return
        }
        
        // if we know we don't (or can't) have an image, return a placeholder immediately
        if unavailableImages.contains(key) || card.imageSrc == nil {
            completion(card, ImageCache.placeholder(for: card.role), true)
            return
        }

        // check if the request is currently in-flight, and if so, add its completion block to our list of callbacks
        let alreadyPending: Bool = self.queue.sync(flags: .barrier) {
            let alreadyPending = self.pendingRequests[key] != nil
            self.pendingRequests[key, default:[]].append(completion)
            return alreadyPending
        }

        if alreadyPending {
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            // get image from our on-disk cache
            if let img = self.decodedImage(for: key) {
                if Reachability.online {
                    self.checkForImageUpdate(for: card, key: key)
                }
                
                self.memCache[key] = img
                self.callCallbacks(for: card, key: key, image: img, placeholder: false)
            } else {
                // image is not in on-disk cache
                if Reachability.online {
                    self.downloadImage(for: card, key: key) { (card, image, placeholder) in
                        self.callCallbacks(for: card, key: key, image: image, placeholder: placeholder)
                    }
                } else {
                    self.callCallbacks(for: card, key: key, image: ImageCache.placeholder(for: card.role), placeholder: true)
                }
            }
        }
    }

    private func callCallbacks(for card: Card, key: String, image: UIImage, placeholder: Bool) {
        DispatchQueue.main.async {
            // call all pending callbacks for this image
            let pendingCallbacks = self.pendingRequests.removeValue(forKey: key)
            assert(pendingCallbacks != nil && pendingCallbacks!.count > 0)
            pendingCallbacks?.forEach { callback in
                callback(card, image, placeholder)
            }
        }
    }
    
    func updateMissingImage(for card: Card, completion: @escaping (Bool) -> Void) {
        if self.getImage(for: card.code) != nil {
            completion(true)
        } else {
            self.updateImage(for: card, completion: completion)
        }
    }
    
    func updateImage(for card: Card, completion: @escaping (Bool) -> Void) {
        guard
            Reachability.online,
            let src = card.imageSrc,
            let url = URL(string: src)
        else {
            completion(false)
            return
        }

        let key = card.code
        
        var request = URLRequest(url:url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 10)
        let lastModDate = self.lastModifiedDates[key]
        if lastModDate != nil {
            request.setValue(lastModDate, forHTTPHeaderField: "If-Modified-Since")
        }
    
        Alamofire
            .request(request)
            .validate()
            .responseImage(imageScale: 1.0) { response in
                if let img = response.result.value {
                    let lastModified = response.response?.allHeaderFields["Last-Modified"] as? String
                    self.NLOG("up: GOT %@ If-Modified-Since %@: status 200", url.absoluteString, lastModified ?? "n/a")
                    self.storeInCache(img, lastModified: lastModified, key: key)
                    completion(true)
                } else {
                    self.NLOG("up: GOT %@ If-Modified-Since %@: status %ld", url.absoluteString, lastModDate ?? "n/a", response.response?.statusCode ?? 999)
                    completion(response.response?.statusCode == 304)
                    if response.response?.statusCode != 304 {
                        self.unavailableImages.insert(card.code)
                    }
                }
            }
    }
    
    func imageAvailable(for card: Card) -> Bool {
        let key = card.code
        
        if self.memCache[key] != nil {
            return true
        }
        
        // if we know we don't (or can't) have an image, return a placeholder immediately
        if self.unavailableImages.contains(key) {
            return false
        }
        
        let dir = self.directoryForImages()
        let file = dir.appendPathComponent(key)
        
        return FileManager.default.fileExists(atPath: file)
    }

    func croppedImage(_ image: UIImage, forCard card: Card) -> UIImage? {
        let key = "\(card.code):crop"
        
        if let cropped = self.memCache[key] {
            return cropped
        }
        
        let rect = CGRect(x: 10.0, y: card.cropY, width: 280.0, height: 209.0)
        if let imageRef = image.cgImage?.cropping(to: rect) {
            let cropped = UIImage(cgImage: imageRef)
            self.memCache[key] = cropped
            return cropped
        }
        return nil
    }
    
    func clearCache() {
        guard BuildConfig.debug else {
            return
        }
        
        self.lastModifiedDates.removeAll()
        self.nextCheckDates.removeAll()
        
        Defaults[.lastModifiedCache] = self.lastModifiedDates.dict
        Defaults[.nextCheck] = self.nextCheckDates.dict

        self.resetUnavailableImages()
        self.removeCacheDirectory()
        URLCache.shared.removeAllCachedResponses()
        
        self.memCache.removeAll()
    }

    func resetUnavailableImages() {
        self.unavailableImages.removeAll()
        Defaults[.unavailableImages] = self.unavailableImages.array
    }
    
    private func NLOG(_ format: String, _ args: CVarArg...) {
        if ImageCache.debugLog {
            let x = String(format: format, arguments: args)
            NSLog(x)
        }
    }
    
    private func storeInCache(_ img: UIImage, lastModified: String?, key: String) {
        var interval = ImageCache.successInterval
        if lastModified != nil {
            self.lastModifiedDates[key] = lastModified!
        } else {
            interval = ImageCache.errorInterval
        }
        
        self.nextCheckDates[key] = Date(timeIntervalSinceNow: interval)
        
        if !self.save(image: img, forKey: key) {
            self.lastModifiedDates.removeValue(forKey: key)
        }
    }
    
    private func save(image: UIImage, forKey key: String) -> Bool {
        let dir = self.directoryForImages()
        let file = dir.appendPathComponent(key)
        
        var img = image
        self.NLOG("save img for %@", key)
        if img.size.width != CGFloat(ImageCache.width) {
            // rescale image to 300x418 and save the scaled-down version
            if let newImg = self.scale(image: img, toSize: CGSize(width: ImageCache.width, height: ImageCache.height)) {
                img = newImg
            }
        }
        
        self.memCache[key] = img
        
        if let data = img.pngData() {
            do {
                try data.write(to: URL(fileURLWithPath: file), options: [.atomic])
                Utils.excludeFromBackup(file)
                return true
            } catch let error {
                self.NLOG("write error \(error)")
            }
        }
        return false
    }
    
    private func scale(image: UIImage, toSize size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        
        image.draw(in: CGRect(x: 0.0, y: 0.0, width: size.width, height: size.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
    
    private func removeCacheDirectory() {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths.first!
        
        let directory = supportDirectory.appendPathComponent(ImageCache.imagesDirectory)
        
        _ = try? FileManager.default.removeItem(atPath: directory)
    }
    
    private func getImage(for key: String) -> UIImage? {
        if let img = self.memCache[key] {
            return img
        }
        
        let img = self.decodedImage(for: key)
        if img != nil {
            self.memCache[key] = img
        }
        return img
    }
    
    private func decodedImage(for key: String) -> UIImage? {
        let dir = self.directoryForImages()
        let file = dir.appendPathComponent(key)

        guard let imgData = try? Data(contentsOf: URL(fileURLWithPath: file)) else {
            self.NLOG("no file for %@", key)
            return nil
        }

        let img = self.decode(image: UIImage(data: imgData))
        let width = img?.size.width ?? 0.0
        // remove images that can't be decoded or that have the wrong size
        if img == nil || width < ImageCache.width - 10 {
            // image is broken - remove it
            self.NLOG("removing broken/small img %@, width=%f", key, width)
            _ = try? FileManager.default.removeItem(atPath: file)
            self.lastModifiedDates.removeValue(forKey: key)
            return nil
        }
        
        return img
    }
    
    private func checkForImageUpdate(for card: Card, key: String) {
        if let checkDate = self.nextCheckDates[key] {
            let now = Date()
            if now.timeIntervalSinceReferenceDate < checkDate.timeIntervalSinceReferenceDate {
                // no need to check
                return
            }
        }
        guard let src = card.imageSrc, let url = URL(string: src) else {
            return
        }

        self.NLOG("check for %@", key)
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData, timeoutInterval: 10)
        let lastModDate = self.lastModifiedDates[key]
        if lastModDate != nil {
            request.setValue(lastModDate, forHTTPHeaderField: "If-Modified-Since")
        }
        
        self.NLOG("GET %@ If-Modified-Since %@", url.absoluteString, lastModDate ?? "n/a")
        Alamofire
            .request(request)
            .validate()
            .responseImage(imageScale: 1.0) { response in
                if let img = response.result.value {
                    self.NLOG("GOT %@ status 200", url.absoluteString)
                    let lastModified = response.response?.allHeaderFields["Last-Modified"] as? String
                    self.storeInCache(img, lastModified: lastModified, key: key)
                } else if response.response?.statusCode == 304 {
                    self.NLOG("GOT %@ status 304", url.absoluteString)
                    self.nextCheckDates[key] = Date(timeIntervalSinceNow: ImageCache.successInterval)
                } else {
                    self.NLOG("GOT %@ failure", url.absoluteString)
                    self.nextCheckDates[key] = Date(timeIntervalSinceNow: ImageCache.errorInterval)
                }
            }
    }
    
    private func downloadImage(for card: Card, key: String, completion: @escaping (Card, UIImage, Bool) -> Void) {
        guard let src = card.imageSrc else {
            let img = ImageCache.placeholder(for: card.role)
            completion(card, img, true)
            return
        }

        Alamofire
            .request(src)
            .validate()
            .responseImage(imageScale: 1.0) { response in
                switch response.result {
                case .success:
                    self.NLOG("dl: GET %@: status 200", src)
                    if let img = response.result.value {
                        completion(card, img, false)
                        let lastModified = response.response?.allHeaderFields["Last-Modified"] as? String
                        self.storeInCache(img, lastModified: lastModified, key: key)
                        self.unavailableImages.remove(key)
                        return
                    }
                    fallthrough
                case .failure:
                    self.NLOG("dl: GET %@ for %@: error %ld", src, card.name, response.response?.statusCode ?? 999)
                    let img = ImageCache.placeholder(for: card.role)
                    completion(card, img, true)
                    self.unavailableImages.insert(key)
                    self.lastModifiedDates.removeValue(forKey: key)
                }
            }
    }
    
    private func directoryForImages() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths.first!
        
        let directory = supportDirectory.appendPathComponent(ImageCache.imagesDirectory)
        
        let fileMgr = FileManager.default
        if !fileMgr.fileExists(atPath: directory) {
            _ = try? fileMgr.createDirectory(atPath: directory, withIntermediateDirectories: true, attributes: nil)
        }
        
        return directory
    }
    
    private func decode(image: UIImage?) -> UIImage? {
        guard let img = image, let imgRef = img.cgImage else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        let width = imgRef.width
        let height = imgRef.height
        if let context = CGContext(data: nil,
                                    width: width,
                                    height: height,
                                    bitsPerComponent: 8, // bits per component
                                    bytesPerRow: width * 4, // Just always return width * 4 will be enough
                                    space: colorSpace, // System only supports RGB, set explicitly
                                    bitmapInfo: bitmapInfo) {

            let rect = CGRect(x: 0, y: 0, width: width, height: height)
            context.draw(imgRef, in: rect)
        
            if let decompressedImageRef = context.makeImage() {
                return UIImage(cgImage: decompressedImageRef, scale: img.scale, orientation: img.imageOrientation)
            }
        }
        return nil
    }
}
