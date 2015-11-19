//
//  MapViewController.swift
//  Zuzu
//
//Copyright © LAP Inc. All rights reserved
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {
    
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
            marker.title = houseTitle ?? "租屋地點"
            marker.snippet = "Taiwan"
            marker.map = mapView
        }
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