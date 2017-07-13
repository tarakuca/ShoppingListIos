//
//  ShoppingListEditorViewController.swift
//  Shopping List
//
//  Created by Mirza Irwan on 2/7/17.
//  Copyright © 2017 Mirza Irwan <mirza.irwan.osman@gmail.com>. All rights reserved.
//

import UIKit
import CoreData

class ShoppingListItemEditorViewController: UIViewController {
    
    // MARK: - API and Model
    
    var shoppingList: ShoppingList!
    
    var shoppingListItem: ShoppingListItem?
    
    var persistentContainer: NSPersistentContainer = AppDelegate.persistentContainer
    
    // MARK: - State Transition variables
    
    fileprivate var changeState = ChangeState()
    
    fileprivate var pictureState = PictureState()
    
    private var selectedPriceState = SelectedPriceState()
    
    fileprivate var validationState = ValidationState()
    
    // MARK: - Properties
    
    private var prices: [Price]? {
        didSet {
            
            unitPrice = Price.filter(prices: prices!, match: .unit)
            unitPriceVc = unitPrice?.valueConvert
            
            bundlePrice = Price.filter(prices: prices!, match: .bundle)
            bundlePriceVc = bundlePrice?.valueConvert
            
            if let bundlePrice = bundlePrice {
                bundleQtyStepper.value = Double(bundlePrice.quantityConvert)
                bundleQtyPricingInfoVc = bundlePrice.quantityConvert
                
            } else {
                bundleQtyStepper.value = Double(2)
                bundleQtyPricingInfoVc = 2
            }
            
        }
    }
    
    private var unitPrice: Price?
    
    private var bundlePrice: Price?
    
    @IBOutlet weak var itemNameTextField: UITextErrorField!
    
    @IBOutlet weak var brandTextField: UITextField!
    
    @IBOutlet weak var countryOriginTextField: UITextField!
    
    @IBOutlet weak var descriptionTextField: UITextField!
    
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    
    @IBOutlet weak var deleteItemButton: UIButton!
    
    /**
     Shared by bundle pricing and unit pricing.
    */
    @IBOutlet weak var quantityToBuyLabel: UILabel!
    
    /**
     Shared by bundle pricing and unit pricing.
     */
    
    @IBOutlet weak var quantityToBuyStepper: UIStepper!
    
    @IBOutlet weak var pricingInformationSc: UISegmentedControl!
    
    @IBOutlet weak var priceStackView: UIStackView!
    
    @IBOutlet weak var bundleQtyStackView: UIStackView!
    
    @IBOutlet weak var currencyCodeField: UITextField!
    
    @IBOutlet weak var unitPriceTextField: UITextField!
    
    @IBOutlet weak var bundlePriceTextField: UITextField!
    
    @IBOutlet weak var bundleQtyLabel: UILabel!
    
    @IBOutlet weak var bundleQtyStepper: UIStepper!
    
    /**
     Shared by bundle pricing and unit pricing. The value of this property depends on the state of the price selected.
     Set quantityToBuyStepper from Int to Double and vice-versa
     */
    private var quantityToBuyStepperConvert: Int {
        set {
            quantityToBuyStepper.value = Double(newValue)
        }
        
        get {
            return Int(quantityToBuyStepper.value)
        }
    }
    
    /**
     Pricing information for bundle.
     Converts Double to Int for getter.
     Set value of bundleQtyLabel.text after converting Double to String.
     */
    private var bundleQtyPricingInfoVc: Int? {
        set {
            let setValue = newValue ?? 2
            bundleQtyLabel.text = String(describing: setValue)
        }
        
        get {
            return Int(bundleQtyStepper.value)
        }
    }
    
    /**
     Pricing information for unit
     */
    private var unitPriceVc: Int? {
        get {
            if let val = unitPriceTextField.text, !val.isEmpty {
                let dblVal = (Double(val))! * 100
                return Int(dblVal)
            } else {
                return nil
            }
        }
        set {
            
            if let newValue = newValue {
                unitPriceTextField.text = Helper.formatMoney(amount: newValue)
            } else {
                unitPriceTextField.text = nil
            }
        }
    }
    
