//
//  NetworkInterfaceTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/21/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class NetworkInterfaceTests: XCTestCase {
    func testIsUp() {
        var name = "en0".cString(using: .ascii)!
        var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_ANY, port: 80)
        XCTContext.runActivity(named: "when the interface is up") { _ in
            let address = ifaddrs(name: &name, flags: IFF_UP, ifa_addr: &socketAddress)
            let networkInterface = NetworkInterface(addr: address)
            XCTAssertTrue(networkInterface.isUp)
        }
        XCTContext.runActivity(named: "when the interface is down") { _ in
            let address = ifaddrs(name: &name, flags: 0, ifa_addr: &socketAddress)
            let networkInterface = NetworkInterface(addr: address)
            XCTAssertFalse(networkInterface.isUp)
        }
    }

    func testName() {
        var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_ANY, port: 80)
        var name = "en0".cString(using: .ascii)!
        let address = ifaddrs(name: &name, flags: 0, ifa_addr: &socketAddress)
        let networkInterface = NetworkInterface(addr: address)
        XCTAssertEqual("en0", networkInterface.name)
    }

    func testSocketFamily() {
        var name = "en0".cString(using: .ascii)!
        var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_ANY, port: 80)
        let address = ifaddrs(name: &name, flags: 0, ifa_addr: &socketAddress)
        let networkInterface = NetworkInterface(addr: address)
        XCTAssertEqual(socketAddress.sa_family, networkInterface.socketFamily)
    }

    func testIpv4Address() {
        var name = "en0".cString(using: .ascii)!
        XCTContext.runActivity(named: "when the interface address is INADDR_ANY") { _ in
            var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_ANY, port: 80)
            let address = ifaddrs(name: &name, flags: 0, ifa_addr: &socketAddress)
            let networkInterface = NetworkInterface(addr: address)
            XCTAssertEqual("0.0.0.0", networkInterface.ipv4Address)
        }
        XCTContext.runActivity(named: "when the interface address is INADDR_LOOPBACK") { _ in
            var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_LOOPBACK, port: 80)
            let address = ifaddrs(name: &name, flags: 0, ifa_addr: &socketAddress)
            let networkInterface = NetworkInterface(addr: address)
            XCTAssertEqual("127.0.0.1", networkInterface.ipv4Address)
        }
    }
}
