//
//  DrinkViewTableController.swift
//  watertunes
//
//  Created by Steven Spry on 6/3/20.
//  Copyright © 2020 Steven Spry. All rights reserved.
//

import UIKit

let drinkTypes:[(value:Double,text:String)] = [(5.0,"5 Oz Mini"), (8.0,"8 Oz Glass"), (16.7,"16.7 Oz Bottle"),
(20,"20 Oz Tumbler"), (24.0,"24 Oz Bottle"), (32.0,"32 Oz Jug")]

class DrinkViewTableController: UITableViewController {

    @IBOutlet weak var picker:UIPickerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        picker.selectRow(Int(drinkTypes.count/2), inComponent: 0, animated: true)
    }
    
    @IBAction private func updateTapped(_ sender: Any) {
        let idx = picker.selectedRow(inComponent: 0)
        let item = drinkTypes[idx]     
        HealthManager.shared.saveWater(value: item.value)
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func cancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension DrinkViewTableController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return drinkTypes.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var title = UILabel()
        if let view = view {
            title = view as! UILabel
        }
        title.font = UIFont(name: "Avenir-Roman", size: 17.0)
        title.textColor = .systemBlue
        title.text =  drinkTypes[row].text
        title.textAlignment = .center

        return title
    }
    
    
}
