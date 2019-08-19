//
//  NetworkInterfaceList.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/18/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Darwin

/**
 * `NetworkInterfaceList` is a linked list of `NetworkInterface`s.
 */
class NetworkInterfaceList: Sequence {
    typealias Iterator = NetworkInterfaceList

    class var current: NetworkInterfaceList {
        var addressPointer: UnsafeMutablePointer<ifaddrs>?
        guard withUnsafeMutablePointer(to: &addressPointer, getifaddrs) >= 0 else {
            return NetworkInterfaceList(addressPointer: nil)
        }
        return NetworkInterfaceList(addressPointer: addressPointer)
    }

    private var addressPointer: UnsafeMutablePointer<ifaddrs>?

    private init(addressPointer: UnsafeMutablePointer<ifaddrs>?) {
        self.addressPointer = addressPointer
    }

    deinit {
        freeifaddrs(addressPointer)
    }
}

extension NetworkInterfaceList: IteratorProtocol {
    typealias Element = NetworkInterface

    func next() -> NetworkInterface? {
        guard let addressPointer = addressPointer else {
            return nil
        }
        addressPointer.moveAssign(from: addressPointer.pointee.ifa_next, count: 1)
        return NetworkInterface(addr: addressPointer.pointee)
    }
}
