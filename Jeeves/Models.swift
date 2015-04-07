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


public struct Route {
    let request: Request
    let response: Response
}

public struct Request {
    let method: String
    let pattern: String
}

public struct Response {
    let resourcePath: String
    let contentType: String?
}

public class JeevesDocument: NSObject, NSFilePresenter {
    private var fileURL: NSURL
    private(set) public var routes: [Route]
    private var coordinator: NSFileCoordinator!
    
    public init(fileURL: NSURL) {
        self.fileURL = fileURL
        self.routes = []
        super.init()
        
        NSFileCoordinator.addFilePresenter(self)
        self.coordinator = NSFileCoordinator(filePresenter: self)
        
        self.readWithCoordination()
    }
    
    deinit {
        NSFileCoordinator.removeFilePresenter(self)
    }
    
    // MARK: - Private
    
    private func readWithCoordination() {
        self.coordinator.coordinateReadingItemAtURL(self.fileURL, options: NSFileCoordinatorReadingOptions.WithoutChanges, error: nil) { (url) -> Void in
            var routes: [Route] = []
            if let data = NSData(contentsOfURL: url) {
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
            self.routes = routes
        }
    }

    // MARK: - NSFilePresenter
    
    public var presentedItemURL: NSURL? {
        get {
            return self.fileURL
        }
    }

    static let queue = NSOperationQueue()
    public var presentedItemOperationQueue: NSOperationQueue {
        get {
            return JeevesDocument.queue
        }
    }

    public func presentedItemDidChange() {
        self.readWithCoordination()
    }
    
    public func accommodatePresentedItemDeletionWithCompletionHandler(completionHandler: (NSError!) -> Void) {
        self.routes = []
        completionHandler(nil)
        NSFileCoordinator.removeFilePresenter(self)
    }
    
    public func presentedItemDidMoveToURL(newURL: NSURL) {
        self.fileURL = newURL
    }
}

// MARK: - JSONDecodable

extension Request: JSONDecodable {
    private static func create(method: String = "GET")(pattern: String) -> Request {
        return Request(method: method, pattern: pattern)
    }
    
    public static func decode(j: JSONValue) -> Request? {
        return Request.create
            <^> j <| "method"
            <*> j <| "pattern"
    }
}

extension Response: JSONDecodable {
    
    private static func create(resourcePath: String)(contentType: String?) -> Response {
        return Response(resourcePath: resourcePath, contentType: contentType)
    }
    
    public static func decode(j: JSONValue) -> Response? {
        return Response.create
            <^> j <| "resourcePath"
            <*> j <| "contentType"
    }
}

extension NSURL: JSONDecodable {
    public static func decode(j: JSONValue) -> NSURL? {
        switch j {
            case let .JSONString(s): return NSURL(fileURLWithPath: s)
            default: return nil
        }
    }
}

extension Route: JSONDecodable {
    private static func create(request: Request)(response: Response) -> Route {
        return Route(request: request, response: response)
    }
    
    public static func decode(j: JSONValue) -> Route? {
        return Route.create
            <^> j <| "request"
            <*> j <| "response"
    }
}
