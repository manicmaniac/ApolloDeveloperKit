//
//  FileDescriptorDuplicator.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 11/5/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

/**
 * `FileDescriptorDuplicator` abstracts the interface of `dup` and `dup2`.
 *
 * This protocol is mainly for testing purposes.
 */
protocol FileDescriptorDuplicator {
    func dup(_ fildes: Int32) -> Int32
    @discardableResult func dup2(_ fildes: Int32, _ fildes2: Int32) -> Int32
}
