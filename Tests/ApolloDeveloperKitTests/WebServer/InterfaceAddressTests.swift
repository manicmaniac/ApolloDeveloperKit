//
//  InterfaceAddressTests.swift
//  ApolloDeveloperKitTests
//
//  Created by Ryosuke Ito on 8/21/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import XCTest
@testable import ApolloDeveloperKit

class InterfaceAddressTests: XCTestCase {
    func testIsUp_whenTheInterfaceIsUp() {
        var name = "en0".cString(using: .ascii)!
        var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_ANY, port: 80)
        let address = ifaddrs(name: &name, flags: IFF_UP, addr: &socketAddress)
        let interfaceAddress = InterfaceAddress(rawValue: address)
        XCTAssertTrue(interfaceAddress.isUp)
    }

    func testIsUp_whenTheInterfaceIsDown() {
        var name = "en0".cString(using: .ascii)!
        var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_ANY, port: 80)
        let address = ifaddrs(name: &name, flags: 0, addr: &socketAddress)
        let interfaceAddress = InterfaceAddress(rawValue: address)
        XCTAssertFalse(interfaceAddress.isUp)
    }

    func testName() {
        var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_ANY, port: 80)
        var name = "en0".cString(using: .ascii)!
        let address = ifaddrs(name: &name, flags: 0, addr: &socketAddress)
        let interfaceAddress = InterfaceAddress(rawValue: address)
        XCTAssertEqual("en0", interfaceAddress.name)
    }

    func testSocketFamily() {
        var name = "en0".cString(using: .ascii)!
        var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_ANY, port: 80)
        let address = ifaddrs(name: &name, flags: 0, addr: &socketAddress)
        let interfaceAddress = InterfaceAddress(rawValue: address)
        XCTAssertEqual(socketAddress.sa_family, interfaceAddress.socketFamily)
    }

    func testIpv4Address_whenTheInterfaceAddressIsINADDR_ANY() {
        var name = "en0".cString(using: .ascii)!
        var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_ANY, port: 80)
        let address = ifaddrs(name: &name, flags: 0, addr: &socketAddress)
        let interfaceAddress = InterfaceAddress(rawValue: address)
        XCTAssertEqual("0.0.0.0", interfaceAddress.hostName)
    }

    func testIpv4Address_whenTheInterfaceAddressIsINADDR_LOOPBACK() {
        var name = "en0".cString(using: .ascii)!
        var socketAddress = sockaddr.in(family: AF_INET, address: INADDR_LOOPBACK, port: 80)
        let address = ifaddrs(name: &name, flags: 0, addr: &socketAddress)
        let interfaceAddress = InterfaceAddress(rawValue: address)
        XCTAssertEqual("127.0.0.1", interfaceAddress.hostName)
    }
}
