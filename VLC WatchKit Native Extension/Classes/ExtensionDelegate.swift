/*****************************************************************************
* ExtensionDelegate.swift
* VLC for iOS
*****************************************************************************
* Copyright (c) 2015 VideoLAN. All rights reserved.
* $Id$
*
* Authors: Tobias Conradi <videolan # tobias-conradi.de>
*
* Refer to the COPYING file of the official project for license.
*****************************************************************************/

import WatchKit
import WatchConnectivity
import CoreData
import MediaLibraryKit

class ExtensionDelegate: NSObject, WKExtensionDelegate, WCSessionDelegate, NSFileManagerDelegate {

    func applicationDidFinishLaunching() {
        // Perform any final initialization of your application.

        let additionalOptions = [NSReadOnlyPersistentStoreOption : NSNumber(bool: true)]

        let library = MLMediaLibrary.sharedMediaLibrary() as! MLMediaLibrary
        library.additionalPersitentStoreOptions = additionalOptions

        WCSession.defaultSession().delegate = self;
        WCSession.defaultSession().activateSession()
    }

    func session(session: WCSession, didReceiveMessage message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
        let msg = VLCWatchMessage(dictionary: message)
        if msg.name == VLCWatchMessageNameNotification, let payloadDict = msg.payload as? [String : AnyObject] {
            if let name = payloadDict["name"] as? String {
                handleRemoteNotification(name, userInfo: payloadDict["userInfo"] as? [String : AnyObject])
            }
        }
    }

    func handleRemoteNotification(name:String, userInfo: [String: AnyObject]?) {
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: self, userInfo: userInfo)
    }


    func session(session: WCSession, didReceiveFile file: WCSessionFile) {
        let fileType = file.metadata?["filetype"] as? String ?? ""
        if fileType == "coredata" {
            dispatch_sync(dispatch_get_main_queue())
            {
                self.copyUpdatedCoreDataDBFromURL(file.fileURL)
            }
        }
    }

    func copyUpdatedCoreDataDBFromURL(url:NSURL) {
        let library = MLMediaLibrary.sharedMediaLibrary() as! MLMediaLibrary
        library.overrideLibraryWithLibraryFromURL(url)
        NSNotificationCenter.defaultCenter().postNotificationName(VLCDBUpdateNotification, object: self)
    }

}