//
//  Card+html.swift
//  NetDeck
//
//  Created by Gereon Steffens on 22.10.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import DTCoreText

extension Card {
    
    @nonobjc static var htmlCache = [String: NSAttributedString]()
    
    @nonobjc static let replacements = [
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

    @nonobjc static let fontFamily = UIFont.systemFont(ofSize: 13).familyName
    @nonobjc static let styleSheet = DTCSSStylesheet(styleBlock:
        ".icon { font-family: 'netrunner' !important; font-style: normal; font-variant: normal; font-weight: normal; line-height: 1; text-transform: none; }")
    
    @nonobjc static let coreTextOptions: [String: Any] = [
        DTUseiOS6Attributes: true,
        DTDefaultFontFamily: NSString(string: fontFamily),
        DTDefaultFontSize: 13,
        DTDefaultStyleSheet: styleSheet!,
    ]

    var attributedText: NSAttributedString {
        if Card.htmlCache[self.code] == nil {
            var str = self.text
            Card.replacements.forEach { code, repl in
                str = str.replacingOccurrences(of: code, with: repl)
            }
            
            let data = str.data(using: String.Encoding.utf8)
            let attrStr = NSAttributedString(htmlData: data, options: Card.coreTextOptions, documentAttributes: nil) ?? NSAttributedString(string: "")
            Card.htmlCache[self.code] = attrStr
        }
        return Card.htmlCache[self.code]!
    }

}
