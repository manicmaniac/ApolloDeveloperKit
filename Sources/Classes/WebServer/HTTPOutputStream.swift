//
//  HTTPOutputStream.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 9/15/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

protocol HTTPOutputStream: class {
    func write(data: Data)
    func writeAndClose(contentsOf url: URL) throws
    func close()
}
