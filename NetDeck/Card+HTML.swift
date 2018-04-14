//
//  Card+html.swift
//  NetDeck
//
//  Created by Gereon Steffens on 22.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

extension Card {

    static private(set) var htmlCache = [String: NSAttributedString]()
    
    static let replacements = [
        "\n": "<br/>",
        "[subroutine]": "<span class='icon'>\u{e900}</span>",
        "[trash]": "<span class='icon'>\u{e905}</span>",
        "[click]": "<span class='icon'>\u{e909}</span>",
        "[credit]": "<span class='icon'>\u{e90b}</span>",
        "[recurring-credit]": "<span class='icon'>\u{e90a}</span>",
        "[link]": "<span class='icon'>\u{e908}</span>",
        "[mu]": "<span class='icon'>\u{e904}</span>",
        "[anarch]": "<span class='icon'>\u{e91a}</span>",
        "[criminal]": "<span class='icon'>\u{e919}</span>",
        "[shaper]": "<span class='icon'>\u{e91b}</span>",
        "[jinteki]": "<span class='icon'>\u{e916}</span>",
        "[haas-bioroid]": "<span class='icon'>\u{e918}</span>",
        "[nbn]": "<span class='icon'>\u{e915}</span>",
        "[weyland-consortium]": "<span class='icon'>\u{e917}</span>",
        "[adam]": "<span class='icon'>\u{e91d}</span>",
        "[apex]": "<span class='icon'>\u{e91e}</span>",
        "[sunny-lebeau]": "<span class='icon'>\u{e91c}</span>",
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
