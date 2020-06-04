//
//  VisualizeViewController.swift
//  watertunes
//
//  Created by Steven Spry on 6/3/20.
//  Copyright © 2020 Steven Spry. All rights reserved.
//

import UIKit
//import MKRingProgressView

class VisualizeViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var goalLabel: UILabel!

    var ringProgressView: RingProgressView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        ringProgressView = RingProgressView(frame: containerView.bounds)
        ringProgressView.startColor = UIColor.init(red: 0, green: 122/255.0, blue: 1, alpha: 1)
        ringProgressView.endColor = UIColor.init(red: 0, green: 92/255.0, blue: 191/255.0, alpha: 1)
        ringProgressView.ringWidth = 50
        ringProgressView.progress = 0.0
        containerView.addSubview(ringProgressView)

        NotificationCenter.default.addObserver(self, selector: #selector(updateHealth(notification:)),
        name: NSNotification.Name(rawValue: healthUpdateDidComplete), object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        setupViews()
    }
    
    func setupViews() {
        self.goalLabel.text = "\(HealthManager.shared.water) Ounces of Your \(HealthManager.shared.dailyGoal) Ounce Daily Goal"
        let percentage = HealthManager.shared.water / Double(HealthManager.shared.dailyGoal)
        UIView.animate(withDuration: 0.5) {
            self.ringProgressView.progress = percentage
        }
    }
    
    @objc func updateHealth(notification: Notification) {
        DispatchQueue.main.async {
            self.setupViews()
        }
    }
}

