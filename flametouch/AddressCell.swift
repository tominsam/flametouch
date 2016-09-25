//
//  AddressCell.swift
//  Flame
//
//  Created by tominsam on 9/24/16.
//  Copyright © 2016 tominsam. All rights reserved.
//

import Foundation
import UIKit

class AddressCell : UITableViewCell {
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder : NSCoder) {
        super.init(coder: coder)
        // don't ever want this to be called.
        precondition(false)
    }
}
