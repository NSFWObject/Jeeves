
//
//  AppController.swift
//  Jeeves
//
//  Created by Sash Zats on 3/29/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Cocoa


class AppController: NSObject, MenuManagerDelegate {
    private let recentsManager: RecentsManager
    private let menuManager: MenuManager
    weak var openPanel: NSOpenPanel?
    var serverManager: Server?
    
    override init() {
        self.recentsManager = RecentsManager()
        self.menuManager = MenuManager(recentsManager: self.recentsManager)
        super.init()
        self.menuManager.delegate = self
    }
    
    // MARK: - Public
    
    func checkForInitialHotkey() {
        let flags = NSEvent.modifierFlags() & NSEventModifierFlags.DeviceIndependentModifierFlagsMask
        let resetFlags: NSEventModifierFlags = .AlternateKeyMask | .ShiftKeyMask
        if flags == resetFlags {
            self.reset()
        }
    }
    
    // MARK: - Private
    
    private func reset() {
        self.recentsManager.reset()
    }

    private func setupServer(rootURL: NSURL) {
        self.menuManager.selectedURL = nil
        if let server = self.serverManager {
            server.stop()
        }
        
        let resolver = LocalURLResolver()
        let server = Server(rootURL: rootURL, resolver: resolver)
        var error: NSError?
        if !server.start(&error) {
            let alert = NSAlert(error: error!)
            alert.runModal()
            return
        }
        if let url = server.serverURL {
            NSWorkspace.sharedWorkspace().openURL(url)
        }
        self.menuManager.selectedURL = rootURL
        self.serverManager = server
    }

    private func showOpenFolder() {
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        if self.openPanel != nil {
            self.openPanel?.makeKeyAndOrderFront(nil)
            return
        }
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = false
        panel.canChooseFiles = false
        panel.hidesOnDeactivate = false
        panel.beginWithCompletionHandler({ result in
            if result == NSFileHandlingPanelOKButton {
                self.recentsManager.add(panel.URL!)
                self.setupServer(panel.URL!)
            }
        })
        self.openPanel = panel
    }

    // MARK: - MenuItemDelegate

    func menuManagerDidSelectOpen(menuManager: MenuManager) {
        showOpenFolder()
    }

    func menuManagerDidSelectQuit(menuManager: MenuManager) {
        NSApplication.sharedApplication().terminate(self)
    }

    func menuManager(menuManager: MenuManager, didSelectRecentWithURL url: NSURL) {
        if url.checkPromisedItemIsReachableAndReturnError(nil) {
            self.setupServer(url)
        } else {
            let alert = NSAlert(error: NSError(domain: "Hello", code: 0, userInfo: [
                    NSLocalizedDescriptionKey: "Failed to open \(url)"
            ]))
            alert.runModal()

            var recents = RecentsManager()
            recents.remove(url)
        }

    }

    func menuManagerDidSelectOptions(menuManager: MenuManager) {

    }
}