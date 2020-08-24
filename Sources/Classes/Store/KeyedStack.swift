//
//  KeyedStack.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/25/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

struct KeyedStack<Key, Value> where Key: Equatable {
    private var elements = [(Key, Value)]()

    mutating func push(_ value: Value, for key: Key) {
        elements.append((key, value))
    }

    subscript(key: Key) -> Value? {
        get {
            guard let index = elements.lastIndex(where: { k, _ in k == key }) else { return nil }
            return elements[index].1
        }
        set {
            guard let index = elements.lastIndex(where: { k, _ in k == key }) else { return }
            if let newValue = newValue {
                elements[index] = (key, newValue)
            } else {
                elements.remove(at: index)
            }
        }
    }
}

extension KeyedStack: Sequence {
    func makeIterator() -> AnyIterator<(Key, Value)> {
        return AnyIterator(elements.makeIterator())
    }
}
