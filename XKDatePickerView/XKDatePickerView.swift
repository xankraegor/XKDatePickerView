//
//  XKDatePickerView.swift
//  XKDatePickerView
//
//  Created by Xan Kraegor on 15.03.2017.
//  Copyright © 2017 Anton Alekseev
//

import UIKit

@objc protocol XKDatePickerViewDelegate: class {
    @objc optional func xkDatePickerDateChangedWith(date: Date)
}

class XKDatePickerView: UIPickerView, UIPickerViewDataSource, UIPickerViewDelegate {

    // MARK: - Constants

    // Represents each picker view component as an Int value
    // Day|Month|Cent|Subc|Era
    // -----------------------
    //  16|March|  13|74  |BC
    internal struct Component {
        static let day = 0
        static let month = 1
        static let century = 2
        static let subcent = 3
        static let era = 4
    }

    // Used for 'infinite' scroll of the first 4 components: day, month, century, subcentury
    internal let initailPositionIndex: Int = 10_000
    internal let maximumRowsInInfiniteComponent: Int = 20_000

    // Default widths for picker components, used for convenience initialization
    internal let defaultEraComponentWidth: CGFloat = 60
    internal let defaultNumericalComponentWidth: CGFloat = 34
    internal let defualtMonthComponentWidth: CGFloat = 80

    // MARK: - Public properties
    public var xkDatePickerDelegate: XKDatePickerViewDelegate?
    public var validDateFontColor: UIColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    public var invalidDateFontColor: UIColor = #colorLiteral(red: 0.8374180198, green: 0.8374378085, blue: 0.8374271393, alpha: 1)

    public var maximumYear: Int = -9999 {
        didSet {
            guard maximumYear > minimumYear else {
                fatalError("maximumYear \(maximumYear) should be greater than minimumYear \(minimumYear)")
            }
            if pickerDate > maximumDate() {
                selectRowsAndUpdatePickerDateFor(date: maximumDate(), initial: true, animated: true)
            }
            self.layoutSubviews()
            self.reloadAllComponents()

        }
    }

    public var minimumYear: Int = 9999 {
        didSet {
            guard maximumYear > minimumYear else {
                fatalError("maximumYear \(maximumYear) should be greater than minimumYear \(minimumYear)")
            }
            if pickerDate < minimumDate() {
                selectRowsAndUpdatePickerDateFor(date: minimumDate(), initial: true, animated: true)
            }
            self.layoutSubviews()
            self.reloadAllComponents()
        }
    }

    internal var pickerDate: Date = Date() {
        didSet {
            xkDatePickerDelegate?.xkDatePickerDateChangedWith?(date: pickerDate)
            self.reloadAllComponents()
        }
    }

    // MARK: - Private properties

    internal var useShortMonthLabels = false {
        didSet {
            self.reloadAllComponents()
        }
    }

    // Gregorian calendar only (in prolaplic mode for dates before its adoption)
    internal var cal = Calendar.init(identifier: Calendar.Identifier.gregorian)
    // Stores maximal width for each picker component, based on it's localized label for current locale
    internal var dynamicComponentWidths: [CGFloat]?


    // MARK: - Life Cycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    func commonInit() {
        guard maximumYear > minimumYear else {
            fatalError("maximumYear \(maximumYear) should be greater than minimumYear \(minimumYear)")
        }
        // Set current locale for reused gregorian calendar object
        cal.locale = Locale.current

