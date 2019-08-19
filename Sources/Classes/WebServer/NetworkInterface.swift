//
//  NetworkInterface.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/18/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Darwin

/**
 * `NetworkInterface` is a Swift bridge for Unix `ifaddrs`.
 */
class NetworkInterface {
    let name: String
    private let addressPointer: UnsafeMutablePointer<sockaddr>
    private let flags: UInt32

    var isUp: Bool {
        return (flags & UInt32(IFF_UP)) == 1
    }

    var socketFamily: sa_family_t {
        return addressPointer.pointee.sa_family
    }

    var ipv4Address: String? {
        let buffer = UnsafeMutablePointer<Int8>.allocate(capacity: Int(NI_MAXHOST))
        defer { buffer.deallocate() }
        guard getnameinfo(addressPointer,
                          socklen_t(addressPointer.pointee.sa_len),
                          buffer,
                          socklen_t(NI_MAXHOST),
                          nil,
                          0,
                          NI_NUMERICHOST | NI_NOFQDN) == 0 else {
            return nil
        }
        return String(cString: buffer, encoding: .ascii)
    }

    init(addr: ifaddrs) {
        self.name = String(cString: addr.ifa_name)
        self.flags = addr.ifa_flags
        self.addressPointer = addr.ifa_addr
    }
}