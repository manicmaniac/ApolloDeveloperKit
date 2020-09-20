//
//  Socket.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/26/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

protocol SocketDelegate: class {
    func socket(_ socket: Socket, didAccept nativeHandle: CFSocketNativeHandle, address: Data)
    func socket(_ socket: Socket, didReceive data: Data, address: Data)
    func socketDidBecomeWritable(_ socket: Socket)
}

/**
 * A thin wrapper for Swift-incompatible type `CFSocket`.
 */
final class Socket {
    weak var delegate: SocketDelegate?
    private var cfSocket: CFSocket!

    init(protocolFamily: Int32, socketType: Int32, `protocol`: Int32, callbackTypes: CFSocketCallBackType) throws {
        let pointerToSelf = Unmanaged.passUnretained(self).toOpaque()
        var context = CFSocketContext(version: 0, info: pointerToSelf, retain: nil, release: nil, copyDescription: nil)
        errno = 0
        guard let cfSocket = CFSocketCreate(kCFAllocatorDefault, protocolFamily, socketType, `protocol`, callbackTypes.rawValue, socketCallBack(cfSocket:callbackType:address:data:info:), &context) else {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
        self.cfSocket = cfSocket
    }

    init(nativeHandle: CFSocketNativeHandle, callbackTypes: CFSocketCallBackType) throws {
        let pointerToSelf = Unmanaged.passUnretained(self).toOpaque()
        var context = CFSocketContext(version: 0, info: pointerToSelf, retain: nil, release: nil, copyDescription: nil)
        errno = 0
        guard let cfSocket = CFSocketCreateWithNative(kCFAllocatorDefault, nativeHandle, callbackTypes.rawValue, socketCallBack(cfSocket:callbackType:address:data:info:), &context) else {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
        self.cfSocket = cfSocket
    }

    var address: Data {
        return CFSocketCopyAddress(cfSocket) as Data
    }

    func enableCallBacks(_ callbacks: CFSocketCallBackType) {
        CFSocketEnableCallBacks(cfSocket, callbacks.rawValue)
    }

    func disableCallBacks(_ callbacks: CFSocketCallBackType) {
        CFSocketDisableCallBacks(cfSocket, callbacks.rawValue)
    }

    func setAddress(_ address: Data) throws {
        // Do not use `CFSocketSetAddress()` because it doesn't report errors properly.
        // https://opensource.apple.com/source/CF/CF-1153.18/CFSocket.c.auto.html
        let fileDescriptor = CFSocketGetNative(cfSocket)
        errno = 0
        let result = address.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> Int32 in
            let pointer = bytes.bindMemory(to: sockaddr.self).baseAddress
            return bind(fileDescriptor, pointer, socklen_t(bytes.count))
        }
        let backlog = Int32(256) // The same value used in CFSocketSetAddress()
        guard result != -1 && listen(fileDescriptor, backlog) != -1 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
    }

    func setValue<T>(_ value: inout T, for level: Int32, option: Int32) throws {
        errno = 0
        guard setsockopt(CFSocketGetNative(cfSocket), level, option, &value, socklen_t(MemoryLayout.size(ofValue: value))) != -1 else {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
    }

    func setValue<T>(_ value: T, for level: Int32, option: Int32) throws {
        var value = value
        try setValue(&value, for: level, option: option)
    }

    func invalidate() {
        CFSocketInvalidate(cfSocket)
    }

    func send(address: Data? = nil, data: Data, timeout: TimeInterval) throws -> Bool {
        errno = 0
        guard CFSocketSendData(cfSocket, address as CFData?, data as CFData, timeout) == .success else {
            if let code = POSIXErrorCode(rawValue: errno) {
                throw POSIXError(code)
            }
            return false
        }
        return true
    }

    func schedule(in runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        let source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, cfSocket, 0)
        CFRunLoopAddSource(runLoop.getCFRunLoop(), source, CFRunLoopMode(mode.rawValue as CFString))
    }
}

private func socketCallBack(cfSocket: CFSocket!, callbackType: CFSocketCallBackType, address: CFData?, data: UnsafeRawPointer?, info: UnsafeMutableRawPointer!) {
    let socket = Unmanaged<Socket>.fromOpaque(info).takeUnretainedValue()
    switch callbackType {
    case .acceptCallBack:
        let nativeHandle = data!.load(as: CFSocketNativeHandle.self)
        socket.delegate?.socket(socket, didAccept: nativeHandle, address: address! as Data)
    case .dataCallBack:
        let data = Unmanaged<CFData>.fromOpaque(data!).takeUnretainedValue() as Data
        socket.delegate?.socket(socket, didReceive: data, address: address! as Data)
    case .writeCallBack:
        socket.delegate?.socketDidBecomeWritable(socket)
    default:
        assertionFailure("Received unhandled callback type (\(callbackType.rawValue)).")
    }
}

// MARK: Equatable

extension Socket: Equatable {
    static func == (lhs: Socket, rhs: Socket) -> Bool {
        return CFEqual(lhs.cfSocket, rhs.cfSocket)
    }
}

// MARK: Hashable

extension Socket: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(cfSocket))
    }
}
