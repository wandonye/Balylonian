//
//  TopTabBar.swift
//  app
//
//  Created by Dongning Wang on 11/13/15.
//  Copyright © 2015 KZ. All rights reserved.
//

import UIKit

class TopTabBar: UITabBar {

    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

    override func sizeThatFits(size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        sizeThatFits.height = 64
        
        return sizeThatFits
    }
}
