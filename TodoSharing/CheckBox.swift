//
//  CheckBox.swift
//  TodoSharing
//
//  Created by 原涼馬 on 2021/12/16.
//

import UIKit

class CheckBox: UIButton {
    // Images
    let checkedImage = UIImage(systemName: "checkmark.circle")! as UIImage
    let uncheckedImage = UIImage(systemName: "circle")! as UIImage

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 50
    }
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // Bool property
    var isChecked: Bool = false {
        didSet{
            if isChecked {
                self.setImage(checkedImage, for: UIControl.State.normal)
            } else {
                self.setImage(uncheckedImage, for: UIControl.State.normal)
            }
        }
    }

    override func awakeFromNib() {
        self.addTarget(self, action:#selector(buttonClicked(sender:)), for: UIControl.Event.touchUpInside)
        self.isChecked = false
    }

    @objc func buttonClicked(sender: UIButton) {
        if sender == self {
            isChecked = !isChecked
        }
    }
}
