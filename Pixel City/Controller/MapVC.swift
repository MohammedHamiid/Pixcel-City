//
//  MapVC.swift
//  Pixel City
//
//  Created by Mohamed on 8/23/20.
//  Copyright © 2020 MohamedHamid. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import Alamofire
import AlamofireImage

class MapVC: UIViewController {
    
    var spinner : UIActivityIndicatorView?
    var progressL : UILabel?
    var collectionView : UICollectionView?
    var flowLayout = UICollectionViewFlowLayout()
    
    let screenSize = UIScreen.main.bounds
    
    @IBOutlet weak var pullUpView: UIView!
    @IBOutlet weak var heightView: NSLayoutConstraint!
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager ()
    let authorizationStatus = CLLocationManager.authorizationStatus()
    let regionRaduis : Double = 1000
    
    
    // Var to Network
    var imageUrlArray = [String]()
    var imageArray = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        configerLocationServices()
        addDoubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        pullUpView.addSubview(collectionView!)
       
    }
    
    func addDoubleTap () {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector (dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        mapView.addGestureRecognizer(doubleTap)
    }
    
    @IBAction func centerMapBtn(_ sender: Any) {
        if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
    func animatedViewUp () {
        heightView.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSwip () {
        let swip = UISwipeGestureRecognizer(target: self, action: #selector (anmatedViewDown))
        swip.direction = .down
        pullUpView.addGestureRecognizer(swip)
    }
    
    @objc func anmatedViewDown () {
        cancelAllSessions()
        heightView.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func addSpinner () {
        spinner = UIActivityIndicatorView ()
        spinner?.center = CGPoint(x: (screenSize.width/2) - ((spinner?.frame.width)!/2), y: 150)
        spinner?.color = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        spinner?.style = .large
        spinner?.startAnimating()
        
        collectionView?.addSubview(spinner!)
    }
    
    func removeSpinner() {
        if spinner != nil {
            spinner?.removeFromSuperview()
        }
    }
    
    func addProgressLabel () {
        progressL = UILabel ()
        progressL?.textAlignment = .center
        progressL?.textColor = #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1)
        progressL?.font = UIFont(name: "Avenir Next", size: 15)
        progressL?.text = ""
        progressL?.frame = CGRect(x: (screenSize.width/2) - 125, y: 175, width: 250, height: 40)
        
        collectionView?.addSubview(progressL!)
    }
    
    func removeProgressLbl() {
        if progressL != nil {
            progressL?.removeFromSuperview()
        }
    }
    
    func retriveUrl (forAnnotation annotation : DroppablePin , handler : @escaping (_ status : Bool)->()) {
        Alamofire.request(flickrUrl(forApiKey: apiKey, withAnnotation: annotation, andNumberOfPhotos: 35)) .responseJSON { (response) in
            guard let json = response.result.value as? Dictionary<String, AnyObject> else { return }
            let photosDict = json["photos"] as! Dictionary<String, AnyObject>
            let photosDictArray = photosDict["photo"] as! [Dictionary<String, AnyObject>]
            for photo in photosDictArray {
                let postUrl = "https://live.staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_q_d.jpg"
                self.imageUrlArray.append(postUrl)
            }
            self.collectionView?.reloadData()
            handler(true)
            
        }
    }
    
    func retrieveImages(handler: @escaping (_ status: Bool) -> ()) {
        for url in imageUrlArray {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                guard let image = response.result.value else { return }
                self.imageArray.append(image)
                self.progressL?.text = "\(self.imageArray.count)/35 IMAGES DOWNLOADED"
                
                if self.imageArray.count == self.imageUrlArray.count {
                    handler(true)
                }
            })
        }
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
        }
    }
}




// MARK:- Map View Delegate
extension MapVC : MKMapViewDelegate {
    
    func centerMapOnUserLocation () {
        guard let coordinate = locationManager.location?.coordinate else {return}
        let coordinateRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: regionRaduis , longitudinalMeters: regionRaduis )
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    // custom color pin
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "droppablePin")
        pinAnnotation.pinTintColor = .orange
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    @objc func dropPin (sender : UITapGestureRecognizer) {
        // before add pin remove all pins
        removeAnnotations()
        removeSpinner()
        removeProgressLbl()
        cancelAllSessions()
        
        imageUrlArray = []
        imageArray = []
        
        collectionView?.reloadData()
        
        animatedViewUp()
        addSwip()
        addSpinner()
        addProgressLabel()
        
        let touchPiont = sender.location(in: mapView)
        // transilate point in view to coordinate
        let touchCoordinate = mapView.convert(touchPiont, toCoordinateFrom: mapView)
        
        let annotation = DroppablePin(coordinate: touchCoordinate, identifire: "droppablePin")
        mapView.addAnnotation(annotation)
        
        // to show pin in center map view
        let coordinateRegion = MKCoordinateRegion(center: touchCoordinate, latitudinalMeters: regionRaduis , longitudinalMeters: regionRaduis )
        mapView.setRegion(coordinateRegion, animated: true)
        
        retriveUrl(forAnnotation: annotation) { (finished) in
            if finished {
                self.retrieveImages { (finished) in
                    if finished {
                        if finished {
                            self.removeSpinner()
                            self.removeProgressLbl()
                            self.collectionView?.reloadData()
                        }
                    }
                }
            }
        }
    }
    
    
    func removeAnnotations () {
        for annotations in mapView.annotations {
            mapView.removeAnnotation(annotations)
        }
    }
}





// MARK:- Location Manager
extension MapVC : CLLocationManagerDelegate {
    
    func configerLocationServices () {
        if authorizationStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        }else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        centerMapOnUserLocation()
    }
}





//MARK:- CollectionView Delegate
extension MapVC : UICollectionViewDataSource , UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageArray.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageFromIndex = imageArray[indexPath.row]
        let imageView = UIImageView(image: imageFromIndex)
        cell.addSubview(imageView)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(identifier: "PopVC") as? PopVC else {return}
        popVC.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        popVC.modalTransitionStyle = UIModalTransitionStyle.coverVertical
        popVC.passImage = imageArray[indexPath.row]
        present(popVC, animated: true, completion: nil)
    }
    
}
