//
//  TranslateTabView.swift
//  app
//
//  Created by Dongning Wang on 11/14/15.
//  Copyright © 2015 KZ. All rights reserved.
//

import UIKit
import Firebase

class TranslateTabView: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate{
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var transButton: UIButton!
    @IBOutlet weak var statusSpinner: UIActivityIndicatorView!
    
    @IBOutlet weak var langPicker1: UIPickerView!
    
    @IBOutlet weak var langPicker2: UIPickerView!

    let pickerData = ["EN","CN"]
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.tabBarItem.image = UIImage(named: "tab_groups.png")
        self.tabBarItem.selectedImage = UIImage(named: "tab_groups.png")
    }
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)!
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Translate"
        langPicker1.dataSource = self
        langPicker1.delegate = self
        langPicker2.dataSource = self
        langPicker2.delegate = self
        self.statusSpinner.hidesWhenStopped = true
    }
    //MARK: - Delegates and data sources
    //MARK: Data Sources
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    
    @IBAction func startTransView(sender: AnyObject) {
        self.statusLabel.hidden = false
        //self.statusSpinner.startAnimating()
        self.transButton.enabled = false
        print(findTranslator()?.objectId)
        let transView = TransView.init(with: UIDevice.currentDevice().identifierForVendor?.UUIDString)
        
        self.navigationController?.pushViewController(transView, animated: true)
        //self.presentViewController(transView, animated: true, completion: nil)
    }
    
    func findTranslator()->PFObject? {
        let users = PFQuery(className: PF_USER_CLASS_NAME)
        //let users = PFUser.query()
        users.addDescendingOrder("updatedAt")
        do {
            return try users.getFirstObject()
        }
        catch {
            print("no user available")
        }
        return nil
    }
}
