//
//  JSONCocoaTypeConversions.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 11/20/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo
import Foundation

/**
 * `Apollo` has its own utility extensions to convert Swift standard types to JSON object and uses it widely in the project.
 * `ApolloDeveloperKit` borrows this feature in order to convert an object to JSON-compliant object, like converting cache contents to JSON.
 *  However, I found `Apollo` sometimes utilizes Cocoa types like NSString which is not covered by the above utility extensions,
 *  and when I use those utility extensions on them, `fatalError()` occurs because it doesn't conform to `JSONEncodable`.
 *  So to avoid this problem, `ApolloDeveloperKit` have to prepare some more extensions for Cocoa types.
 */
protocol ExtendedJSONEncodable: JSONEncodable {}

extension NSString: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        return (self as String).jsonValue
    }
}

extension NSNumber: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        switch CFGetTypeID(self) {
        case CFBooleanGetTypeID():
            return boolValue.jsonValue
        case CFNumberGetTypeID():
            return CFNumberIsFloatType(self) ? doubleValue.jsonValue : intValue.jsonValue
        default:
            fatalError("The underlying type of value must be CFBoolean or CFNumber")
        }
    }
}

extension NSDictionary: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        return (self as [NSObject: AnyObject]).jsonValue
    }
}

extension NSArray: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        return (self as [AnyObject]).jsonValue
    }
}

extension NSNull: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        return self
    }
}

extension CFString: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        return (self as NSString).jsonValue
    }
}

extension CFNumber: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        return (self as NSNumber).jsonValue
    }
}

extension CFBoolean: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        return CFBooleanGetValue(self).jsonValue
    }
}

extension CFDictionary: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        return (self as NSDictionary).jsonValue
    }
}

extension CFArray: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        return (self as NSArray).jsonValue
    }
}

extension CFNull: ExtendedJSONEncodable {
    public var jsonValue: JSONValue {
        return self as NSNull
    }
}
