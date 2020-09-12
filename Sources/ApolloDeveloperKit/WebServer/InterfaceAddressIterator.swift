//
//  InterfaceAddressIterator.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 9/15/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

final class InterfaceAddressIterator: IteratorProtocol {
    private let initialPointer: UnsafeMutablePointer<ifaddrs>
    private let deallocator: (UnsafeMutablePointer<ifaddrs>) -> Void
    private var currentPointer: UnsafeMutablePointer<ifaddrs>?

    init(initialPointer: UnsafeMutablePointer<ifaddrs>, deallocator: @escaping (UnsafeMutablePointer<ifaddrs>) -> Void) {
        self.initialPointer = initialPointer
        self.deallocator = deallocator
        self.currentPointer = initialPointer
    }

    convenience init() throws {
        var initialPointer: UnsafeMutablePointer<ifaddrs>!
        errno = 0
        guard withUnsafeMutablePointer(to: &initialPointer, getifaddrs) != -1 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
        self.init(initialPointer: initialPointer, deallocator: freeifaddrs)
    }

    deinit {
        deallocator(initialPointer)
    }

    func next() -> InterfaceAddress? {
        guard let pointer = currentPointer else { return nil }
        defer { currentPointer = currentPointer?.pointee.ifa_next }
        return InterfaceAddress(rawValue: pointer.pointee)
    }
}
