//
//  HTTPOutputStreamSet.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 9/15/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

final class HTTPOutputStreamSet: Sequence {
    private let hashTable = NSHashTable<AnyObject>.weakObjects()

    func insert(_ stream: HTTPOutputStream) {
        hashTable.add(stream)
    }

    func broadcast(data: Data) {
        for stream in self {
            stream.write(data: data)
        }
    }

    func makeIterator() -> AnyIterator<HTTPOutputStream> {
        return AnyIterator(hashTable.allObjects.map { $0 as! HTTPOutputStream }.makeIterator())
    }
}
