//
//  AirPlayButtonViewController.swift
//  SwiftRadio
//
//  Created by Nathan Lawrence on 4/28/19.
//  Copyright © 2019 nathanlawrence.org. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import AVKit

class AirPlayButtonViewController:UIViewController{
    var AirPlayButton:AVRoutePickerView!
    
    override func loadView() {
        let view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = .white
        AirPlayButton = AVRoutePickerView(frame: CGRect(x:50, y:50, width:100, height:100))
        view.addSubview(AirPlayButton)
        self.view = view
    }
}
