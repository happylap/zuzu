//
//  MapViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {
    var houseAddres: String?
    var houseTitle: String?
    var coordinate: (latitude: CLLocationDegrees, longitude: CLLocationDegrees)?
    
    private let locationManager = CLLocationManager()
    
    //@IBOutlet weak var closeMapButton: UIButton!
    @IBOutlet weak var mapView: GMSMapView!
    
    func onCloseMapButtonTouched(sender: UIButton) {
        //self.dismissViewControllerAnimated(true, completion: nil)
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //closeMapButton.addTarget(self, action: "onCloseMapButtonTouched:", forControlEvents: UIControlEvents.TouchUpInside)
        
        let status = CLLocationManager.locationServicesEnabled()
        let authStatus = CLLocationManager.authorizationStatus()
        
        NSLog("%@, %d", status, authStatus.rawValue)
        
        if status {
            if authStatus == CLAuthorizationStatus.AuthorizedWhenInUse {
                mapView.myLocationEnabled = true
                mapView.settings.myLocationButton = true
            }
        }
        
        if let coordinate = coordinate {
            //locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            
            let camera = GMSCameraPosition.cameraWithLatitude(coordinate.latitude,
                longitude: coordinate.longitude, zoom: 16)
            
            mapView.camera = camera
            mapView.settings.compassButton = true
            
            
            let marker = GMSMarker()
            marker.position = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude)
            marker.icon = GMSMarker.markerImageWithColor(UIColor.colorWithRGB(0x1CD4C6))
            marker.title = houseTitle ?? "租屋地點"
            marker.snippet = houseAddres ?? "無住址"
            marker.map = mapView
            
            mapView.selectedMarker = marker
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        ///Hide tab bar
        self.tabBarController!.tabBarHidden = true
        
        ///Google Analytics Tracker
        self.trackScreen()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        ///Display tab bar
        self.tabBarController!.tabBarHidden = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}

extension MapViewController : CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            mapView.myLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            
            mapView.camera = GMSCameraPosition(target: location.coordinate, zoom: 16, bearing: 0, viewingAngle: 0)
            
            locationManager.stopUpdatingLocation()
        }
        
    }
}
