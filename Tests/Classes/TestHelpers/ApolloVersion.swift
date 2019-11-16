//
//  ApolloVersion.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 11/17/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Apollo

struct ApolloVersion {
    #if os(iOS)
    private static let apolloBundleIdentifier = "com.apollographql.Apollo.iphoneos"
    #else
    private static let apolloBundleIdentifier = "com.apollographql.Apollo.macosx"
    #endif

    static var current: ApolloVersion {
        let bundleVersion = Bundle(identifier: apolloBundleIdentifier)!.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
        return ApolloVersion(stringLiteral: bundleVersion)
    }

    let major: Int
    let minor: Int
    let patch: Int
}

// MARK: Comparable

extension ApolloVersion: Comparable {
    static func < (lhs: ApolloVersion, rhs: ApolloVersion) -> Bool {
        return [lhs.major, lhs.minor, lhs.patch] < [rhs.major, rhs.minor, rhs.patch]
    }
}

// MARK: CustomStringConvertible

extension ApolloVersion: CustomStringConvertible {
    var description: String {
        return "\(major).\(minor).\(patch)"
    }
}

// MARK: ExpressibleByFloatLiteral

extension ApolloVersion: ExpressibleByFloatLiteral {
    typealias FloatLiteralType = Double

    init(floatLiteral value: Double) {
        var integral = 0.0
        let fractional = modf(value, &integral)
        self.major = Int(integral)
        self.minor = Int(fractional * 10)
        self.patch = 0
    }
}

// MARK: ExpressibleByStringLiteral

extension ApolloVersion: ExpressibleByStringLiteral {
    typealias StringLiteralType = String

    init(stringLiteral value: String) {
        let components = value.split(separator: ".")
        let (major, minor, patch) = (Int(components[0])!, Int(components[1])!, Int(components[2])!)
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}
