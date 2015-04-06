//
//  Server.swift
//  Jeeves
//
//  Created by Sash Zats on 4/5/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Foundation
import GCDWebServerOSX


class Server {
    let engine: GCDWebServer = GCDWebServer()
    var rootServerFolder: NSURL?
    var serverRootURL: NSURL? {
        get {
            return self.engine.running ? self.engine.serverURL : nil
        }
    }
    
    init() {
    }
    
    func start(rootServerFolder: NSURL) -> Bool {
        self.stop()
        
        self.rootServerFolder = rootServerFolder

        self.engine.removeAllHandlers()
        self.engine.addHandlerWithMatchBlock({ (method: String!, url: NSURL!, headers: [NSObject : AnyObject]!, path: String!, query: [NSObject : AnyObject]!) -> GCDWebServerRequest! in
            return GCDWebServerRequest(method: method, url: url, headers: headers, path: path, query: query)
        }, processBlock: { (request: GCDWebServerRequest!) -> GCDWebServerResponse! in
            return self.responseForRequest(request)
        })

        let options = [
            "Port": 8080,
            "ServerName": "Jeeves"
        ]
        return self.engine.startWithOptions(options, error: nil)
    }
    
    func stop() {
        if self.engine.running {
            self.engine.stop()
            self.rootServerFolder = nil
        }
    }
    
    // MARK: - Private
    
    private func responseForRequest(request: GCDWebServerRequest) -> GCDWebServerResponse {
        if let path = request.URL.path {
            if let serverFolder = self.rootServerFolder  {
                let fileURL = serverFolder.URLByAppendingPathComponent(path)
                
                // direct match
                if let response = self.directMatchForURL(fileURL) {
                    return response
                }
                
                // index
                if let response = self.indexMatchForURL(fileURL) {
                    return response
                }
                
                return self.erroneousResponse(code: 404, message: "<h1>Not Found</h1>\(request.URL.absoluteString!) did not match any resources")
            }
        }
        return self.erroneousResponse(code: 500, message: "<h1>Uh Oh</h1>Something went terribly wrong")
    }
    
    private func directMatchForURL(fileURL: NSURL) -> GCDWebServerResponse? {
        if isFileAtURL(fileURL) {
            let request = NSURLRequest(URL: fileURL)
            var response: NSURLResponse?
            if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: nil) {
                if response != nil {
                    return GCDWebServerDataResponse(data: data, contentType: response!.MIMEType)
                }
            }
        }
        return nil
    }
    
    private func indexMatchForURL(fileURL: NSURL) -> GCDWebServerResponse? {
        if isDirectoryAtURL(fileURL) {
            let indexURL = fileURL.URLByAppendingPathComponent("index.html")
            return self.directMatchForURL(indexURL)
        }
        return nil
    }
    
    private func erroneousResponse(#code: Int, message: String) -> GCDWebServerResponse {
        let response = GCDWebServerDataResponse(HTML: message)
        response.statusCode = code
        return response
    }
    
    private func isDirectoryAtURL(fileURL: NSURL) -> Bool {
        var isDrectory: ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(fileURL.relativePath!, isDirectory: &isDrectory) {
            return isDrectory.boolValue
        }
        return false
    }
    
    private func isFileAtURL(fileURL: NSURL) -> Bool {
        var isDrectory: ObjCBool = false
        if NSFileManager.defaultManager().fileExistsAtPath(fileURL.relativePath!, isDirectory: &isDrectory) {
            return !isDrectory.boolValue
        }
        return false
    }
}