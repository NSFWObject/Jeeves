//
//  ServerConfigurationObserver.swift
//  Jeeves
//
//  Created by Sash Zats on 4/6/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Cocoa
import Runes
import Argo


public struct Route: JSONDecodable {
    let request: Request
    let response: Response

    private static func create(request: Request)(response: Response) -> Route {
        return Route(request: request, response: response)
    }

    // MARK: JSONDecodable
    
    public static func decode(j: JSONValue) -> Route? {
        return Route.create
            <^> j <| "request"
            <*> j <| "response"
    }
}

public struct Request: JSONDecodable {
    let method: String
    let pattern: String

    private static func create(method: String = "GET")(pattern: String) -> Request {
        return Request(method: method, pattern: pattern)
    }
    
    // MARK: JSONDecodable

    public static func decode(j: JSONValue) -> Request? {
        return Request.create
            <^> j <| "method"
            <*> j <| "pattern"
    }
}

public struct Response: JSONDecodable {
    let resourcePath: String
    let contentType: String?
    
    private static func create(resourcePath: String)(contentType: String?) -> Response {
        return Response(resourcePath: resourcePath, contentType: contentType)
    }
    
    // MARK: JSONDecodable

    public static func decode(j: JSONValue) -> Response? {
        return Response.create
            <^> j <| "resourcePath"
            <*> j <| "contentType"
    }
}

public class ServerConfiguration {
    private let folderURL: NSURL
    private(set) public var routes: [Route]
    private let configurationFileURL: NSURL
    private var folderObserver: FolderObserver!
    
    public init(folderURL: NSURL) {
        self.folderURL = folderURL
        self.configurationFileURL = folderURL.URLByAppendingPathComponent("jeeves.json")
        self.routes = []
        
        self.folderObserver = FolderObserver(folderURL: folderURL)
        self.folderObserver.subitemDidChange = { [weak self] (URL) in
            if URL == self?.configurationFileURL {
                self?.readWithCoordination()
            }
        }
        self.readWithCoordination()
    }
    
    deinit {
        self.folderObserver.stop()
    }
    
    // MARK: Private
        
    private func readWithCoordination() {
        self.folderObserver.readItemCoordinated(self.configurationFileURL) { [weak self] (URL) in
            var routes: [Route] = []
            if let data = NSData(contentsOfURL: URL) {
                if let jsonArray = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: nil) as? [String: AnyObject] {
                    if let routesArray = jsonArray["routes"] as? [AnyObject] {
                        for json in routesArray {
                            let j = JSONValue.parse(json)
                            if let route = Route.decode(j) {
                                routes.append(route)
                            }
                        }
                    }
                }
            }
            self?.routes = routes
        }
    }
}


class FolderObserver: NSObject, NSFilePresenter {
    private var folderURL: NSURL
    private var coordinator: NSFileCoordinator!
    var subitemDidChange: ((URL: NSURL) -> Void)!
    
    init(folderURL: NSURL) {
        self.folderURL = folderURL
        super.init()
        NSFileCoordinator.addFilePresenter(self)
        self.coordinator = NSFileCoordinator(filePresenter: self)
    }
    
    // MARK: Public
    
    func stop() {
        self.coordinator.cancel()
        // Coordinator retains presenter
        self.coordinator = nil
        NSFileCoordinator.removeFilePresenter(self)
    }
    
    func readItemCoordinated(itemURL: NSURL, readerBlock: (URL: NSURL) -> Void) {
        self.coordinator.coordinateReadingItemAtURL(itemURL, options: NSFileCoordinatorReadingOptions.WithoutChanges, error: nil) { (URL) -> Void in
            readerBlock(URL: URL)
        }
    }
    
    // MARK: - NSFilePresenter

    static let queue = NSOperationQueue()
    var presentedItemOperationQueue: NSOperationQueue {
        get {
            return FolderObserver.queue
        }
    }
    
    var presentedItemURL: NSURL? {
        get {
            return self.folderURL
        }
    }
    
    func presentedSubitemDidAppearAtURL(URL: NSURL) {
        self.subitemDidChange(URL: URL)
    }
    
    func presentedSubitemDidChangeAtURL(URL: NSURL) {
        self.subitemDidChange(URL: URL)
    }
}
