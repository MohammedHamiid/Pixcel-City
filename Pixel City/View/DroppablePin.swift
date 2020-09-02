//
//  DroppablePin.swift
//  Pixel City
//
//  Created by Mohamed on 8/24/20.
//  Copyright © 2020 MohamedHamid. All rights reserved.
//

import UIKit
import MapKit


class DroppablePin : NSObject , MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var identifire : String
    
    init(coordinate : CLLocationCoordinate2D , identifire : String ) {
        self.coordinate = coordinate
        self.identifire = identifire
    }
}
