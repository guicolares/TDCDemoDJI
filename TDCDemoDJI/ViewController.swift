//
//  ViewController.swift
//  TDCDemoDJI
//
//  Created by Guilherme Leite Colares on 04/12/22.
//

import UIKit
import DJIUXSDK

final class ViewController: DUXDefaultLayoutViewController {
    
    // MARK: IBOutlets
    @IBOutlet private weak var motorsButton: UIButton!
    @IBOutlet private weak var takeOffLandingButton: UIButton!
    
    // MARK: Properties
    private var currentDroneState: DJIFlightControllerState = .init()
    
    private lazy var flightController: DJIFlightController? = {
        DroneService.shared.connectedProduct?.flightController
    }()

    // MARK: Life
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        flightController?.delegate = self
    }
    
    // MARK: Button Actions
    @IBAction func didTapMotors(_ sender: Any) {
        if currentDroneState.areMotorsOn {
            flightController?.turnOffMotors()
            motorsButton.setTitle("Turn on Motors", for: .normal)
        } else {
            flightController?.turnOnMotors()
            motorsButton.setTitle("Turn off Motors", for: .normal)
        }
    }
    
    @IBAction func didTapTakeOffLanding(_ sender: Any) {
        if currentDroneState.isFlying {
            flightController?.startLanding()
            takeOffLandingButton.setTitle("Start Take Off", for: .normal)
        } else {
            flightController?.startTakeoff()
            takeOffLandingButton.setTitle("Start Landing", for: .normal)
        }
    }
}

// MARK: Flight Controller Delegate
extension ViewController: DJIFlightControllerDelegate {
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        currentDroneState = state
    }
}
