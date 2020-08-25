//
//  MockFileDescriptorDuplicator.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/25/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

@testable import ApolloDeveloperKit

class MockFileDescriptorDuplicator: FileDescriptorDuplicator {
    private(set) var dupInvocationHistory = [Int32]()
    private(set) var dup2InvocationHistory = [(fildes: Int32, fildes2: Int32)]()

    func dup(_ fildes: Int32) -> Int32 {
        dupInvocationHistory.append(fildes)
        return fildes
    }

    func dup2(_ fildes: Int32, _ fildes2: Int32) -> Int32 {
        dup2InvocationHistory.append((fildes, fildes2))
        return fildes2
    }

    func clearInvocationHistory() {
        dupInvocationHistory.removeAll()
        dup2InvocationHistory.removeAll()
    }
}
