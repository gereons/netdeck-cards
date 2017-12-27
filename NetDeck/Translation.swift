//
//  Translation.swift
//  NetDeck
//
//  Created by Gereon Steffens on 04.06.16.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import Foundation

class Translation {
    static func forTerm(_ term: String, language: String) -> String {
        return data[language]?[term] ?? term.capitalized
    }
    
    private static let data = [
        "en": [
            "adam": "Adam",
            "anarch": "Anarch",
            "apex": "Apex",
            "criminal": "Criminal",
            "haas-bioroid": "Haas-Bioroid",
            "jinteki": "Jinteki",
            "nbn": "NBN",
            "neutral": "Neutral",
            "neutral-runner": "Neutral",
            "neutral-corp": "Neutral",
            "shaper": "Shaper",
            "sunny-lebeau": "Sunny Lebeau",
            "weyland-consortium": "Weyland",
            "agenda": "Agenda",
            "asset": "Asset",
            "event": "Event",
            "hardware": "Hardware",
            "ice": "ICE",
            "identity": "Identity",
            "operation": "Operation",
            "program": "Program",
            "resource": "Resource",
            "upgrade": "Upgrade",
            "runner": "Runner",
            "corp": "Corp"
        ],
        "de": [
            "adam": "Adam",
            "anarch": "Anarchos",
            "apex": "Apex",
            "criminal": "Kriminelle",
            "haas-bioroid": "Haas-Bioroid",
            "jinteki": "Jinteki",
            "nbn": "NBN",
            "neutral": "Neutral",
            "neutral-runner": "Neutral",
            "neutral-corp": "Neutral",
            "shaper": "Gestalter",
            "sunny-lebeau": "Sunny Lebeau",
            "weyland-consortium": "Weyland",
            "agenda": "Agenda",
            "asset": "Aktivposten",
            "event": "Ereignis",
            "hardware": "Hardware",
            "ice": "ICE",
            "identity": "Identität",
            "operation": "Operation",
            "program": "Programm",
            "resource": "Ressource",
            "upgrade": "Upgrade",
            "runner": "Runner",
            "corp": "Kon"
        ],
        "es": [
            "adam": "Adam",
            "anarch": "Anarchistas",
            "apex": "Apex",
            "criminal": "Delincuentes",
            "haas-bioroid": "Haas-Bioroid",
            "jinteki": "Jinteki",
            "nbn": "NBN",
            "neutral": "Neutrales",
            "neutral-runner": "Neutrales",
            "neutral-corp": "Neutrales",
            "shaper": "Moldeadores",
            "sunny-lebeau": "Sunny Lebeau",
            "weyland-consortium": "Weyland",
            "agenda": "Plan",
            "asset": "Ventaja",
            "event": "Evento",
            "hardware": "Hardware",
            "ice": "Hielo",
            "identity": "Identidad",
            "operation": "Operación",
            "program": "Programa",
            "resource": "Recurso",
            "upgrade": "Mejora",
            "runner": "Runner",
            "corp": "Corporación"
        ],
        "fr": [
            "adam": "Adam",
            "anarch": "Anarch",
            "apex": "Apex",
            "criminal": "Criminel",
            "haas-bioroid": "Haas-Bioroid",
            "jinteki": "Jinteki",
            "nbn": "NBN",
            "neutral": "Neutre",
            "neutral-runner": "Neutre",
            "neutral-corp": "Neutre",
            "shaper": "Façonneur",
            "sunny-lebeau": "Sunny Lebeau",
            "weyland-consortium": "Weyland",
            "agenda": "Projet",
            "asset": "Avoir",
            "event": "Événement",
            "hardware": "Matériel",
            "ice": "Glace",
            "identity": "Identité",
            "operation": "Opération",
            "program": "Programme",
            "resource": "Ressource",
            "upgrade": "Extension",
            "runner": "Runner",
            "corp": "Corpo"
        ],
        "it": ["adam": "Adam",
            "anarch": "Anarchici",
            "apex": "Apex",
            "criminal": "Criminali",
            "haas-bioroid": "Haas-Bioroid",
            "jinteki": "Jinteki",
            "nbn": "NBN",
            "neutral": "Neutrali",
            "neutral-runner": "Neutrali",
            "neutral-corp": "Neutrali",
            "shaper": "Modellatori",
            "sunny-lebeau": "Sunny Lebeau",
            "weyland-consortium": "Weyland",
            "agenda": "Obiettivo",
            "asset": "Asset",
            "event": "Evento",
            "hardware": "Hardware",
            "ice": "Ghiaccio",
            "identity": "Identita",
            "operation": "Operazione",
            "program": "Programma",
            "resource": "Risorsa",
            "upgrade": "Aggiornamento",
            "runner": "Runner",
            "corp": "Corporazione"
        ],
        "jp": [
            "adam": "Adam",
            "anarch": "アナーク",
            "apex": "Apex",
            "criminal": "クリミナル",
            "haas-bioroid": "ハース＝バイオロイド",
            "jinteki": "ジンテキ",
            "nbn": "NBN",
            "neutral": "中立",
            "neutral-runner": "中立",
            "neutral-corp": "中立",
            "shaper": "シェイパー",
            "sunny-lebeau": "Sunny Lebeau",
            "weyland-consortium": "ウェイランド・コンソーシアム",
            "agenda": "計画書",
            "asset": "資財",
            "event": "イベント",
            "hardware": "ハードウェア",
            "ice": "アイス",
            "identity": "ID",
            "operation": "任務",
            "program": "プログラム",
            "resource": "リソース",
            "upgrade": "強化",
            "runner": "ランナー",
            "corp": "コーポ"
        ],
        "pl": [
            "adam": "Adam",
            "anarch": "Anarchowie",
            "apex": "Apex",
            "criminal": "Przestępcy",
            "haas-bioroid": "Haas-Bioroid",
            "jinteki": "Jinteki",
            "nbn": "NBN",
            "neutral": "Neutralne",
            "neutral-runner": "Neutralne",
            "neutral-corp": "Neutralne",
            "shaper": "Kształcerze",
            "sunny-lebeau": "Sunny Lebeau",
            "weyland-consortium": "Weyland",
            "agenda": "Projekt",
            "asset": "Aktywa",
            "event": "Wydarzenie",
            "hardware": "Sprzęt",
            "ice": "Lód",
            "identity": "Tożsamość",
            "operation": "Operacja",
            "program": "Program",
            "resource": "Zasób",
            "upgrade": "Upgrade",
            "runner": "Runner",
            "corp": "Korp"
        ],
        "zh": [
            "adam": "亚当",
            "anarch": "反叛者",
            "apex": "尖峰",
            "criminal": "逆法者",
            "haas-bioroid": "哈斯生化",
            "jinteki": "人间会社",
            "nbn": "网际传媒",
            "neutral": "中立",
            "neutral-runner": "中立",
            "neutral-corp": "中立",
            "shaper": "塑造者",
            "sunny-lebeau": "桑妮·勒博",
            "weyland-consortium": "威兰财团",
            "agenda": "议案",
            "asset": "资产",
            "event": "事件",
            "hardware": "硬件",
            "ice": "防火墙",
            "identity": "特性",
            "operation": "事务",
            "program": "程序",
            "resource": "资源",
            "upgrade": "升级",
            "runner": "潜袭者",
            "corp": "公司"
        ],
        "kr": [
            "adam": "아담",
            "anarch": "아나크",
            "apex": "에이팩스",
            "criminal": "크리미널",
            "haas-bioroid": "하스바이오로이드",
            "jinteki": "진테키",
            "nbn": "NBN",
            "neutral": "중립",
            "neutral-runner": "중립",
            "neutral-corp": "중립",
            "shaper": "셰이퍼",
            "sunny-lebeau": "서니르뷰",
            "weyland-consortium": "웨이랜드컨소시엄",
            "agenda": "아젠다",
            "asset": "자산",
            "event": "이벤트",
            "hardware": "하드웨어",
            "ice": "아이스",
            "identity": "ID",
            "operation": "운영",
            "program": "프로그램",
            "resource": "리소스",
            "upgrade": "개선",
            "corp": "기업",
            "runner": "러너"
        ]
    ]
}