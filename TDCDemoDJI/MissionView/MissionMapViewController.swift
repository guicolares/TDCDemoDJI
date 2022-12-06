//
//  MissionMapViewController.swift
//  TDCDemoDJI
//
//  Created by Guilherme Leite Colares on 04/12/22.
//

import UIKit
import DJISDK
import MapKit

final class MissionMapViewController: UIViewController {
    
    // MARK: IBOutlets
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var mapView: MKMapView!
    @IBOutlet private weak var startStopMissionButton: UIButton!
    @IBOutlet private weak var clearButton: UIButton!
    @IBOutlet private weak var currentAltitudeLabel: UILabel!
    @IBOutlet private weak var prepareMissionButton: UIButton!
    @IBOutlet private weak var altitudeControl: UISegmentedControl!
    
    // MARK: Properties
    private let locationManager = CLLocationManager()
    private var coordinatesToGo: [CLLocationCoordinate2D] = []
    
    private var started = false
    private var link: CADisplayLink = .init()
    
    private var droneMarker: Marker?
    private var homeLocationMarker: Marker?
    
    private lazy var flightController: DJIFlightController? = {
        DroneService.shared.connectedProduct?.flightController
    }()

    // MARK: Life
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocationManager()
        setupMapView()
        bindMissionControl()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        flightController?.delegate = self
    }
    
    private func bindMissionControl() {
        DJISDKManager.missionControl()?.addListener(self, toTimelineProgressWith: { (event: DJIMissionControlTimelineEvent, element: DJIMissionControlTimelineElement?, error: Error?, info: Any?) in
            
            switch event {
            case .started:
                self.didStart()
            case .stopped:
                self.didStop()
            case .paused: break
            case .resumed: break
            case .finished:
                self.didFinished()
            default:
                break
            }
        })
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        // Request a user’s location once
        locationManager.requestLocation()
        
        locationManager.startUpdatingLocation()
    }
    
    private func setupMapView() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.handleTap(_:)))
        mapView.addGestureRecognizer(tap)
        mapView.delegate = self
        
        link = CADisplayLink(target: self,
                                  selector: #selector(MissionMapViewController.updateViewsBasedOnMapRegion(_:)))
        link.isPaused = true
        link.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
    }
    
    @objc func handleTap(_ sender: UITapGestureRecognizer? = nil) {
        guard let locationGesture = sender?.location(in: mapView) else { return }
        let coordinate = mapView.convert(locationGesture, toCoordinateFrom: mapView)
        
        coordinatesToGo.append(coordinate)
        
        let point = MKPointAnnotation()
        point.title = "Waypoint"
        point.coordinate = coordinate
        
        mapView.addAnnotation(point)
    }
    
    @objc func updateViewsBasedOnMapRegion(_ link: CADisplayLink){
        droneMarker?.updateFrame()
        homeLocationMarker?.updateFrame()
    }
    
    private func getAltitudeSelected() -> Float {
        altitudeControl.selectedSegmentIndex == 0 ? 10 : 20
    }
    
    private func didStart() {
        started = true
        DispatchQueue.main.async {
            self.startStopMissionButton.setTitle("Stop Mission", for: .normal)
            self.prepareMissionButton.isHidden = true
            self.infoLabel.text = "In Mission"
        }
    }
    
    private func didStop() {
        started = false
        DispatchQueue.main.async {
            self.startStopMissionButton.setTitle("Start Mission", for: .normal)
            self.startStopMissionButton.isHidden = true
            self.infoLabel.text = "Mission Stoped"
        }
    }
    
    private func didFinished() {
        startStopMissionButton.setTitle("Start Mission", for: .normal)
        prepareMissionButton.isHidden = false
        infoLabel.text = "Mission Finished"
    }
    
    @IBAction func didTapStartStopMission(_ sender: Any) {
        DJISDKManager.missionControl()?.startTimeline()
    }
    
    @IBAction func didTapPrepareMission(_ sender: UIButton) {
        infoLabel.text = "Uploading"
        let mission = DJIMutableWaypointMission()
        mission.maxFlightSpeed = 15
        mission.autoFlightSpeed = 8
        mission.finishedAction = .goHome
        mission.headingMode = .auto
        mission.flightPathMode = .normal
        mission.rotateGimbalPitch = true
        mission.exitMissionOnRCSignalLost = true
        mission.gotoFirstWaypointMode = .safely
        mission.repeatTimes = 1
        
        let waypoints: [DJIWaypoint] = coordinatesToGo.map { coordinate in
            let waypoint = DJIWaypoint(coordinate: coordinate)
            waypoint.altitude = getAltitudeSelected()
            return waypoint
        }
        
        mission.addWaypoints(waypoints)
    
        let element: DJIMissionControlTimelineElement = DJIWaypointMission(mission: mission)
        
        let error = DJISDKManager.missionControl()?.scheduleElement(element)
        
        if error != nil {
            infoLabel.text = error?.localizedDescription ?? ""
            NSLog("Error scheduling element \(String(describing: error))")
            return;
        }
        infoLabel.text = "Mission Uploaded"
        
        startStopMissionButton.isHidden = false
    }
    
    @IBAction func didTapClearWaypoints(_ sender: UIButton) {}
    
}

extension MissionMapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        guard let location = locations.first else { return }
        
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate,
                                                  latitudinalMeters: 200,
                                                  longitudinalMeters: 200)
        self.mapView.setRegion(coordinateRegion, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error.localizedDescription)
    }
}

extension MissionMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let identifier = "Annotation"
        var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
        
        if annotation.isEqual(MKPointAnnotation.self) {
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView!.canShowCallout = true
                annotationView!.tintColor = .red
            } else {
              annotationView!.annotation = annotation
            }
            
            return annotationView
        }
        
        return nil
    }
}

extension MissionMapViewController: DJIFlightControllerDelegate {
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        guard let aircraftLocation = state.aircraftLocation else { return }
        let heading = state.attitude.yaw * Double.pi / 180.0
        
        if let marker = droneMarker {
            marker.coordinate = aircraftLocation.coordinate
            marker.heading = heading
        } else {
            droneMarker = Marker("drone", aircraftLocation.coordinate, heading)
            mapView.addSubview(droneMarker!)
        }
        
        if let homeLocation = state.homeLocation {
            if let marker = homeLocationMarker {
                marker.coordinate = homeLocation.coordinate
            } else {
                homeLocationMarker = Marker("home_on", homeLocation.coordinate)
                mapView.addSubview(homeLocationMarker!)
            }
        }
        
        let coordinateRegion = MKCoordinateRegion(center: aircraftLocation.coordinate,
                                                  latitudinalMeters: 200,
                                                  longitudinalMeters: 200)
        self.mapView.setRegion(coordinateRegion, animated: true)
        
        currentAltitudeLabel.text = "\(state.altitude)m"
    }
}
