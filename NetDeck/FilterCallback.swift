//
//  FilterCallback.swift
//  NetDeck
//
//  Created by Gereon Steffens on 22.01.17.
//  Copyright © 2017 Gereon Steffens. All rights reserved.
//

import UIKit

protocol FilterCallback: class {

    // -(void) filterCallback:(UIButton*)button type:(NSString*)type value:(id)value;
    
    func filterCallback(_ button: UIButton, type: String, value: Any)

}