        self.dataSource = self
        self.delegate = self
        selectRowsAndUpdatePickerDateFor(date: pickerDate, initial: true, animated: false)
    }

    override func layoutSubviews() {
        dynamicComponentWidths = ([Int](0...4)).map{calculateMaximumWidthForComponent(component: $0, short: false)}
        let pickerComponentsWidth = (dynamicComponentWidths?.reduce(0, +))!
        if pickerComponentsWidth > self.bounds.width {
            useShortMonthLabels = true
            dynamicComponentWidths?[Component.month] = calculateMaximumWidthForComponent(component: Component.month, short: true)
        } else {
            useShortMonthLabels = false
            dynamicComponentWidths?[Component.month] = calculateMaximumWidthForComponent(component: Component.month, short: false)
        }

        super.layoutSubviews()
    }

    // MARK: - User Interface

    internal func selectRowsAndUpdatePickerDateFor(date: Date, initial: Bool, animated: Bool) {
        // Calculate indexes for picker sections
        let dayIndex = cal.component(Calendar.Component.day, from: date) - 1
        let monthIndex = cal.component(Calendar.Component.month, from: date) - 1
        let year = cal.component(Calendar.Component.year, from: date)
        let centuryIndex = getCentury(fromYear: year)
        let subcenturyIndex = getSubcentury(fromYear: year)
        let eraIndex = cal.component(Calendar.Component.era, from: date)
        // 'Infinite' scroll implemented the way it begins at index, that is far enough from beginning and end for user 
        // to have scrolled to. Rows for each of the picker components are selected at indexes in relation to initial
        // position or current nearest initial position of the cycle for 'infinite' scroll components (excluding era).
        if initial {
            selectRow(initailPositionIndex + dayIndex, inComponent: Component.day, animated: animated)
            selectRow(initailPositionIndex + monthIndex, inComponent: Component.month, animated: animated)
            selectRow(initailPositionIndex + centuryIndex, inComponent: Component.century, animated: animated)
            selectRow(initailPositionIndex + subcenturyIndex, inComponent: Component.subcent, animated: animated)
            selectRow(eraIndex, inComponent: Component.era, animated: animated)
        } else {
            selectRow(nearestInitialPositionForSelectedRow(of: Component.day) + dayIndex, inComponent: Component.day, animated: animated)
            selectRow(nearestInitialPositionForSelectedRow(of: Component.month) + monthIndex, inComponent: Component.month, animated: animated)
            selectRow(nearestInitialPositionForSelectedRow(of: Component.century) + centuryIndex, inComponent: Component.century, animated: animated)
            selectRow(nearestInitialPositionForSelectedRow(of: Component.subcent) + subcenturyIndex, inComponent: Component.subcent, animated: animated)
            selectRow(eraIndex, inComponent: Component.era, animated: animated)
        }
        pickerDate = date
    }


    // MARK: - UIPickerViewDataSource Methods

    internal func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 5
    }

    internal func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == Component.era {
            return 2
        } else {
            return maximumRowsInInfiniteComponent
        }
    }


    // MARK: - UIPickerViewDelegate Methods

    internal func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {

        var label: String?
        let paragraph = NSMutableParagraphStyle()
        var attributes = [String : Any]()
        let row = realRow(forRow: row, forComponent: component)!
        let isNewDateValid = isDateValid(afterChangingComponent: component, toValue: row)

        switch component {
        case Component.day: // 1 to 31
            label = String(row + 1)
            paragraph.alignment = .right
            attributes[NSForegroundColorAttributeName] = isNewDateValid ? validDateFontColor : invalidDateFontColor
        case Component.month: // (localized) January to December
            label = useShortMonthLabels ? DateFormatter().shortMonthSymbols[row] : DateFormatter().monthSymbols[row]
            paragraph.alignment = .center
        case Component.century: // 0 to 60
            label = String(row)
            paragraph.alignment = .right
            attributes[NSForegroundColorAttributeName] = isNewDateValid ? validDateFontColor : invalidDateFontColor
        case Component.subcent: // 00 to 99
            label = row > 9 ? String(row) : "0\(row)"
            paragraph.alignment = .left
            attributes[NSForegroundColorAttributeName] = isNewDateValid ? validDateFontColor : invalidDateFontColor
        case Component.era: // (localized) BC or AD
            label = DateFormatter().eraSymbols[row]
        default:
            label = ""
        }

        attributes[NSParagraphStyleAttributeName] = paragraph
        return NSAttributedString(string: label!, attributes: attributes)
    }

    internal func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        // Calculated on init and layout
        return dynamicComponentWidths![component]
    }

    internal func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        var dateComponents = cal.dateComponents(Set<Calendar.Component>([.day, .month, .year, .era, .hour, .minute, .second]), from: pickerDate)
        let row = realRow(forRow: row, forComponent: component)!

        switch component {
        case Component.day:
            dateComponents.day = row + 1
        case Component.month:
            dateComponents.month = row + 1
        case Component.century:
            dateComponents.year = row * 100 + getSubcentury(fromYear: dateComponents.year!)
        case Component.subcent:
            let century = getCentury(fromYear: dateComponents.year!)
            dateComponents.year = century * 100 + row
        case Component.era:
            dateComponents.era = row
        default:
            break
        }

        var newDate = cal.date(from: dateComponents)!
        if newDate >= maximumDate() {
            newDate = maximumDate()
        }
        if newDate <= minimumDate() {
            newDate = minimumDate()
        }
        selectRowsAndUpdatePickerDateFor(date: newDate, initial: true, animated: false)
    }


    // MARK: - Methods for external control

    public func setXkPickerDate(to date: Date) {
        if date >= maximumDate() {
            selectRowsAndUpdatePickerDateFor(date: maximumDate(), initial: true, animated: true)
        } else if date <= minimumDate() {
            selectRowsAndUpdatePickerDateFor(date: minimumDate(), initial: true, animated: true)
        } else {
            selectRowsAndUpdatePickerDateFor(date: date, initial: true, animated: true)
        }
    }


    // MARK: - Helper functions

    internal func getCentury(fromYear year: Int) -> Int {
        return abs(year / 100)
    }

    internal func getSubcentury(fromYear year: Int) -> Int {
        return abs(abs(year) - getCentury(fromYear: year) * 100)
    }

    /// Maximum width for each picker view component
    func calculateMaximumWidthForComponent(component: Int, short: Bool) -> CGFloat {
        let fontAttributes = [NSFontAttributeName: UIFont.systemFont(ofSize: 30.0)]
        let borderThickness: CGFloat = 4

        // Numerical components
        if component == Component.day || component == Component.century || component == Component.subcent {
            // Maximum width of attributed strings contatining double '0' to double '9'
            let maxWidth = ([Int](0...9).map{"\($0)\($0)"}.map{$0.size(attributes: fontAttributes).width}.max())
            if maxWidth != nil {
                return maxWidth! + borderThickness
            } else {
                return defaultNumericalComponentWidth
            }
        } else if component == Component.month {
            if short {
                // Maximum width of attributed strings contatining short month labels
                let maxWidth = ([Int](0...11)).map{cal.shortMonthSymbols[$0]}.map{$0.size(attributes: fontAttributes).width}.max()
                if maxWidth != nil {
                    return maxWidth! + borderThickness
                } else {
                    return defualtMonthComponentWidth
                }
            } else {
                // Maximum width of attributed strings contatining full month labels
                let maxWidth = ([Int](0...11)).map{cal.monthSymbols[$0]}.map{$0.size(attributes: fontAttributes).width}.max()
                if maxWidth != nil {
                    return maxWidth! + borderThickness
                } else {
                    return defualtMonthComponentWidth
                }
            }
        } else if component == Component.era {
            // Maximum width of attributed strings contatining era labels
            let maxWidth = [0, 1].map{cal.eraSymbols[$0]}.map{$0.size(attributes: fontAttributes).width}.max()
            if maxWidth != nil {
                return maxWidth! + 4
            } else {
                return defaultEraComponentWidth
            }
        }

        return 0
    }


    // MARK: - Date validation

    internal func maximumDate() -> Date {
        let era = maximumYear >= 0 ? 1 : 0
        let year = abs(maximumYear)
        let month = 12
        let day = 31
        let now = Date()
        let hour = cal.component(Calendar.Component.hour, from: now)
        let minute = cal.component(Calendar.Component.minute, from: now)
        let second = cal.component(Calendar.Component.second, from: now)
        let components = DateComponents(calendar: cal, timeZone: nil, era: era, year: year, month: month, day: day,
                                        hour: hour, minute: minute, second: second)
        return cal.date(from: components)!
    }

    internal func minimumDate() -> Date {
        let era = minimumYear >= 0 ? 1 : 0
        let year = abs(minimumYear)
        let month = 1
        let day = 1
        let now = Date()
        let hour = cal.component(Calendar.Component.hour, from: now)
        let minute = cal.component(Calendar.Component.minute, from: now)
        let second = cal.component(Calendar.Component.second, from: now)
        let components = DateComponents(calendar: cal, timeZone: nil, era: era, year: year, month: month, day: day,
                                        hour: hour, minute: minute, second: second)
        return cal.date(from: components)!
    }

    internal func isDateValid(afterChangingComponent component: Int, toValue newValue: Int) -> Bool {
        var value: Int?
        var changingCalendarComponent: Calendar.Component?

        switch component {
        case Component.day:
            value = newValue + 1
            changingCalendarComponent = .day
        case Component.month:
            value = newValue + 1
            changingCalendarComponent = . month
        case Component.century:
            let subcentury = getSubcentury(fromYear: cal.component(.year, from: pickerDate))
            value = newValue * 100 + subcentury
            changingCalendarComponent = .year
        case Component.subcent:
            let century = getCentury(fromYear: cal.component(.year, from: pickerDate))
            value = century * 100 + newValue
            changingCalendarComponent = .year
        case Component.era:
            value = newValue
            changingCalendarComponent = .era
        default:
            break
        }

        let componentsForCurrentPickerDate = cal.dateComponents(Set<Calendar.Component>([.day, .month, .year, .era]), from: pickerDate)
        var newComponents = componentsForCurrentPickerDate
        newComponents.setValue(value, for: changingCalendarComponent!)

        var maxDateForComparision = maximumDate()
        maxDateForComparision.addTimeInterval(84400)
        var minDateForComparision = minimumDate()
        minDateForComparision.addTimeInterval(-84400)

        if newComponents.isValidDate(in: cal) {
            if let newDate = cal.date(from: newComponents) {
                if newDate > maxDateForComparision {
                    return false
                }
                if newDate < minDateForComparision {
                    return false
                }
                return true
            }
        }

        return false
    }


    // MARK: - 'Infinite' sections scroll helpers

    /// This is what pickerView:numberOfRows method could have contained, if there were no 'infinite' scroll
    func realNumberOfRows(forComponent component: Int)->Int {
        switch component {
        case Component.day:       return 31
        case Component.month:     return 12
        case Component.century:
            let biggestYear: Int = [abs(maximumYear), abs(minimumYear)].max()!
            let remainder: Int = biggestYear % 100
            return remainder > 0 ? biggestYear + 1 : biggestYear
        case Component.subcent:   return 100
        case Component.era:       return 2
        default:                  return 0
        }
    }

    /// Real row index for 'infinite' scroll row
    func realRow(forRow row: Int, forComponent component: Int)->Int? {
        guard component >= 0 && component < 5 else {
            return nil
        }

        guard component != Component.era else {
            return row
        }

        guard row >= 0 && row <= maximumRowsInInfiniteComponent else {
            return nil
        }

        let delta = row - initailPositionIndex
        let remainder = delta % realNumberOfRows(forComponent: component)
        if remainder < 0 {
            return realNumberOfRows(forComponent: component) + remainder
        } else {
            return remainder
        }
    }

    /// Nearest begin of 'infinite' scroll cycle in relation to the row of a component just changed
    func nearestInitialPositionForSelectedRow(of component: Int) -> Int {
        let selectedRow: Int = self.selectedRow(inComponent: component)
        let delta: Int = selectedRow - initailPositionIndex
        let rowsCycled: Int = realNumberOfRows(forComponent: component)
        let cyclesCount: Int = abs(delta) / rowsCycled
        if delta >= 0 {
            return cyclesCount * rowsCycled
        } else {
            return (-1) * cyclesCount * rowsCycled - 1
        }
    }
}
