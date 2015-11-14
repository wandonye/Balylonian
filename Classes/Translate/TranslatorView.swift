//
//  TranslatorView.swift
//  app
//
//  Created by Dongning Wang on 11/14/15.
//  Copyright © 2015 KZ. All rights reserved.
//

import UIKit

class TranslatorView: ChatView, AVAudioRecorderDelegate {
    var audioRecorder: AVAudioRecorder!
    var filePathStr: String!
    let voiceButton = UIButton()
    let cameraButton = UIButton()
    let pictureButton = UIButton()
    let textButton = UIButton()
    let topTapbar = TopTabBar()
    
    override init!(with groupId_: String!) {
        super.init(with: groupId_)
        self.tabBarItem.image = UIImage(named: "tab_groups.png")
        self.tabBarItem.selectedImage = UIImage(named: "tab_groups.png")
    }
    
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
        
        self.inputToolbar?.hidden = true
        self.navigationController?.navigationBarHidden = true
        // Do any additional setup after loading the view.
        let viewXmax = UIScreen.mainScreen().bounds.width
        let buttonWidth = (viewXmax-110)/4
        
        voiceButton.setTitle("Press and Hold", forState: .Normal)
        voiceButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        voiceButton.frame = CGRectMake(0, 0, 100, 100)
        voiceButton.setImage(UIImage(named: "mic_normal.png") as UIImage?, forState: .Normal)
        voiceButton.addTarget(self, action: "startRecord:", forControlEvents: .TouchDown)
        voiceButton.addTarget(self, action: "stopRecord:", forControlEvents: .TouchUpInside)
        voiceButton.addTarget(self, action: "cancelRecord:", forControlEvents: .TouchUpOutside)
        
        topTapbar.frame = CGRectMake(0, 0, viewXmax, 48)
        self.view.addSubview(topTapbar)
        var center = self.topTapbar.center
        center.y = center.y + 26
        voiceButton.center = center
        self.view.addSubview(voiceButton)
        
        
        cameraButton.setTitle("Camera", forState: .Normal)
        //cameraButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        cameraButton.tintColor = UIColor.blackColor()
        cameraButton.frame = CGRectMake(0, 0, buttonWidth, 32)
        center.y = center.y - 6
        center.x = viewXmax -  buttonWidth/2
        cameraButton.center = center
        cameraButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        cameraButton.setImage(UIImage(named: "camera_gray.png") as UIImage?, forState: .Normal)
        cameraButton.addTarget(self, action: "startCamera:", forControlEvents: .TouchDown)
        self.view.addSubview(cameraButton)
        
        pictureButton.setTitle("Picture", forState: .Normal)
        pictureButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        pictureButton.frame = CGRectMake(0, 0, buttonWidth, 32)
        center.x = center.x - buttonWidth
        pictureButton.center = center
        pictureButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        pictureButton.setImage(UIImage(named: "pictures_gray.png") as UIImage?, forState: .Normal)
        pictureButton.addTarget(self, action: "addPicture:", forControlEvents: .TouchDown)
        self.view.addSubview(pictureButton)
        
        textButton.setTitle("Text", forState: .Normal)
        textButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        textButton.frame = CGRectMake(0, 0, buttonWidth, 32)
        center.x = buttonWidth/2
        textButton.center = center
        textButton.imageView?.contentMode = UIViewContentMode.ScaleAspectFit
        textButton.setImage(UIImage(named: "text_gray.png") as UIImage?, forState: .Normal)
        textButton.addTarget(self, action: "textMessage:", forControlEvents: .TouchDown)
        self.view.addSubview(textButton)
    }
    
    override func viewWillAppear(animated: Bool) {
        if (PFUser.currentUser() == nil)
        {
            ParentLoginUser(self)
        }
        if (self.senderId == nil){
            self.senderId = PFUser.currentId()
            self.senderDisplayName = PFUser.currentName()
        }
        super.viewWillAppear(animated)
    }
    
    func textMessage(sender:UIButton!) {
        if self.inputToolbar?.hidden == true {
            self.inputToolbar?.hidden = false
        }
        else {
            self.inputToolbar?.hidden = false
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func startRecord(sender:UIButton!) {
        let image = UIImage(named: "mic_talk.png") as UIImage?
        voiceButton.setImage(image, forState: .Normal)
        //Unique recording URL
        let fileName = NSProcessInfo.processInfo().globallyUniqueString + ".m4a"
        self.filePathStr = NSTemporaryDirectory() + fileName
        self.record()
    }
    func stopRecord(sender:UIButton!) {
        let image = UIImage(named: "mic_normal.png") as UIImage?
        voiceButton.setImage(image, forState: .Normal)
        //TODO check self.recordingFilePath, caution about touch down outside and up inside
        self.audioRecorder.stop()
        self.messageSend(nil, video:nil, picture:nil, audio:"\(self.filePathStr)")
        self.collectionView?.reloadData()
    }
    func cancelRecord(sender:UIButton!) {
        let image = UIImage(named: "mic_normal.png") as UIImage?
        voiceButton.setImage(image, forState: .Normal)
    }
    func addPicture(sender:UIButton!) {
        PresentPhotoLibrary(self, true)
    }
    
    func startCamera(sender:UIButton!) {
        PresentMultiCamera(self, true)
    }
    
    func record() {
        //init
        let audioSession:AVAudioSession = AVAudioSession.sharedInstance()
        
        //ask for permission
        if (audioSession.respondsToSelector("requestRecordPermission:")) {
            AVAudioSession.sharedInstance().requestRecordPermission({(granted: Bool)-> Void in
                if granted {
                    //print("granted")
                    
                    //set category and activate recorder session
                    try! audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
                    try! audioSession.setActive(true)
                    
                    //create AnyObject of settings
                    
                    let settings: [String : AnyObject] = [
                        AVFormatIDKey:Int(kAudioFormatMPEG4AAC), //Int required in Swift2
                        AVSampleRateKey:44100.0,
                        AVNumberOfChannelsKey:2
                    ]
                    
                    //record
                    if let url = NSURL(string: self.filePathStr) {
                        self.audioRecorder = try? AVAudioRecorder(URL: url, settings: settings)
                        self.audioRecorder.delegate = self
                        self.audioRecorder.meteringEnabled = true
                        self.audioRecorder.prepareToRecord()
                        self.audioRecorder.record()
                    }
                    else {
                        print("error")
                    }
                    
                } else{
                    print("not granted")
                    return
                }
            })
        }
        
    }
    
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using segue.destinationViewController.
    // Pass the selected object to the new view controller.
    }
    */
    
}
