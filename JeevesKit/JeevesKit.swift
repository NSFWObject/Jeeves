//
//  JeevesKit.swift
//  Jeeves
//
//  Created by Sash Zats on 3/28/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Foundation
import Argo
import Runes

// MARK: - Types

public enum RequestMethod: String {
    case OPTIONS = "OPTIONS"
    case GET = "GET"
    case HEAD = "HEAD"
    case POST = "POST"
    case PUT = "PUT"
    case PATCH = "PATCH"
    case DELETE = "DELETE"
    case TRACE = "TRACE"
    case CONNECT = "CONNECT"
}

public struct Request {
    let method: RequestMethod
    let URL: NSURL
}

public enum Response {
    case Success(URL: NSURL)
    case Failure(error: ResponseErrorCode)
}

public enum ResponseErrorCode: Int {
    case NotFound = 404
    case InternalError = 500
}

public struct Route {
    public let method: RequestMethod
    public let requestPath: String
    public let responseFileURL: NSURL
    
    public init(method: RequestMethod = .GET, requestPath: String, responseFileURL: NSURL) {
        self.method = method
        self.requestPath = requestPath
        self.responseFileURL = responseFileURL
    }
}

public struct RoutesCollection {
    let routes: [Route]
    
    init(routes: [Route]) {
        self.routes = routes
    }
    
    init?(jsonObject: AnyObject) {
        let j = JSONValue.parse(jsonObject)
        if let instance = RoutesCollection.decode(j) {
            self = instance
        } else {
            return nil
        }
    }
}

// MARK: - JSONDecodable

extension NSURL: JSONDecodable {
    public static func decode(j: JSONValue) -> NSURL? {
        switch j {
        case let .JSONString(s): return NSURL(fileURLWithPath: s)
        default: return nil
        }
    }
}

extension RequestMethod: JSONDecodable {
    public static func decode(j: JSONValue) -> RequestMethod? {
        switch j {
        case let .JSONString(s): return RequestMethod(rawValue: s)
        default: return nil
        }
    }
}

extension Route: JSONDecodable {
    internal static func create(method: RequestMethod = .GET)(requestPath: String)(responseFileURL: NSURL) -> Route {
        return Route(method: method, requestPath: requestPath, responseFileURL: responseFileURL)
    }
    
    public static func decode(j: JSONValue) -> Route? {
        return Route.create
            <^> j <| "method"
            <*> j <| "path"
            <*> j <| "resource"
    }
}

extension RoutesCollection: JSONDecodable {
    internal static func create(routes: [Route]) -> RoutesCollection {
        return RoutesCollection(routes: routes)
    }
    
    public static func decode(j: JSONValue) -> RoutesCollection? {
        return RoutesCollection.create
            <^> j <|| "routes"
    }
}

/*
extension Route {
    func isMatching(request: Request) -> Bool {
        return self.isStrictlyMatching(request) || self.isMatchingAsRegex(request)
    }
    
    func isStrictlyMatching(request: Request) -> Bool {
        return self.method == request.method && self.requestPath == request.URL.path!
    }
    
    func isMatchingAsRegex(request: Request) -> Bool {
        if let regex = NSRegularExpression(pattern: self.path, options: NSRegularExpressionOptions.CaseInsensitive, error: nil) {
            if let path = request.URL.path {
                return regex.numberOfMatchesInString(path, options: .Anchored, range: NSMakeRange(0, (path as NSString).length)) > 0
            } else {
                return false
            }
        } else {
            return false
        }
        
    }
}
*/

// MARK: - RequestMatcher

public protocol RequestMatcher {
    func match(#request: Request, resolver: URLResolver) -> RequestMatcherResult
}

public enum RequestMatcherResult {
    case Yes(matchedURL: NSURL)
    case No
}

extension RequestMatcherResult: BooleanType {
    public var boolValue: Bool {
        get {
            switch self {
            case .No:
                return false
            default:
                return true
            }
        }
    }
}

public func | (lhs: RequestMatcherResult, rhs: RequestMatcherResult) -> RequestMatcherResult {
    return lhs ?? rhs
}

public struct DirectRequestMatcher: RequestMatcher {
    public init() {
    }
    
    public func match(#request: Request, resolver: URLResolver) -> RequestMatcherResult {
        if resolver.isFileExist(request.URL) {
            return RequestMatcherResult.Yes(matchedURL: request.URL)
        }
        return RequestMatcherResult.No
    }
}

public struct IndexRequestMatcher: RequestMatcher {
    public init() {
    }
    
    public func match(#request: Request, resolver: URLResolver) -> RequestMatcherResult {
        if request.URL.pathExtension == nil || request.URL.pathExtension! == "" {
            let indexURL = request.URL.URLByAppendingPathComponent("index.html")
            if resolver.isFileExist(indexURL) {
                return RequestMatcherResult.Yes(matchedURL: indexURL)
            }
        }
        return RequestMatcherResult.No
    }
}

public struct RouteRequestMatcher: RequestMatcher {
    public let route: Route
    
    public init(route: Route) {
        self.route = route
    }

    public func match(#request: Request, resolver: URLResolver) -> RequestMatcherResult {
        if request.method == route.method {
            if let regex: NSRegularExpression = NSRegularExpression(pattern: self.route.requestPath, options: .AnchorsMatchLines | .CaseInsensitive, error: nil) {
                if let path = request.URL.path {
                    if regex.numberOfMatchesInString(path, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, (path as NSString).length)) > 0 {

                        return DirectRequestMatcher().match(request: request, resolver: resolver) |
                               IndexRequestMatcher().match(request: request, resolver: resolver)
                    }
                }
            }
        }
        return RequestMatcherResult.No
    }
}

public struct RouteCollectionRequestMatcher: RequestMatcher {
    public let routes: [Route]
    
    public init(routes: [Route]) {
        self.routes = routes
    }
    
    public func match(#request: Request, resolver: URLResolver) -> RequestMatcherResult {
        for route in self.routes {
            let matcher = RouteRequestMatcher(route: route)
            let result = matcher.match(request: request, resolver: resolver)
            if result {
                return result
            }
        }
        return RequestMatcherResult.No
    }
}

// MARK: - RequestMapper

public struct RequestMapper {
    let matchers: [RequestMatcher]
    let resolver: URLResolver
    
    public init(matchers: [RequestMatcher], resolver: URLResolver) {
        self.matchers = matchers
        self.resolver = resolver
    }

    public func map(#request: Request) -> Response {
        for matcher in self.matchers {
            switch matcher.match(request: request, resolver: self.resolver) {
            case .Yes(let URL):
                return Response.Success(URL: URL)
            case .No:
                break
            }
        }
        return Response.Failure(error: .NotFound)
    }
}

// MARK: - URLResolver

public protocol URLResolver {
    init()
    func isFileExist(fileURL: NSURL) -> Bool;
}

public struct LocalURLResolver: URLResolver {
    public init() {
    }
    
    public func isFileExist(fileURL: NSURL) -> Bool {
        return fileURL.checkPromisedItemIsReachableAndReturnError(nil)
    }
}

// MARK: - Server

public class Server {
    public init() {
        
    }
    
    public func start(#rootFileURL: NSURL) {
        
    }
    
    public func stop() {
        
    }
}