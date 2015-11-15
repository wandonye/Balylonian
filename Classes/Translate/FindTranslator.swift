//
//  FindTranslator.swift
//  app
//
//  Created by Dongning Wang on 11/14/15.
//  Copyright © 2015 KZ. All rights reserved.
//

func findTranslator()->PFObject? {
    let users = PFQuery(className: "username")
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