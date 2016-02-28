//
//  SmartTableViewCell.swift
//  SmartMirror
//
//  Created by Julien Saad on 2016-02-28.
//  Copyright © 2016 Julien Saad. All rights reserved.
//

import UIKit

enum SmartType {
    case Calendar
    case Headline
    
    var image: UIImage {
        switch self {
            case .Calendar:
                return UIImage(named: "calendar")!
            case .Headline:
                return UIImage(named: "newspaper")!
        }
    }
    
}

class SmartTableViewCell: UITableViewCell {

   
    @IBOutlet weak var iconImageView: UIImageView!
    
    var type: SmartType = .Calendar {
        didSet {
            updateType()
        }
    }
    
    func updateType() {
        switch type {
        case .Calendar:
            iconImageView.image = type.image
        case .Headline:
            iconImageView.image = type.image
        }
        
        iconImageView.tintColor = UIColor.whiteColor()
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        iconImageView.tintColor = UIColor.whiteColor()
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
