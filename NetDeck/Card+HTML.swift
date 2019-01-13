//
//  Card+html.swift
//  NetDeck
//
//  Created by Gereon Steffens on 22.10.16.
//  Copyright © 2019 Gereon Steffens. All rights reserved.
//

import Foundation

extension Card {

    static private(set) var htmlCache = [String: NSAttributedString]()

    static let replacements = [
        "\n": "<br/>",
        "[subroutine]": "<span class='icon'>\(Symbols.subroutine.rawValue)</span>",
        "[trash]": "<span class='icon'>\(Symbols.trash.rawValue)</span>",
        "[click]": "<span class='icon'>\(Symbols.click.rawValue)</span>",
        "[credit]": "<span class='icon'>\(Symbols.credit.rawValue)</span>",
        "[recurring-credit]": "<span class='icon'>\(Symbols.recurringCredit.rawValue)</span>",
        "[link]": "<span class='icon'>\(Symbols.link.rawValue)</span>",
        "[mu]": "<span class='icon'>\(Symbols.mu.rawValue)</span>",
        "[anarch]": "<span class='icon'>\(Symbols.anarch.rawValue)</span>",
        "[criminal]": "<span class='icon'>\(Symbols.criminal.rawValue)</span>",
        "[shaper]": "<span class='icon'>\(Symbols.shaper.rawValue)</span>",
        "[jinteki]": "<span class='icon'>\(Symbols.jinteki.rawValue)</span>",
        "[haas-bioroid]": "<span class='icon'>\(Symbols.haasBioroid.rawValue)</span>",
        "[nbn]": "<span class='icon'>\(Symbols.nbn.rawValue)</span>",
        "[weyland-consortium]": "<span class='icon'>\(Symbols.weylandConsortium.rawValue)</span>",
        "[adam]": "<span class='icon'>\(Symbols.adam.rawValue)</span>",
        "[apex]": "<span class='icon'>\(Symbols.apex.rawValue)</span>",
        "[sunny-lebeau]": "<span class='icon'>\(Symbols.sunnyLebeau.rawValue)</span>",
        "<errata>": "<em>",
        "</errata>": "</em>",
        "<trace>": "<strong>",
        "</trace>": "</strong>-"
    ]

    var attributedText: NSAttributedString {
        if let str = Card.htmlCache[self.code] {
            return str
        }

        var str = self.text
        Card.replacements.forEach { code, repl in
            str = str.replacingOccurrences(of: code, with: repl)
        }

        str = """
        <style type="text/css">
        * { font-family: apple-system,sans-serif; font-size: 110%; }
        .icon { font-family: 'netrunner' !important; font-style: normal; font-variant: normal; font-weight: normal; line-height: 1; text-transform: none; }
        </style>
        """ + str

        let attrStr = NSAttributedString(html: str) ?? NSAttributedString(string: self.text)
        Card.htmlCache[self.code] = attrStr
        return attrStr
    }
}

fileprivate extension NSAttributedString {
    convenience init?(html: String) {
        guard let data = html.data(using: String.Encoding.utf16, allowLossyConversion: false) else {
            return nil
        }

        guard let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: String.Encoding.utf8.rawValue], documentAttributes: nil) else {
            return nil
        }

        self.init(attributedString: attributedString)
    }
}
