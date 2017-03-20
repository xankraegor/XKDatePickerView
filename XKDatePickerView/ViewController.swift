//
//  ViewController.swift
//  XKDatePickerView
//
//  Created by Xan Kraegor on 15.03.2017.
//  Copyright © 2017 Anton Alekseev
//

import UIKit

class ViewController: UIViewController, UIPickerViewDelegate, XKDatePickerViewDelegate, UITextFieldDelegate {

    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var xkDatePicker: XKDatePickerView!
    @IBOutlet weak var minYearTextField: UITextField!
    @IBOutlet weak var maxYearTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        xkDatePicker.xkDatePickerDelegate = self
        minYearTextField.delegate = self
        maxYearTextField.delegate = self
    }

    // XKPickerViewDelegate

    func xkDatePickerDateChangedWith(date: Date) {
        var cal = Calendar.init(identifier: Calendar.Identifier.gregorian)
        cal.locale = Locale.current
        let era = cal.component(Calendar.Component.era, from: date)
        let eraString = cal.eraSymbols[era]
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        label.text = formatter.string(from: date) + " \(eraString)"
        print(date)
    }

    @IBAction func setTodayPressed(_ sender: UIButton) {
        let today = Date()
        xkDatePicker.setXkPickerDate(to: today)
    }

    @IBAction func setMinYear(_ sender: Any) {
        if let minYear = Int(minYearTextField.text!) {
            xkDatePicker.minimumYear = minYear
        }
    }

    @IBAction func setMaxYear(_ sender: Any) {
        if let maxYear = Int(maxYearTextField.text!) {
            xkDatePicker.maximumYear = maxYear
        }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func randomizeColors(_ sender: Any) {
        let enabledDateFontColor = UIColor(colorLiteralRed: Float(arc4random_uniform(256)) / 255.0, green: Float(arc4random_uniform(256)) / 255.0, blue: Float(arc4random_uniform(256)) / 255.0, alpha: 1)
        print(enabledDateFontColor)
        let disabledDateFontColor = UIColor(colorLiteralRed: Float(arc4random_uniform(256)) / 255.0, green: Float(arc4random_uniform(256)) / 255.0, blue: Float(arc4random_uniform(256)) / 255.0, alpha: 1)
        print(disabledDateFontColor)

        xkDatePicker.validDateFontColor = enabledDateFontColor
        xkDatePicker.invalidDateFontColor = disabledDateFontColor
    }


}

