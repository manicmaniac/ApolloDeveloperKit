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
    typealias Element = NetworkInterface
    typealias Iterator = AnyIterator<NetworkInterface>

    /**
     * Returns newly initialized instance with the current device's state of network interfaces.
     */
    class var current: NetworkInterfaceList? {
        var addressPointer: UnsafeMutablePointer<ifaddrs>!
        guard withUnsafeMutablePointer(to: &addressPointer, getifaddrs) >= 0 else {
            return nil
        }
        return NetworkInterfaceList(addressPointer: addressPointer)
    }

    private let addressPointer: UnsafeMutablePointer<ifaddrs>

    /**
     * Initializes `NetworkInterfaceList` with a pointer to head of interface addresses.
     *
     * This constructor is only visible for testing purpose.
     *
     * The initialized instance takes the ownership of a given pointer.
     * You must not free it by yourself.
     *
     * - Parameter addressPointer: head of linked list of interface addresses.
     */
    init(addressPointer: UnsafeMutablePointer<ifaddrs>) {
        self.addressPointer = addressPointer
    }

    func makeIterator() -> Iterator {
        let addressPointers = sequence(first: addressPointer, next: { $0.pointee.ifa_next })
        let networkInterfaces = addressPointers.lazy.map { NetworkInterface(addr: $0.pointee) }
        return AnyIterator(networkInterfaces.makeIterator())
    }

    deinit {
        freeifaddrs(addressPointer)
    }
}
