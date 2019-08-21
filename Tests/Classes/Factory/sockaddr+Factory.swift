//
//  sockaddr+Factory.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/21/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Darwin

extension sockaddr {
    static func `in`(family: Int32, address: UInt32, port: Int) -> sockaddr {
        return unsafeBitCast(sockaddr_in(sin_len: __uint8_t(MemoryLayout<sockaddr_in>.size),
                                         sin_family: sa_family_t(AF_INET),
                                         sin_port: in_port_t(port).bigEndian,
                                         sin_addr: in_addr(s_addr: address.bigEndian),
                                         sin_zero: (0, 0, 0, 0, 0, 0, 0, 0)),
                             to: sockaddr.self)
    }
}
