# XKDatePickerView

A simple date picker written in Swift, that has two wheels for year selection and an era picker. Supports Gregorian calender only by now.

Features:
* Year, Month, Century, Subcentury and Era picker wheels
* 'Infinite' scrolling for Year, Month, Century, Subcentury and Era
* Minimum and maximum year customization in range from 9999 DCE to 9999 CE
* Date validation (incl. vs maximum and minimum date)
* Different color for valid / non-valid date font

## Getting Started

Just copy XKDatePickerView.swift to your project.
UIPickerViewDataSource and UIPickerViewDelegate protocols are already implemented in AXDatePickerView itself, so don't implement them for axDatePickeView object,
Add conformance to XKDatePickerViewDelegate instead. Example:

```
class ViewController: UIViewController, XKDatePickerViewDelegate {

override func viewDidLoad() {
        super.viewDidLoad()
        xkDatePicker.xkDatePickerDelegate = self
        }
```

### Callback

Implement XKDatePickerViewDelegate function to recieve selected date:
```
func axDatePickerDateChangedWith(date: Date) {
        // Your code here to handle date
    }
```

## Customization
Make outlet for AXDatePicker object in your controller.
```
@IBOutlet weak var xkDatePicker: XKDatePickerView!
```

To select date implement xkDatePickerDateChangedWith function:
```
func xkDatePickerDateChangedWith(date: Date) {
        // Your code here to handle the date
    }
```

To change minimum and maximum year set corresponing class property:
```
let minYear: Int = -4000
xkDatePicker.minimumYear = minYear

let maxYear: Int = 5500
xkDatePicker.maximumYear = maxYear
```
New dates will be handled automatically. Keep in mind, that maximum date should be greater than minimum date, otherwise a fatalError will be thrown.

## Contributing

Feel free to contribute!

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details
