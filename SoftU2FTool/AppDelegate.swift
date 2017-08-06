//
//  AppDelegate.swift
//  U2FTouchID
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        if NSClassFromString("XCTest") != nil {
            // HACK: skip execution when being tested, since reading from stdin
            // hangs the test suite
            return
        }
        U2FRunner.run()
    }
    
    func applicationDidBecomeActive(_ notification: Notification) {
        // Chrome gives ignores our U2F responses if it isn't active when we send them.
        // This hack should give focus back to Chrome immediately after the user interacts
        // with our notification.
        NSApplication.shared().hide(nil)
    }
}
