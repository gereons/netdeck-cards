//
//  Rotation.swift
//  NetDeck
//
//  Created by Gereon Steffens on 02.08.20.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

struct RotatedPacks: Equatable {
    let packs: Set<String>
    let cycles: [String]

    fileprivate init(_ data: RotationData) {
        self.packs = Set(data.packs)
        self.cycles = data.cycles
    }

    static let empty = RotatedPacks(RotationData(code: "none", name: "none", cycles: [], packs: [], dateStart: nil))
}

final class RotationManager {

    static let r2017 = 0
    static let r2018 = 1
    static let r2019 = 2
    static let r2021 = 3

    private static var rotations = [RotatedPacks]()
    private(set) static var settingsValues = [Int]()
    private(set) static var settingsTitles = [String]()

    static func setup(_ data: [RotationData]) {
        self.rotations = data.map { RotatedPacks($0) }

        self.settingsValues = Array(rotations.indices).reversed()
        self.settingsTitles = data.map { $0.name }.reversed()

        var rotationIndex = self.rotations.count - 1
        let now = Date()
        if let index = data.lastIndex(where: { $0.dateStart != nil && $0.dateStart! < now }) {
            rotationIndex = index
        }

        Defaults.registerDefault(.rotationIndex, rotationIndex)
        print("rotations initialized")
    }

    static var rotatedPacks: RotatedPacks {
        let index = Defaults[.rotationIndex]
        if Self.settingsValues.contains(index) {
            return Self.rotations[index]
        }
        return RotatedPacks.empty
    }

    // MARK: - persistence

    static let filename = "rotations.json"

    private static func rotationsPathname() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]

        return supportDirectory.appendPathComponent(RotationManager.filename)
    }

    static func fileExists() -> Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: rotationsPathname())
    }

    static func removeFile() {
        let fileMgr = FileManager.default
        _ = try? fileMgr.removeItem(atPath: rotationsPathname())
    }

    static func setupFromFiles() -> Bool {
        let rotationFile = rotationsPathname()
        let fileMgr = FileManager.default

        if !fileMgr.fileExists(atPath: rotationFile) {
            // copy the file from our bundle
            if let bundlePath = Bundle.main.path(forResource: "rotations", ofType: "json") {
                do {
                    try fileMgr.copyItem(atPath: bundlePath, toPath: rotationFile)
                } catch {
                    print(error)
                }
            }
        }

        if let rotationData = fileMgr.contents(atPath: rotationFile) {
            return setupFromJsonData(rotationData)
        }

        print("app start: missing rotations file")
        return false
    }

    static func setupFromNetrunnerDb(_ rotationData: Data) -> Bool {
        let ok = setupFromJsonData(rotationData)
        if !ok {
            return false
        }

        do {
            let rotationFile = self.rotationsPathname()
            try rotationData.write(to: URL(fileURLWithPath: rotationFile), options: .atomic)
            Utils.excludeFromBackup(rotationFile)
        }
        catch let error {
            print("\(error)")
        }

        return ok
    }

    static func setupFromJsonData(_ rotationData: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            let rotations = try decoder.decode([RotationData].self, from: rotationData)

            RotationManager.setup(rotations)
        } catch let error {
            print("\(error)")
            return false
        }
        return true
    }

}
