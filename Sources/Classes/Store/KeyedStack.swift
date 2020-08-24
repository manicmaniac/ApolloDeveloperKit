//
//  KeyedStack.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 8/25/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

/**
 * `KeyedStack` is kind of a stack of `Value`s keyed by `Key`.
 *
 * - Warning: Iterating over `KeyedStack` yields key-value pairs from the *bottom* of stack.
 */
struct KeyedStack<Key, Value> where Key: Equatable {
    private var elements = [(Key, Value)]()

    mutating func push(_ value: Value, for key: Key) {
        elements.append((key, value))
    }

    /**
     * Access the value associated with the given key for reading and writing.
     *
     * Since `KeyedStack` is a stack and doesn't guarantee uniqueness of keys,
     * the return value is the *first* found `Value` from the top of  stack.
     */
    subscript(key: Key) -> Value? {
        get {
            return index(for: key).flatMap { elements[$0].1 }
        }
        set {
            guard let index = self.index(for: key) else { return }
            if let newValue = newValue {
                elements[index] = (key, newValue)
            } else {
                elements.remove(at: index)
            }
        }
    }

    private func index(for key: Key) -> Int? {
        return elements.lastIndex { $0.0 == key }
    }
}

extension KeyedStack: Sequence {
    func makeIterator() -> AnyIterator<(Key, Value)> {
        return AnyIterator(elements.makeIterator())
    }
}
