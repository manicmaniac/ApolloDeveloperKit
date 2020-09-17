//
//  InterfaceAddress.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 9/15/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Darwin

struct InterfaceAddress: RawRepresentable {
    var rawValue: ifaddrs

    init(rawValue: ifaddrs) {
        self.rawValue = rawValue
    }

    var name: String {
        return String(cString: rawValue.ifa_name)
    }

    var isUp: Bool {
        return (rawValue.ifa_flags & UInt32(IFF_UP)) != 0
    }

    var socketFamily: sa_family_t {
        return rawValue.ifa_addr.pointee.sa_family
    }

    var hostName: String? {
        var host = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        errno = 0
        guard getnameinfo(rawValue.ifa_addr,
                          socklen_t(rawValue.ifa_addr.pointee.sa_len),
                          &host,
                          socklen_t(host.count),
                          nil,
                          0,
                          NI_NUMERICHOST | NI_NOFQDN) == 0
        else { return nil }
        return String(cString: host)
    }
}
