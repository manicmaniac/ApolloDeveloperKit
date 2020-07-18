//
//  NetworkInterfaceListTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/20/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class NetworkInterfaceListTests: XCTestCase {
    private var networkInterfaceList: NetworkInterfaceList!

    // We must manage memory by ourselves because they are out of ARC.
    private var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_ANY, port: 80)
    private var en0Name = "en0".cString(using: .ascii)!
    private var en1Name = "en1".cString(using: .ascii)!
    private var en2Name = "en2".cString(using: .ascii)!
    private var en0: ifaddrs!
    private var en1: ifaddrs!
    private var en2: ifaddrs!

    override func setUp() {
        let flags = IFF_UP | IFF_BROADCAST | IFF_RUNNING | IFF_PROMISC | IFF_SIMPLEX | IFF_MULTICAST
        en0 = ifaddrs(name: &en0Name, flags: flags, addr: &socketAddress)
        en1 = ifaddrs(name: &en1Name, flags: flags, addr: &socketAddress)
        en2 = ifaddrs(name: &en2Name, flags: flags, addr: &socketAddress)
        withUnsafeMutablePointer(to: &en1) { en0.ifa_next = $0 }
        withUnsafeMutablePointer(to: &en2) { en1.ifa_next = $0 }
        self.networkInterfaceList = withUnsafeMutablePointer(to: &en0, NetworkInterfaceList.init(addressPointer:))
    }

    func testMakeIterator() {
        // Make sure each iterators are independent.
        let iterator1 = networkInterfaceList.makeIterator()
        let iterator2 = networkInterfaceList.makeIterator()
        XCTAssertEqual("en0", iterator1.next()?.name)
        XCTAssertEqual("en0", iterator2.next()?.name)
        XCTAssertEqual("en1", iterator1.next()?.name)
        XCTAssertEqual("en1", iterator2.next()?.name)
        XCTAssertEqual("en2", iterator1.next()?.name)
        XCTAssertEqual("en2", iterator2.next()?.name)
        XCTAssertNil(iterator1.next())
        XCTAssertNil(iterator2.next())
    }
}
