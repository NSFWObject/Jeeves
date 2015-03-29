//
//  Resolver.swift
//  Jeeves
//
//  Created by Sash Zats on 3/28/15.
//  Copyright (c) 2015 Sash Zats. All rights reserved.
//

import Foundation

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
}

// MARK: - Request Matchers

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
    public func match(#request: Request, resolver: URLResolver) -> RequestMatcherResult {
        if resolver.isFileExist(request.URL) {
            return RequestMatcherResult.Yes(matchedURL: request.URL)
        }
        return RequestMatcherResult.No
    }
}

public struct IndexRequestMatcher: RequestMatcher {
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
    public let routeCollection: [Route]
    
    public func match(#request: Request, resolver: URLResolver) -> RequestMatcherResult {
        for route in self.routeCollection {
            let matcher = RouteRequestMatcher(route: route)
            let result = matcher.match(request: request, resolver: resolver)
            if result {
                return result
            }
        }
        return RequestMatcherResult.No
    }
}

// MARK: - Request Mapper

public struct RequestMapper {
    let matchers: [RequestMatcher]
    let resolver: URLResolver

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

// MARK: - Resolvers

public protocol URLResolver {
    func isFileExist(fileURL: NSURL) -> Bool;
}

public class LocalURLResolver: URLResolver {
    public func isFileExist(fileURL: NSURL) -> Bool {
        return fileURL.checkPromisedItemIsReachableAndReturnError(nil)
    }
}