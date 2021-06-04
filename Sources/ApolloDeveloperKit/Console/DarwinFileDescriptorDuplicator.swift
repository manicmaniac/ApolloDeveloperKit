//
//  DarwinFileDescriptorDuplicator.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 11/5/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

import Darwin

struct DarwinFileDescriptorDuplicator: FileDescriptorDuplicator {
    func dup(_ fildes: Int32) -> Int32 {
        return Darwin.dup(fildes)
    }

    func dup2(_ fildes: Int32, _ fildes2: Int32) -> Int32 {
        return Darwin.dup2(fildes, fildes2)
    }
}
