//
//  TranslateView.swift
//  app
//
//  Created by Dongning Wang on 11/6/15.
//  Copyright © 2015 KZ. All rights reserved.
//

import UIKit
import Firebase

class TranslateView: JSQMessagesViewController {
    
    var groupId: NSString!
    var initialized: Bool = false
    var firebase1: Firebase!
    
    var loaded: NSInteger = 0
    var loads: NSMutableArray = []
    var items: NSMutableArray = []
    var messages: NSMutableArray = []
    var started: NSMutableDictionary = NSMutableDictionary()
    var avatars: NSMutableDictionary = NSMutableDictionary()
    
    var bubbleImageOutgoing: JSQMessagesBubbleImage!
    var bubbleImageIncoming: JSQMessagesBubbleImage!
    var avatarImageBlank: JSQMessagesAvatarImage!
    
    init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?, groupId: NSString) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        self.groupId = groupId
    }
    
    required init(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)!
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = PFUser.currentUser()?.objectId
        self.senderDisplayName = PFUser.currentUser()?.username
        inputToolbar!.hidden = true


        // Do any additional setup after loading the view.
        let bubbleFactory = JSQMessagesBubbleImageFactory()
        
        bubbleImageOutgoing = bubbleFactory.outgoingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleLightGrayColor())
        bubbleImageIncoming = bubbleFactory.incomingMessagesBubbleImageWithColor(UIColor.jsq_messageBubbleGreenColor())
        
        avatarImageBlank = JSQMessagesAvatarImageFactory.avatarImageWithImage(UIImage(named: "chat_blank"), diameter: 30)
        
        firebase1 = Firebase(url: FIREBASE+"/Message/"+(groupId as String))

        self.loadMessages()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func loadMessages() -> Void{
        initialized = true
        self.automaticallyScrollsToMostRecentMessage = false
        
        firebase1.observeEventType(.ChildAdded, withBlock: {snapshot in

            if (self.initialized){
                let incoming:Bool = self.addMessage(snapshot.value as! NSDictionary)
                print("\(snapshot.key) -> \(snapshot.value)")
                if (incoming){
                    JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                }
                self.finishReceivingMessage()
            }
            else {
                self.loads.addObject(snapshot.value)
            }
        })
        firebase1.observeEventType(.ChildRemoved, withBlock: {snapshot in
            self.deleteMessage(snapshot.value as! NSDictionary)
        })
        firebase1.observeEventType(.ChildChanged, withBlock: {snapshot in
            self.updateMessage(snapshot.value as! NSDictionary)
        })
        firebase1.observeSingleEventOfType(.Value, withBlock: {snapshot in
            self.insertMessages()
            self.scrollToBottomAnimated(false)
            self.initialized = true
        })
        
    }

    func addMessage(item: NSDictionary) -> Bool{
        let incoming:Incoming = Incoming.init(with: self.groupId as String, collectionView: self.collectionView)
        let message:JSQMessage = incoming.create(item as [NSObject : AnyObject])
        items.addObject(item)
        messages.addObject(message)
        return self.incoming(item)
    }
    
    func incoming(item: NSDictionary) -> Bool{
        return self.senderId != (item["userId"] as! String)
    }
    
    func updateMessage(item: NSDictionary) -> Void{
        for index in 0...items.count{
            let temp:NSDictionary = items[index] as! NSDictionary
            if (item["messageId"] as! String) == (temp["messageId"] as! String){
                items[index] = item
                self.collectionView?.reloadData()
                break
            }
        }
    }
    func deleteMessage(item: NSDictionary) -> Void{
        for index in 0...items.count{
            let temp:NSDictionary = items[index] as! NSDictionary
            if (item["messageId"] as! String) == (temp["messageId"] as! String){
                items.removeObjectAtIndex(index)
                messages.removeObjectAtIndex(index)
                self.collectionView?.reloadData()
                break
            }
        }
    }
    
    func insertMessages() -> Void{
        let max:NSInteger = loads.count-loaded
        var min:NSInteger = max-10
        if min<0 {
            min = 0
        }
        for var index = max-1; index >= min; index-- {
            let item:NSDictionary = loads[index] as! NSDictionary
            self.insertMessage(item as [NSObject : AnyObject])
            loaded++
        }
    }
    
    func insertMessage(item: [NSObject : AnyObject]!) -> Bool{
        print("Count: \(item.count)")
        let incoming:Incoming = Incoming.init(with: self.groupId as String, collectionView: self.collectionView)
        let message:JSQMessage = incoming.create(item)
        items.insertObject(item, atIndex: 0)
        messages.insertObject(message, atIndex: 0)
        return self.incoming(item)
    }
    
    func loadAvatar(senderId: NSString) -> Void{
        if (self.started[senderId] == nil) {
            self.started[senderId] = true
        }
        else{
            return
        }
        if (senderId==PFUser.currentId()){
            self.downloadThumbnail(PFUser.currentUser()!)
            return
        }
        
        let query:PFQuery = PFQuery(className: PF_USER_CLASS_NAME)
        query.whereKey(PF_USER_OBJECTID, equalTo: senderId)
        query.findObjectsInBackgroundWithBlock({(objects:[PFObject]?, error: NSError?) in
            if(error == nil){
                if (objects!.count != 0){
                    if let user = objects?.first as? PFUser {
                        self.downloadThumbnail(user)
                    }
                    else{
                        self.started.removeObjectForKey(senderId)
                    }
                }
            }
            else{
                self.started.removeObjectForKey(senderId)
            }
        })
    }
    
    func downloadThumbnail(user: PFUser) -> Void{
        AFDownload.start(user[PF_USER_THUMBNAIL] as! String, complete: {(path: String!, error: NSError!, network: Bool) in
            if error == nil {
                let image: UIImage = UIImage(contentsOfFile: path)!
                self.avatars[user.objectId!] = JSQMessagesAvatarImageFactory.avatarImageWithImage(image, diameter: 30)
                self.performSelector("delayedReload", withObject: nil, afterDelay: 0.1)
            }
            else {
                self.started.removeObjectForKey(user.objectId!)
            }
        })
    }
    
    func delayedReload() -> Void {
        self.collectionView?.reloadData()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item] as! JSQMessageData
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        if self.senderId == (items[indexPath.item]["userId"] as! String){
            return bubbleImageOutgoing
        }
        else{
            return bubbleImageIncoming
        }
    }

    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let message: JSQMessage = messages[indexPath.item] as! JSQMessage
        if (avatars[message.senderId] == nil)
        {
            self.loadAvatar(message.senderId)
            return avatarImageBlank;
        }
        else{
            return avatars[message.senderId] as! JSQMessageAvatarImageDataSource
        }
    }
    
    
    //CellTopLabel
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if (indexPath.item % 3 == 0)
        {
            let message :JSQMessage = messages[indexPath.item] as! JSQMessage
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.date)
        }
        else{
            return nil
        }
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if (indexPath.item % 3 == 0){
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        else{
            return 0
        }
    }
    
    // MessageBubbleTopLabel
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if !(self.senderId == (items[indexPath.item]["userId"] as! String))
        {
            let message: JSQMessage = messages[indexPath.item] as! JSQMessage
            if (indexPath.item > 0)
            {
                let previous: JSQMessage = messages[indexPath.item-1] as! JSQMessage
                if (previous.senderId == message.senderId)
                {
                    return nil
                }
            }
            return NSAttributedString(string: message.senderDisplayName)
        }
        else{
            return nil
        }
        
    }
    
    // CellBottomLabel
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let item: NSDictionary = items[indexPath.item] as! NSDictionary
        if (self.senderId == (items[indexPath.item]["userId"] as! String))
        {
            return NSAttributedString(string: item["status"] as! String)
        }
        else{
            return nil
        }
    }
    
    // MessageBubbleTopLabel height
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if (self.senderId == (items[indexPath.item]["userId"] as! String)) {
            return 0;
        }
        else{
            if indexPath.row > 1 {
                let previous = messages[indexPath.item-1] as! JSQMessage
                let message = messages[indexPath.item]as! JSQMessage
                if previous.senderId == message.senderId {
                    return 0
                }
        }
        }
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    // CellBottomLabel height
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        return 0
    }
    
    // ------------------------------------------------------------------------
    // MARK: - Standard CollectionView handling
    // ------------------------------------------------------------------------
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell: JSQMessagesCollectionViewCell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell

        if ((items[indexPath.item]["type"] as! String) == "text") {
            if (self.senderId == (items[indexPath.item]["userId"] as! String)) {
                cell.textView!.textColor = UIColor.whiteColor()
            } else {
                cell.textView!.textColor = UIColor.blackColor()
            }
            cell.textView!.linkTextAttributes = [NSForegroundColorAttributeName : cell.textView!.textColor!,NSUnderlineStyleAttributeName : NSUnderlineStyle.StyleSingle.rawValue]
        }
        return cell
    }
/*
    UIColor *color = [self outgoing:items[indexPath.item]] ? [UIColor whiteColor] : [UIColor blackColor];
    
    JSQMessagesCollectionViewCell *cell = (JSQMessagesCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    cell.textView.textColor = color;
    cell.textView.linkTextAttributes = @{NSForegroundColorAttributeName:color};
    
    return cell;
*/

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
