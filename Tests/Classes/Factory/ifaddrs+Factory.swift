//
//  ifaddrs+Factory.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/21/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Darwin

extension ifaddrs {
    init(name: inout [CChar], flags: Int32, ifa_addr: inout sockaddr) {
        self.init(ifa_next: nil,
                  ifa_name: &name,
                  ifa_flags: UInt32(flags),
                  ifa_addr: &ifa_addr,
                  ifa_netmask: nil,
                  ifa_dstaddr: nil,
                  ifa_data: nil)
    }
}

