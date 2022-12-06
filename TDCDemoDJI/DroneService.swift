//
//  DroneService.swift
//  TDCDemoDJI
//
//  Created by Guilherme Leite Colares on 04/12/22.
//

import DJISDK

class DroneService: NSObject {
    
    static let shared = DroneService()
    
    open var connectedProduct: DJIAircraft?
    
    var registered = false
    var connected = false
    
    func registerWithProduct() {
        DJISDKManager.registerApp(with: self)
    }
}

extension DroneService: DJISDKManagerDelegate {
    func appRegisteredWithError(_ error: Error?) {
        if error == nil {
            registered = true
            NSLog("Connecting to product...")
            
            // Start connection to product
            let startedResult = DJISDKManager.startConnectionToProduct()
            
            if startedResult {
                NSLog("successfully!")
            } else {
                NSLog("failed to start!")
            }
        } else {
            NSLog("Error Registrating App: \(String(describing: error))")
        }
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        NSLog("Connection to new product succeeded!")
        connectedProduct = product as? DJIAircraft
    }
    
    func productDisconnected() {
        connected = false
    }

    func didUpdateDatabaseDownloadProgress(_ progress: Progress) {}
}
