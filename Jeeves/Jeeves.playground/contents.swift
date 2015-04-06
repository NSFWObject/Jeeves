//: Playground - noun: a place where people can play

import Cocoa
import Foundation

let string = "cats"
let regex = NSRegularExpression(pattern: "^cat$", options: .CaseInsensitive, error: nil)!
let matches = regex.matchesInString(string, options: NSMatchingOptions.Anchored, range: NSMakeRange(0, (string as NSString).length)) as! [NSTextCheckingResult]
matches.first!.range