    /**
     Pricing information for bundle
     */
    private var bundlePriceVc: Int? {
        
        get {
            
            if let val = bundlePriceTextField.text, !val.isEmpty {
                let dblVal = (Double(val))! * 100
                return Int(dblVal)
            } else {
                return nil
            }
        }
        
        set {
            
            if let newValue = newValue {
                bundlePriceTextField.text = Helper.formatMoney(amount: newValue)
            } else {
                bundlePriceTextField.text = nil
            }
        }
    }
    
    fileprivate var itemImage: UIImage? {
        didSet {
            itemImageView.image = itemImage
        }
    }
    
    @IBOutlet weak var itemImageView: UIImageView!
    
    private let moneyTextFieldDelegate = MoneyUITextFieldDelegate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("\(#function) - \(type(of: self))")
        doneButton.isEnabled = false
        itemNameTextField.delegate = self
        brandTextField.delegate = self
        countryOriginTextField.delegate = self
        descriptionTextField.delegate = self
        
        moneyTextFieldDelegate.vc = self
        moneyTextFieldDelegate.changeState = changeState
        unitPriceTextField.delegate = moneyTextFieldDelegate
        bundlePriceTextField.delegate = moneyTextFieldDelegate
        
        if shoppingListItem == nil {
            validationState.handle(event: .onItemNew, handleNextStateUiAttributes: validationStateUiPropertiesHandler)
        } else {
            validationState.handle(event: .onItemExist, handleNextStateUiAttributes: validationStateUiPropertiesHandler)
        }
    }
    
    @IBAction func onCancel(_ sender: UIBarButtonItem) {
        changeState.transition(event: .onCancel(changeStateOnCancelEventAction), handleNextStateUiAttributes: changeStateAttributeHandler)
    }
    
    @IBAction func onDone(_ sender: UIBarButtonItem) {
        
        let onSaveEventhandler = ValidationState.OnSaveItemEventHandler(validate: { currentState in
            
            if let name = self.itemNameTextField.text, !name.isEmpty {
                
                switch currentState {
                    
                case .newItem:
                    do {
                        if try Item.isNameExist(self.itemNameTextField.text!, moc: self.persistentContainer.viewContext) {
                            self.itemNameTextField.errorText = "Name already exist"
                            return false
                        } else {
                            return true
                        }
                    } catch {
                        let nserror = error as NSError
                        print("Error \(nserror) : \(nserror.userInfo)")
                        return false
                    }
                    
                default:
                    return true
                }
                
            } else {
                self.itemNameTextField.errorText = "Name cannot be empty"
                return false
            }
            
        }, actionIfValidateTrue: {currentState in
            
            switch currentState {
                
            case .newItem:
                self.saveNew()
                self.presentingViewController?.dismiss(animated: true, completion: nil)
                
            case .existingItem:
                self.saveUpdate()
                self.presentingViewController?.dismiss(animated: true, completion: nil)
                
            default:
                break
            }
        })
        
        validationState.handle(event: .onSaveItem(onSaveEventhandler), handleNextStateUiAttributes: nil)
    }
    
    // MARK: - State: Selected price type, Pricing information, Quantity to buy logic
    
    /**
     I need a stored property for quantity to buy at UNIT pricing because the quantity to buy stepper is used for both unit and quantity price.
     A property observer set the quantityToBuyLabel
     */
    private var quantityToBuyAtUnit: Int = 0 {
        didSet {
            quantityToBuyLabel.text = String(quantityToBuyAtUnit)
        }
    }
    
    /**
     I need a stored property for quantity to buy at BUNDLE pricing because the quantity to buy stepper is used for both unit and quantity price.
     A property observer set the quantityToBuyLabel
     */
    private var quantityToBuyAtBundle: Int = 0 {
        didSet {
            quantityToBuyLabel.text = String(quantityToBuyAtBundle)
        }
    }
    
    
    @IBOutlet weak var selectedPriceTypeSc: UISegmentedControl!
    
    /**
     Event causes the display of relevent pricing information and hiding of irrelevant pricing information depending on the price type.
    */
    @IBAction func onDisplayPriceTypeInformation(_ sender: UISegmentedControl) {
        
        if let priceType = PriceType(rawValue: sender.selectedSegmentIndex) {
            
            switch priceType {
            case .unit:
                bundleQtyStackView.isHidden = true
                unitPriceTextField.placeholder = "Unit price"
                unitPriceTextField.isHidden = false
                bundlePriceTextField.isHidden = true
                
            case .bundle:
                bundleQtyStackView.isHidden = false
                bundlePriceTextField.placeholder = "Bundle Price"
                unitPriceTextField.isHidden = true
                bundlePriceTextField.isHidden = false
            }
        }
    }
    
    /**
     The requirement is to sync the quantity to buy value with pricing info's bundle quantity when the selected price is bundle quantity.
     If the selected price is unit price, the quantity to buy value is NOT changed.
     */
    @IBAction func onBundleQtyChange(_ sender: UIStepper) {
        
        changeState.transition(event: .onChangeCharacters, handleNextStateUiAttributes: changeStateAttributeHandler)
        selectedPriceState.transition(event: .onBundleQtyChange(Int(sender.value), onBundleQtyChangeEventHandler), handleStateUiAttribute: nil)
    }
    
    /**
     The requirement is to sync the quantity to buy value with pricing info's bundle quantity when the selected price is bundle quantity.
     If the selected price is unit price, the quantity to buy value is NOT changed.
     The pricing info's bundle quantity will change at all times.
     */
    lazy var onBundleQtyChangeEventHandler: (SelectedPriceState, Int) -> Void = { selectedPriceState, newBundleQty in
        
        switch selectedPriceState {
        case .bundlePrice:
            self.quantityToBuyAtBundle = newBundleQty
            self.quantityToBuyStepperConvert = newBundleQty
            
            self.bundleQtyPricingInfoVc = newBundleQty
            
            //Set the stepper config for bundle pricing
            self.quantityToBuyStepper.minimumValue = Double(newBundleQty)
            self.quantityToBuyStepper.stepValue = Double(newBundleQty)
            
        case .unitPrice:
            
            //The pricing info's bundle quantity will change at all times.
            self.bundleQtyPricingInfoVc = newBundleQty
        }
    }
    
    /**
     The event of selecting the price type configures the behavior of the stepper to respond differently depending on selected price type.
     */
    @IBAction func onSelectPriceType(_ sender: UISegmentedControl) {
        changeState.transition(event: .onSelectPrice, handleNextStateUiAttributes: {
            changeState in
            
            switch changeState {
            case .changed:
                self.doneButton.isEnabled = true
                
            default:
                break
            }
        })
        
        let k = (PriceType(rawValue: sender.selectedSegmentIndex))!
        
        selectedPriceState.transition(event: .onSelectPriceType(k, onSelectPriceTypeEventHandler), handleStateUiAttribute: priceStateAttributeHandler)
    }
    
    /**
     The handler of the event of selecting the price type configures the behavior of the stepper to respond differently depending on selected price type. Because there is only one stepper for quantity to buy, for either unit or bundle price, I need to do book-keeping in order for the proper quantities to buy to be valid and not lost. Upon changing bundle price, use the stored property quantityToBuyAtBundle to update the quantity to buy label.
     */
    lazy var onSelectPriceTypeEventHandler: (PriceType) -> Void = { priceType in
        
        switch priceType {
        case .bundle:
            
            //Use the stored property quantityToBuyAtBundle to update the quantity to buy label
            if self.quantityToBuyAtBundle == 0 {
                self.quantityToBuyAtBundle = self.bundleQtyPricingInfoVc ?? 2
                
            } else {
                //Artificially set the value to notify property observer
                self.quantityToBuyAtBundle = self.quantityToBuyAtBundle + 0
            }
            
            //Set the stepper config for bundle pricing
            self.quantityToBuyStepper.minimumValue = Double(self.bundleQtyPricingInfoVc ?? 2)
            self.quantityToBuyStepper.stepValue = self.quantityToBuyStepper.minimumValue
            
            //Set the stepper to the correct value for bundle price
            self.quantityToBuyStepperConvert = self.quantityToBuyAtBundle
            
        case .unit:
            
            //Update the quantity to buy to unit quantity
            if self.quantityToBuyAtUnit == 0 {
                self.quantityToBuyAtUnit = 1
            } else {
                //Artificially set the value to notify property observer
                self.quantityToBuyAtUnit = self.quantityToBuyAtUnit + 0
            }
            
            //Set the stepper config for bundle pricing
            self.quantityToBuyStepper.minimumValue = 1
            self.quantityToBuyStepper.stepValue = self.quantityToBuyStepper.minimumValue
            
            //Set the stepper to the correct value for unit price
            self.quantityToBuyStepperConvert = self.quantityToBuyAtUnit
        }
        
    }
    
    /**
     The logic depends on the state of the selected price type. The event of selecting the price type configures the behavior of the stepper to respond differently depending on selected price type.
    */
    @IBAction func onChangeQtyToBuy(_ sender: UIStepper) {
        
        selectedPriceState.transition(event: .onChangeQtyToBuy(onChangeQtyToBuyEventHandler), handleStateUiAttribute: priceStateAttributeHandler)
        changeState.transition(event: .onChangeCharacters, handleNextStateUiAttributes: changeStateAttributeHandler)
    }
    
    /**
     The handler uses quantityToBuyStepper control to set the quantity to buy display. Prior to this event, the event of selecting the price type configures the behavior of the stepper to respond differently depending on selected price type.
     */
    lazy var onChangeQtyToBuyEventHandler: (SelectedPriceState) -> Void = { selectedPriceState in
        
        switch selectedPriceState {
        case .bundlePrice:
            
            //Update the quantity to buy to bundle quantity
            self.quantityToBuyAtBundle = self.quantityToBuyStepperConvert
            
        case .unitPrice:
            
            //Update the quantity to buy to bundle quantity
            self.quantityToBuyAtUnit = self.quantityToBuyStepperConvert
        }
        
    }
    
    /**
     Control the state of quantity to buy stepper
     */
    var priceStateAttributeHandler: (SelectedPriceState) -> Void {
        
        return { selectedPrice in
            
            switch selectedPrice {
            case .bundlePrice:
                
                //Show bundle pricing information
                self.pricingInformationSc.selectedSegmentIndex = SelectedPriceState.bundlePrice.rawValue
                self.onDisplayPriceTypeInformation(self.pricingInformationSc)
                
                //Display the price type chosen
                self.selectedPriceTypeSc.selectedSegmentIndex = SelectedPriceState.bundlePrice.rawValue
                
            case .unitPrice:
                
                //Show unit pricing informationß∫
                self.pricingInformationSc.selectedSegmentIndex = SelectedPriceState.unitPrice.rawValue
                self.onDisplayPriceTypeInformation(self.pricingInformationSc)
                
                //Display the price type chosen
                self.selectedPriceTypeSc.selectedSegmentIndex = SelectedPriceState.unitPrice.rawValue
            }
        }
        
    }
    
    // MARK: - Create, Read, Update, Delete
    
    /**
     Save new item
     */
    fileprivate func saveNew() {
        
        let moc = persistentContainer.viewContext
        
        do {
            let isExist = try Item.isNameExist(itemNameTextField.text!, moc: moc)
            
            if isExist {
                
                itemNameTextField.errorText = "Name already exist"
                return
            }
            
            let item = Item(context: moc)
            item.name = itemNameTextField.text!
            item.brand = brandTextField.text
            item.countryOfOrigin = countryOriginTextField.text
            item.itemDescription = descriptionTextField.text
            handlePictureEventAction(of: item, in: moc)
            updateUnitPrice(of: item)
            updateBundlePrice(of: item)
            
            let shoppingLineItem = shoppingList.add(item: item, quantity: quantityToBuyStepperConvert)
            
            shoppingLineItem.priceTypeSelectedConvert = selectedPriceState.rawValue
            
            try persistentContainer.viewContext.save()
            
            persistentContainer.viewContext.refresh(shoppingLineItem, mergeChanges: true)
            
        } catch  {
            let nserror = error as NSError
            print(">>>>>\(nserror) : \(nserror.userInfo)")
        }
    }
    
    /**
     Save existing item
     */
    fileprivate func saveUpdate() {
        
        let moc = persistentContainer.viewContext
        
        handlePictureEventAction(of: (shoppingListItem?.item)!, in: moc)
        
        shoppingListItem?.item?.countryOfOrigin = countryOriginTextField.text
        shoppingListItem?.item?.brand = brandTextField.text
        shoppingListItem?.item?.itemDescription = descriptionTextField.text
        shoppingListItem?.quantityToBuyConvert = quantityToBuyStepperConvert
        shoppingListItem?.priceTypeSelectedConvert = selectedPriceState.rawValue
        print(">>>>\(#function) - \(selectedPriceState.rawValue)")
        
        updateUnitPrice(of: (shoppingListItem?.item)!)
        updateBundlePrice(of: (shoppingListItem?.item)!)
        
        do {
            if let hasChanges = shoppingListItem?.managedObjectContext?.hasChanges, hasChanges {
                try shoppingListItem?.managedObjectContext?.save()
            }
            
            if shoppingListItem != nil {
                persistentContainer.viewContext.refresh(shoppingListItem!, mergeChanges: true)
            }
        } catch  {
            let nserror = error as NSError
            print(">>>>Error \(nserror) : \(nserror.userInfo)")
        }
    }
    
    private func updateUnitPrice(of item: Item) {
        
        if unitPrice == nil {
            //Create new price
            unitPrice = Price(context: persistentContainer.viewContext)
            item.addToPrices(unitPrice!)
        }
        
        unitPrice?.currencyCode = "SGD"
        unitPrice?.quantityConvert = 1
        print(">>>>\(#function) - \(unitPriceVc!)")
        unitPrice?.valueConvert = unitPriceVc ?? 0
        unitPrice?.type = 0
    }
    
    private func updateBundlePrice(of item: Item) {
        
        if bundlePrice == nil {
            //New bundle price
            bundlePrice = Price(context: persistentContainer.viewContext)
            item.addToPrices(bundlePrice!)
        }
        
        bundlePrice?.currencyCode = "SGD"
        bundlePrice?.valueConvert = bundlePriceVc ?? 0
        bundlePrice?.quantityConvert = bundleQtyPricingInfoVc ?? 2
        bundlePrice?.type = 1
    }
    
    @IBAction func onDeleteItem(_ sender: UIButton) {
        
        validationState.handle(event: .onDelete({ state in
            
            switch state {
                
            case .existingItem:
                self.deleteItemFromShoppingList()
                self.presentingViewController?.dismiss(animated: true, completion: nil)
                
            default:
                break
            }
            
        }), handleNextStateUiAttributes: nil)
    }
    
    
    private func deleteItemFromShoppingList() {
        
        if let stringPath = shoppingListItem?.item?.picture?.fileUrl {
            deletePicture(at: stringPath)
        }
        
        let moc = persistentContainer.viewContext
        
        moc.delete(shoppingListItem!)
        
        do {
            try moc.save()
        } catch {
            let nserror = error as NSError
            print("Error \(nserror) : \(nserror.userInfo)")
        }
    }
    
    // MARK: - Picture
    
    @IBAction func onPictureAction(_ sender: UIButton) {
        
        //Create a action sheet
        let pictureActionSheetController = pictureActionSheet
        
        //The following will cause app to adapt to iPad by presenting action sheet as popover on an iPad.
        pictureActionSheetController.modalPresentationStyle = .popover
        let popoverMenuPresentationController = pictureActionSheetController.popoverPresentationController
        popoverMenuPresentationController?.sourceView = sender
        popoverMenuPresentationController?.sourceRect = sender.frame
        present(pictureActionSheetController, animated: true, completion: nil)
    }
    
    // MARK: - State: Handle validation state transition and state-based ui properties
    
    lazy var validationStateUiPropertiesHandler: (ValidationState) -> Void = { nextState in
        
        switch nextState {
        case .newItem:
            self.deleteItemButton.isHidden = true
            
            let selectedPriceTypeEvent = SelectedPriceState.Event.onSelectPriceType(.unit, nil)
            self.selectedPriceState.transition(event: selectedPriceTypeEvent, handleStateUiAttribute: self.priceStateAttributeHandler)
            self.itemNameTextField.errorText = nil
            
        case .existingItem:
            
            self.itemNameTextField.text = self.shoppingListItem?.item?.name
            self.brandTextField.text = self.shoppingListItem?.item?.brand
            //self.q = self.shoppingListItem?.quantityToBuyConvert ?? 1
            
            self.quantityToBuyStepper.value = Double((self.shoppingListItem?.quantityToBuyConvert) ?? 1)
            self.countryOriginTextField.text = self.shoppingListItem?.item?.countryOfOrigin
            self.descriptionTextField.text = self.shoppingListItem?.item?.itemDescription
            self.pictureState.transition(event: .onExist, handleNextStateUiAttributes: self.nextPictureStateUiAttributes)
            
            //Although I can traverse from item to get prices of type NSSet, it is difficult to work with NSSet.
            //Therefore I do a fetch prices to get an array of prices at the cost of a round trip to database
            self.prices = try! Price.findPrices(of: (self.shoppingListItem?.item)!, moc: self.persistentContainer.viewContext)
            
            self.itemNameTextField.isEnabled = false
            self.deleteItemButton.isHidden = false
            
            let k = self.shoppingListItem?.priceTypeSelectedConvert ?? PriceType.unit.rawValue
            let savedSelectedPriceType = PriceType(rawValue:k)!
            
            switch savedSelectedPriceType {
                
            case .unit:
                self.quantityToBuyAtUnit = self.shoppingListItem?.quantityToBuyConvert ?? 1
            case .bundle:
                self.quantityToBuyAtBundle = self.shoppingListItem?.quantityToBuyConvert ?? 2
            }
            
            let selectedPriceTypeEvent = SelectedPriceState.Event.onSelectPriceType(savedSelectedPriceType, self.onSelectPriceTypeEventHandler)
            
            self.selectedPriceState.transition(event: selectedPriceTypeEvent, handleStateUiAttribute: self.priceStateAttributeHandler)
            
            self.itemNameTextField.errorText = nil
            
        default:
            break
        }
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destinationViewController.
     // Pass the selected object to the new view controller.
     }
     */
}

