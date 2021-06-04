//
//  ErrorLike+Error.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/22/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

extension ErrorLike {
    init(error: Error) {
        self.init(columnNumber: nil,
                  fileName: nil,
                  lineNumber: nil,
                  message: error.localizedDescription,
                  name: String(describing: type(of: error)))
    }
}
