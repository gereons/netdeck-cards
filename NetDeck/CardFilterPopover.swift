//
//  CardFilterPopover.swift
//  NetDeck
//
//  Created by Gereon Steffens on 06.01.17.
//  Copyright © 2021 Gereon Steffens. All rights reserved.
//

import UIKit

protocol FilteringViewController: class {
    
    func filterCallback(attribute: FilterAttribute, value: FilterValue)
    
    var view: UIView! { get }
    
    func present(_ : UIViewController, animated: Bool, completion: (()->Void)?)
}

class CardFilterPopover: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var sections = [String]()
    private var values = [[String]]()
    private var button: UIButton!
    private var attribute: FilterAttribute!
    private weak var filteringViewController: FilteringViewController!
    private var selectedValues = Set<String>()
    private var sectionToggles = [Bool]()
    private var collapsedSections: [Bool]?
    
    private var sectionCount = 0
    private var totalEntries = 0
    
    private static var popover: CardFilterPopover!
    
    static func showFrom(button: UIButton, inView vc: FilteringViewController, entries: TableData<String>, attribute: FilterAttribute, selected: FilterValue?) {
        popover = CardFilterPopover()
        popover.sections = entries.sections
        popover.values = entries.values
        popover.collapsedSections = entries.collapsedSections
        popover.button = button
        popover.attribute = attribute
        popover.filteringViewController = vc
        
        popover.selectedValues.removeAll()
        if let selectedSet = selected?.strings, selectedSet.count > 1 {
            popover.selectedValues = selectedSet
        } else if let selectedStr = selected?.string, selectedStr != Constant.kANY {
            popover.selectedValues = Set([selectedStr])
        }
        
        popover.sectionToggles.removeAll()
        
        popover.sectionCount = 0
        for s in entries.sections {
            popover.sectionToggles.append(false)
            popover.collapsedSections?.append(false)
            if s.count > 0 {
                popover.sectionCount += 1
            }
        }
        
        popover.totalEntries = 0
        for arr in popover.values {
            popover.totalEntries += arr.count
        }
        
        let rect = button.superview?.convert(button.frame, to: vc.view) ?? CGRect.zero
        
        popover.modalPresentationStyle = .popover
        popover.popoverPresentationController?.sourceRect = rect
        popover.popoverPresentationController?.sourceView = vc.view
        popover.popoverPresentationController?.permittedArrowDirections = .left
        
        vc.present(popover, animated: false, completion: nil)
    }
    
    static func dismiss() {
        popover?.dismiss(animated: false, completion: nil)
        popover = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        let tableTap = UITapGestureRecognizer(target: self, action: #selector(doubleTap(_:)))
        tableTap.numberOfTapsRequired = 2
        self.tableView.addGestureRecognizer(tableTap)
        
        self.setTableHeight()
        
        self.preferredContentSize = self.tableView.frame.size
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.setTableHeight()
    }
    
    @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
        if gesture.state == .ended {
            CardFilterPopover.dismiss()
        }
    }
    
    private let cellHeight = 40
    private let headerHeight = 25
    private let tableWidth = 220
    
    func setTableHeight() {
        var h = 0
        for arr in self.values {
            h += cellHeight * arr.count
        }
        h += headerHeight * self.sectionCount
        
        self.tableView.isScrollEnabled = h > 700
        h = min(h, 700)
        
        var frame = self.tableView.frame
        frame.size.height = CGFloat(h)
        self.tableView.frame = frame
    }
    
    // MARK: - table view
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let arr = self.values[section]
        let collapsed = self.collapsedSections?[section] ?? false
        return collapsed ? 0 : arr.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(cellHeight)
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let s = self.sections[section]
        return s.count > 0 ? CGFloat(headerHeight) : 0
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let s = self.sections[section]
        return s.count > 0 ? s : nil
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableWidth, height: headerHeight))
        view.backgroundColor = .secondarySystemBackground
        view.tag = section
        view.isUserInteractionEnabled = true

        let hackOffset: Int = {
            if #available(iOS 13.0, *) { return 10 } else { return 0 }
        }()

        let xOffset = hackOffset + (self.collapsedSections == nil ? 15 : 25)
        let label = UILabel(frame: CGRect(x: xOffset, y:0, width: tableWidth, height: headerHeight))
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.text = self.sections[section]
        view.addSubview(label)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(self.didSelectSection(_:)))
        view.addGestureRecognizer(tap)
        
        if self.collapsedSections != nil {
            let collapseButton = UIButton(type: .system)
            collapseButton.frame = CGRect(x: hackOffset, y: 0, width: 30, height: headerHeight)
            collapseButton.tag = section
            collapseButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 19)
            collapseButton.addTarget(self, action: #selector(self.collapseSection(_:)), for: .touchUpInside)
            view.addSubview(collapseButton)
        
            let collapsed = self.collapsedSections![section]
            UIView.performWithoutAnimation {
                collapseButton.setTitle(collapsed ? "▹" : "▿", for: .normal)
            }
        }
        return view
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "popupCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier) ?? {
            let c = UITableViewCell(style: .default, reuseIdentifier: identifier)
            c.selectionStyle = .none
            c.textLabel?.font = UIFont.systemFont(ofSize: 15)
            c.textLabel?.textColor = UIColor(red: 0, green: 0.5, blue: 1, alpha: 1)
            return c
        }()

        cell.accessoryType = .none
        
        let value = self.values[indexPath.section][indexPath.row]
        let any = value == Constant.kANY
        if any {
            cell.textLabel?.text = value.localized()
        } else {
            cell.textLabel?.text = value
        }
        
        if self.selectedValues.contains(value) && !any {
            cell.accessoryType = .checkmark
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        var value = self.values[indexPath.section][indexPath.row]
        
        // is this the first ("Any") cell?
        var anyCell = indexPath.row == 0 && indexPath.section == 0
        
        // if not, and we adding a new selection, and we're 1 shy of checking all possible values, treat as a tap on "Any"
        if !anyCell && !self.selectedValues.contains(value) && self.selectedValues.count == self.totalEntries - 2 {
            anyCell = true
            value = Constant.kANY
        }
        
        if anyCell {
            let title = self.attribute.localized() + ": " + value.localized()
            self.button.setTitle(title, for: .normal)
            
            self.filteringViewController.filterCallback(attribute: self.attribute, value: FilterValue.string(value))
            
            CardFilterPopover.dismiss()
        } else {
            let cell = tableView.cellForRow(at: indexPath)
            if self.selectedValues.contains(value) {
                cell?.accessoryType = .none
                self.selectedValues.remove(value)
            } else {
                cell?.accessoryType = .checkmark
                self.selectedValues.insert(value)
            }
            
            self.filterWithMultipleSelection()
        }
    }
    
    func filterWithMultipleSelection() {
        let selected: String
        let value: FilterValue
        switch selectedValues.count {
        case 0:
            selected = Constant.kANY.localized()
            value = FilterValue.string(Constant.kANY)
        case 1:
            let str = Array(self.selectedValues)[0]
            selected = str
            value = FilterValue.string(str)
        default:
            selected = "⋯"
            value = FilterValue.strings(selectedValues)
        }
        
        let title = self.attribute.localized() + ": " + selected
        
        self.button.setTitle(title, for: .normal)
        
        self.filteringViewController.filterCallback(attribute: self.attribute, value: value)
    }
    
    @objc func collapseSection(_ sender: UIButton) {
        assert(self.collapsedSections != nil)
        
        let collapsed = self.collapsedSections![sender.tag]
        
        UIView.performWithoutAnimation {
            sender.setTitle(collapsed ? "▹" : "▿", for: .normal)
        }
        self.collapsedSections![sender.tag] = !collapsed
        self.tableView.reloadData()
    }
    
    @objc func didSelectSection(_ gesture: UITapGestureRecognizer) {
        guard let section = gesture.view?.tag else {
            return
        }
        let collapsed = self.collapsedSections?[section] ?? false
        if collapsed {
            return
        }
        
        let on = self.sectionToggles[section]
        self.sectionToggles[section] = !on

        if !on {
            self.selectedValues.formUnion(self.values[section])
        } else {
            self.selectedValues.subtract(self.values[section])
        }
        
        self.tableView.reloadData()
        self.filterWithMultipleSelection()
    }
    
}