// MARK: - State: Handle picture actions and states

extension ShoppingListItemEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var pictureActionSheet: UIAlertController {
        //Create a action sheet
        let pictureActionSheet = UIAlertController(title: "Show a picture of the item", message: nil, preferredStyle: .actionSheet)
        
        //HIG: A Cancel button instills confidence when the user is abandoning a task. Cancel button will not be displayed in iPad.
        pictureActionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        switch pictureState {
        case .none, .delete:
            break
        default:
            //HIG: Make destructive choices prominent. Use red for buttons that perform destructive or dangerous actions, and display these buttons at the top of an action sheet.
            pictureActionSheet.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: onPictureActionHandler))
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            pictureActionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: onPictureActionHandler))
        }
        
        pictureActionSheet.addAction(UIAlertAction(title: "Album", style: .default, handler: nil))
        
        return pictureActionSheet
    }
    
    var onPictureActionHandler: (UIAlertAction) -> Void {
        get {
            return { action in
                switch action.title! {
                case "Camera":
                    self.activateCamera()
                case "Delete":
                    self.pictureState.transition(event: .onDelete, handleNextStateUiAttributes: self.nextPictureStateUiAttributes)
                    self.changeState.transition(event: .onDeletePicture, handleNextStateUiAttributes: self.changeStateAttributeHandler)
                default:
                    break
                }
            }
        }
    }
    
    var nextPictureStateUiAttributes: (PictureState, UIImage?) -> Void {
        
        return { (pictureState: PictureState, newItemPicture: UIImage?) -> Void in
            
            switch pictureState {
                
            case .delete, .none:
                self.itemImage = UIImage(named: "empty-photo")
                
            case .new:
                self.itemImage = newItemPicture!
                
            case .existing:
                if let pictureStringPath = self.shoppingListItem?.item?.picture?.fileUrl {
                    self.itemImage = UIImage(contentsOfFile: pictureStringPath)
                }
                
            case .replacement:
                self.itemImage = newItemPicture!
            }
        }
    }
    
    func writePicturePickedFromCameraToFile() -> URL? {
        
        if let image = itemImage {
            let cameraUtil = CameraUtil()
            return cameraUtil.persistImage(data: image)
        } else {
            return nil
        }
    }
    
    /**
     Depending on picture state, the image file will either be written/deleted to/from app document folder
     */
    func handlePictureEventAction(of item: Item, in moc: NSManagedObjectContext) {
        
        pictureState.transition(event: .onSaveImage({ pictureState in
            
            switch pictureState {
                
            case .new:
                let itemImageUrl = self.writePicturePickedFromCameraToFile()
                if let itemImageUrl = itemImageUrl {
                    let newPicture = Picture(context: moc)
                    newPicture.fileUrl = itemImageUrl.path
                    item.picture = newPicture
                }
                
            case .replacement:
                
                let fileMgr = FileManager.default
                if let imageStringPath = item.picture?.fileUrl {
                    do {
                        //Delete existing picture from document folder
                        try fileMgr.removeItem(atPath: imageStringPath)
                        
                        //Delete existing picture from database
                        moc.delete(item.picture!)
                        
                        let itemImageUrl = self.writePicturePickedFromCameraToFile()
                        
                        //Create new picture
                        if let itemNewImageUrl = itemImageUrl{
                            let newPicture = Picture(context: moc)
                            newPicture.fileUrl = itemNewImageUrl.path
                            item.picture = newPicture
                        }
                    } catch {
                        let nserror = error as NSError
                        print("\(#function) Failed to delete previous picture from document folder -> \(nserror): \(nserror.userInfo)")
                    }
                }
                
            case .delete:
                let fileMgr = FileManager.default
                if let imageStringPath = item.picture?.fileUrl {
                    do {
                        //Delete existing picture from document folder
                        try fileMgr.removeItem(atPath: imageStringPath)
                        
                        //Delete picture from database
                        moc.delete(item.picture!)
                        
                    } catch {
                        let nserror = error as NSError
                        print("\(#function) Failed to delete existing picture from document folder -> \(nserror): \(nserror.userInfo)")
                    }
                }
                
            default:
                break
            }
        }))
    }
    
    /**
     Delete picture from app document folder
     */
    func deletePicture(at pathString: String) {
        let fileMgr = FileManager.default
        do {
            try fileMgr.removeItem(atPath: pathString)
        } catch {
            let nserror = error as NSError
            print("\(#function) Failed to delete existing picture \(pathString) -> \(nserror): \(nserror.userInfo)")
        }
        
    }
    
    func activateCamera() {
        
        let cameraController = UIImagePickerController()
        cameraController.delegate = self
        cameraController.allowsEditing = false
        cameraController.sourceType = .camera
        cameraController.cameraCaptureMode = .photo
        cameraController.modalPresentationStyle = .fullScreen
        
        present(cameraController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let itemImage = info[UIImagePickerControllerOriginalImage] as! UIImage
        
        pictureState.transition(event: .onFinishPickingCameraMedia(itemImage), handleNextStateUiAttributes: nextPictureStateUiAttributes)
        
        changeState.transition(event: .onCameraCapture, handleNextStateUiAttributes: changeStateAttributeHandler)
        
        self.dismiss(animated: true, completion: { print("completion dismiss imagePickerVc")})
        
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        
        self.dismiss(animated: true, completion: nil)
    }
    
}

