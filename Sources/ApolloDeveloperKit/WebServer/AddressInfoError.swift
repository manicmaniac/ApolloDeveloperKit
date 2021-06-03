//
//  AddressInfoError.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 9/20/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Darwin

struct AddressInfoError: Error {
    typealias Code = AddressInfoErrorCode

    let code: AddressInfoErrorCode

    init(_ code: AddressInfoErrorCode) {
        self.code = code
    }

    var localizedDescription: String {
        return String(cString: gai_strerror(code.rawValue))
    }
}

struct AddressInfoErrorCode: RawRepresentable {
    var rawValue: Int32

    init?(rawValue: Int32) {
        guard (1..<EAI_MAX).contains(rawValue) else { return nil }
        self.rawValue = rawValue
    }
}
