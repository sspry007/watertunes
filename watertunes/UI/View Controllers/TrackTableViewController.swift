//
//  TrackTableViewController.swift
//  watertunes
//
//  Created by Steven Spry on 6/3/20.
//  Copyright © 2020 Steven Spry. All rights reserved.
//

import UIKit
import HealthKit

class TrackTableViewController: UITableViewController {
    
    @IBOutlet weak var boundingView:UIView!
    @IBOutlet weak var drinkButton:UIButton!
    @IBOutlet weak var goalLabel:UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        boundingView.layer.cornerRadius = 12.0
        boundingView.layer.borderWidth = 0.5
        boundingView.layer.borderColor = UIColor.lightGray.cgColor
        boundingView.layer.masksToBounds = true
        
        drinkButton.titleLabel?.textAlignment = .center
        goalLabel.text = ""
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateHealth(notification:)),
                                               name: NSNotification.Name(rawValue: healthUpdateDidComplete), object: nil)
        
        HealthManager.shared.authorizeHealthKit { [weak self] (success, error) in
        
            guard let strongSelf = self else { return }
            if success {
                HealthManager.shared.getHealthData()
            } else {
                if let error = error {
                    print(error)
                    
                    DispatchQueue.main.async {
                        strongSelf.navigationItem.prompt = error.localizedDescription
                    }
                }
            }
        }
    }
    
    @objc func updateHealth(notification: Notification) {
        DispatchQueue.main.async {
            self.goalLabel.text = "\(HealthManager.shared.dailyGoal) Oz"
        }
    }
}