// MARK: - Handle change state transition event action and ui attributes
extension ShoppingListItemEditorViewController: UITextFieldDelegate {
    
    
    var changeStateAttributeHandler: (ChangeState) -> Void {
        return { changeState in
            
            switch changeState {
                
            case .changed:
                self.doneButton.isEnabled = true
                
            default:
                break
            }
            
        }
    }
    
    var changeStateOnCancelEventAction: (ChangeState) -> Void {
        return { (changeState: ChangeState) -> Void  in
            
            switch changeState {
                
            case .unchanged:
                
                self.performSegue(withIdentifier: "return to shopping list", sender: self)
                
            case .changed:
                //Alert vc will adapt. iPad will show as popover. iPhone present modally from bottom.
                let alertVc = UIAlertController(title: "Warning", message: "You may have unsaved change(s)", preferredStyle: .actionSheet)
                
                //Apple HIG
                alertVc.addAction(UIAlertAction(title: "Leave", style: .destructive) {
                    action in
                    self.presentingViewController?.dismiss(animated: true, completion: nil)
                })
                
                alertVc.addAction(UIAlertAction(title: "Stay", style: .cancel, handler: nil))
                alertVc.modalPresentationStyle = .popover
                let ppc = alertVc.popoverPresentationController
                ppc?.barButtonItem = self.cancelButton
                
                self.present(alertVc, animated: true, completion: nil)
                
            }
            
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        changeState.transition(event: .onChangeCharacters, handleNextStateUiAttributes: changeStateAttributeHandler)
        
        validationState.handle(event: .onChangeCharacters, handleNextStateUiAttributes: validationStateUiPropertiesHandler)
        
        return true
    }
}
