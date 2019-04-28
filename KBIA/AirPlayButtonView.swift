//
//  AirPlayButtonView.swift
//  SwiftRadio
//
//  Created by Nathan Lawrence on 4/28/19.
//  Copyright © 2019 nathanlawrence.org. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit

@IBDesignable
class AirPlayButtonView: UIView {
    //----------------------
    //Constructors, Initializers, and UIView lifecycle
    //--------------
    override init(frame: CGRect) {
        super.init(frame: frame)
        didLoad()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        didLoad()
    }
    
    convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    }
    
    func didLoad() {
        //Place your initialization code here
        
        let AirPlayButton = AVRoutePickerView(frame: CGRect(x:0, y:0, width:self.frame.width, height:self.frame.height))
        AirPlayButton.tintColor = .white
        self.addSubview(AirPlayButton)
        self.backgroundColor = .clear
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        //Custom manually positioning layout goes here (auto-layout pass has already run first pass)
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        //Disable this if you are adding constraints manually
        //or you're going to have a 'bad time'
        //self.translatesAutoresizingMaskIntoConstraints = false
        
        //Add custom constraint code here
    }
}
