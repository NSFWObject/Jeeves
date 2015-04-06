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


struct Route {
    let request: Request
    let response: Response
}

struct Request {
    let method: String
    let pattern: String
}

struct Response {
    let resourceURL: NSURL
    let contentType: String?
}


class JeevesDocument: NSDocument {
    private var route: Route?
    
    override func readFromData(data: NSData, ofType typeName: String, error outError: NSErrorPointer) -> Bool {
        if let json = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.allZeros, error: outError) {
            let j = JSONValue.parse(json)
            if let route = Route.decode(j) {
                self.route = route
            }
        }
        return false
    }
    
}

// MARK: - JSONDecodable

extension Request: JSONDecodable {
    private static func create(method: String = "GET")(pattern: String) -> Request {
        return Request(method: method, pattern: pattern)
    }
    
    static func decode(j: JSONValue) -> Request? {
        return Request.create
            <^> j <| "method"
            <*> j <| "pattern"
    }
}

extension Response: JSONDecodable {
    private static func create(resourceURL: NSURL)(contentType: String?) -> Response {
        return Response(resourceURL: resourceURL, contentType: contentType)
    }
    
    static func decode(j: JSONValue) -> Response? {
        return Response.create
            <^> j <| "resourceURL"
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
    
    static func decode(j: JSONValue) -> Route? {
        return Route.create
            <^> j <| "request"
            <*> j <| "response"
    }
}
