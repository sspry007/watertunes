//
//  GoalTableViewController.swift
//  watertunes
//
//  Created by Steven Spry on 6/3/20.
//  Copyright © 2020 Steven Spry. All rights reserved.
//

import UIKit

class GoalTableViewController: UITableViewController {

    @IBOutlet weak var stepper:UIStepper!
    @IBOutlet weak var stepperLabel:UILabel!
    @IBOutlet weak var weightLabel:UILabel!
    @IBOutlet weak var goalLabel:UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let goalPerPound = HealthManager.shared.goalPerPound
        stepper.value = goalPerPound * 100
        stepperLabel.text = "\(goalPerPound) Oz"
        
        setupView()
    }
    
    @IBAction private func stepperTapped(_ sender: UIStepper) {
        let stepperValue = sender.value
        let goalPerPound = stepperValue / 100
        stepperLabel.text = "\(goalPerPound) Oz"
        HealthManager.shared.goalPerPound = goalPerPound
        
        setupView()
    }
    
    func setupView() {
        weightLabel.text = String(format: "%.0f Lbs", HealthManager.shared.bodyWeight)
        goalLabel.text = String(format: "%.0f Oz", HealthManager.shared.bodyWeight * HealthManager.shared.goalPerPound)
    }
}
