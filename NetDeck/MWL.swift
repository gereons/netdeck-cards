//
//  MWL.swift
//  NetDeck
//
//  Created by Gereon Steffens on 09.03.19.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import Foundation

struct MostWantedList {
    let code: String
    let name: String

    let universalInfluence: Bool
    let active: Bool
    let penalties: [String: Int]?
    let banned: Set<String>?
    let restricted: Set<String>?

    init(data: NetrunnerDbMwl) {
        self.code = data.code
        self.name = data.name
        self.active = data.active

        var penalties = [String: Int]()
        var banned = Set<String>()
        var restricted = Set<String>()
        var universalInfluence = false

        for (code, restriction) in data.cards {
            if let penalty = restriction.globalPenalty {
                penalties[code] = penalty
            } else if let penalty = restriction.universalFactionCost {
                penalties[code] = penalty
                universalInfluence = true
            }

            if let deckLimit = restriction.deckLimit, deckLimit == 0 {
                banned.insert(code)
            }
            if let isRestricted = restriction.isRestricted, isRestricted == 1 {
                restricted.insert(code)
            }
        }

        self.universalInfluence = universalInfluence
        self.penalties = penalties.count == 0 ? nil : penalties
        self.banned = banned.count == 0 ? nil : banned
        self.restricted = restricted.count == 0 ? nil : restricted
    }

    private init() {
        self.code = ""
        self.name = "Casual".localized()

        self.universalInfluence = true
        self.active = false
        self.penalties = nil
        self.banned = nil
        self.restricted = nil
    }

    static let casual = MostWantedList()
}

class MWLManager {

    private static var mwls = [MostWantedList]()

    static func setup(_ mwldata: [NetrunnerDbMwl]) {
        mwls = mwldata
                .sorted { $0.date_start < $1.date_start }
                .map { MostWantedList(data: $0) }

        mwls.insert(MostWantedList.casual, at: 0)

        print("mwl initialized")
    }

    static var activeMWL: Int {
        let index = mwls.firstIndex(where: { $0.active })
        return index ?? 0
    }

    static func settingsValues() -> [Int] {
        return Array(0 ..< mwls.count)
    }

    static func settingsTitles() -> [String] {
        return mwls.map { $0.active ? $0.name + " (Active)".localized() : $0.name }
    }

    static func mwlBy(_ code: String) -> Int {
        let index = mwls.firstIndex { $0.code == code }
        return index ?? 0
    }

    static func mwlBy(_ index: Int) -> MostWantedList {
        let index = min(mwls.count - 1, index)
        return mwls[index]
    }

    static var firstStandardIndex: Int {
        let index = mwls.firstIndex { $0.code.hasPrefix("standard") }
        return index ?? 0
    }

    static var count: Int {
        return mwls.count
    }

    // MARK: - persistence

    static let filename = "mwl.json"

    private static func mwlPathname() -> String {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let supportDirectory = paths[0]

        return supportDirectory.appendPathComponent(MWLManager.filename)
    }

    static func fileExists() -> Bool {
        let fm = FileManager.default
        return fm.fileExists(atPath: mwlPathname())
    }

    static func removeFile() {
        let fileMgr = FileManager.default
        _ = try? fileMgr.removeItem(atPath: mwlPathname())
    }

    static func setupFromFiles() -> Bool {
        let mwlFile = mwlPathname()
        let fileMgr = FileManager.default

        if !fileMgr.fileExists(atPath: mwlFile) {
            // copy the file from our bundle
            if let bundlePath = Bundle.main.path(forResource: "mwl", ofType: "json") {
                do {
                    try fileMgr.copyItem(atPath: bundlePath, toPath: mwlFile)
                } catch {
                    print(error)
                }
            }
        }

        if let mwlData = fileMgr.contents(atPath: mwlFile) {
            return setupFromJsonData(mwlData)
        }

        print("app start: missing mwl file")
        return false
    }

    static func setupFromNetrunnerDb(_ mwlData: Data) -> Bool {
        let ok = setupFromJsonData(mwlData)
        if !ok {
            return false
        }

        do {
            let mwlFile = self.mwlPathname()
            try mwlData.write(to: URL(fileURLWithPath: mwlFile), options: .atomic)
            Utils.excludeFromBackup(mwlFile)
        }
        catch let error {
            print("\(error)")
        }

        return ok
    }

    static func setupFromJsonData(_ mwlData: Data) -> Bool {
        do {
            let decoder = JSONDecoder()
            let rawMwl = try decoder.decode(ApiResponse<NetrunnerDbMwl>.self, from: mwlData)
            if !rawMwl.valid {
                return false
            }

            MWLManager.setup(rawMwl.data)

            UserDefaults.standard.registerDefault(.defaultMWL, MWLManager.activeMWL)
        } catch let error {
            print("\(error)")
            return false
        }
        return true
    }

}
