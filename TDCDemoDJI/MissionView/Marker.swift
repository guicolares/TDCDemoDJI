//
//  Marker.swift
//  TDCDemoDJI
//
//  Created by Guilherme Leite Colares on 06/12/22.
//

import UIKit
import MapKit

final class Marker: UIView {
    var imageView: UIImageView!
    var coordinate: CLLocationCoordinate2D! {
        didSet {
            let mapview = superview as! MKMapView
            self.center = mapview.convert(self.coordinate, toPointTo: mapview)
            superview?.bringSubviewToFront(self)
        }
    }
    
    var heading: Double! {
        didSet {
            self.transform = CGAffineTransform.identity
            self.transform = CGAffineTransform(rotationAngle: CGFloat(self.heading))
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("Use init(fillColor:, strokeColor:)")
    }
    
    init(_ imageName: String, _ coordinate: CLLocationCoordinate2D? = nil, _ heading: Double? = nil ) {
        super.init(frame:CGRect(x: 0, y: 0, width: 10.0, height: 10.0))
        self.backgroundColor = UIColor.clear
        
        self.imageView = UIImageView(image: UIImage(named: imageName))
        self.imageView.center = self.center
        self.addSubview(self.imageView)
        self.backgroundColor = UIColor.clear
        
        if coordinate != nil {
            self.coordinate = coordinate!
        }
        
        if heading != nil {
            self.heading = heading!
        }
    }
    
    override func didMoveToSuperview() {
        self.updateFrame()
        superview?.bringSubviewToFront(self)
    }
    
    override func draw(_ rect: CGRect){
        super.draw(rect)
    }
    
    func getMapPoint() -> MKMapPoint{
        return MKMapPoint(self.coordinate)
    }
    
    func getViewPoint() -> CGPoint{
        return self.frame.origin
    }
    
    func getLocation() -> CLLocation {
        return CLLocation(latitude: self.coordinate.latitude, longitude: self.coordinate.longitude)
    }
    
    func hide(){
        self.isHidden = true
    }
    
    func show(){
        self.isHidden = false
    }
    
    func updateFrame(){
        if self.coordinate != nil && superview != nil  {
            let mapview = superview as! MKMapView
            self.center = mapview.convert(self.coordinate, toPointTo: mapview)
            superview?.bringSubviewToFront(self)
        }
    }
    
    
    
}

