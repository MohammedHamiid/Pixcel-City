//
//  PopVC.swift
//  Pixel City
//
//  Created by Mohamed on 8/26/20.
//  Copyright © 2020 MohamedHamid. All rights reserved.
//

import UIKit

class PopVC: UIViewController  {

    var passImage : UIImage!
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = passImage
        doubleTap()
    }

    func doubleTap (){
        let gesture = UITapGestureRecognizer(target: self, action: #selector(viewDoubleTap))
        gesture.numberOfTapsRequired = 2
        view.addGestureRecognizer(gesture)
    }
    
   @objc func viewDoubleTap () {
        dismiss(animated: true, completion: nil)
    }
}
