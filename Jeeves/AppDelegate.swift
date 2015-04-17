//
//  AppDelegate.swift
//  Jeeves
//
//  Created by Sash Zats on 3/28/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Cocoa
import Fabric
import Crashlytics
import GCDWebServerOSX


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    let menuItem = MenuItem()
    let server: Server = Server()
    weak var openPanel: NSOpenPanel?
    
    // MARK: - Private
    
    private func startServer(serverFolder: NSURL) {
        if self.server.start(serverFolder) {
            self.menuItem.serverFolderName = serverFolder.lastPathComponent!
            if let url = self.server.serverRootURL {
                NSWorkspace.sharedWorkspace().openURL(url)
            }
        }
    }
    
    private func stopServer() {
        self.menuItem.serverFolderName = nil
        self.server.stop()
    }

    // MARK: - Menu Handlers
    
    func openMenuAction() {
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        if self.openPanel == nil {
            let panel = NSOpenPanel()
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false
            panel.canCreateDirectories = false
            panel.canChooseFiles = false
            panel.hidesOnDeactivate = false
            panel.beginWithCompletionHandler({ result in
                if result == NSFileHandlingPanelOKButton {
                    if let url = panel.URL {
                        self.startServer(url)
                    }
                }
            })
            self.openPanel = panel
        }
        self.openPanel!.makeKeyAndOrderFront(self)
    }
    
    func stopMenuAction() {
        self.stopServer()
    }
    
    func openServerFolderMenuAction() {
        if let url = self.server.rootServerFolder {
            NSWorkspace.sharedWorkspace().openFile(url.relativePath!)
        }
    }
    
    func quitMenuAction() {
        NSApplication.sharedApplication().terminate(self)
    }

    // MARK: - NSApplicationDelegate
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        Fabric.with([Crashlytics()])
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        self.stopServer()
    }
}
