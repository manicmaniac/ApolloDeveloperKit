//
//  Socket.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 2/26/20.
//  Copyright © 2020 Ryosuke Ito. All rights reserved.
//

import Foundation

/**
 * A thin wrapper for Swift-incompatible type `CFSocket`.
 */
final class Socket {
    weak var delegate: SocketDelegate?
    private var cfSocket: CFSocket!

    init(protocolFamily: Int32, socketType: Int32, `protocol`: Int32, callbackTypes: CFSocketCallBackType) throws {
        let pointerToSelf = Unmanaged.passUnretained(self).toOpaque()
        var context = CFSocketContext(version: 0, info: pointerToSelf, retain: nil, release: nil, copyDescription: nil)
        guard let cfSocket = CFSocketCreate(kCFAllocatorDefault, protocolFamily, socketType, `protocol`, callbackTypes.rawValue, socketCallBack(cfSocket:callbackType:address:data:info:), &context) else {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
        self.cfSocket = cfSocket
    }

    init(nativeHandle: CFSocketNativeHandle, callbackTypes: CFSocketCallBackType) throws {
        let pointerToSelf = Unmanaged.passUnretained(self).toOpaque()
        var context = CFSocketContext(version: 0, info: pointerToSelf, retain: nil, release: nil, copyDescription: nil)
        guard let cfSocket = CFSocketCreateWithNative(kCFAllocatorDefault, nativeHandle, callbackTypes.rawValue, socketCallBack(cfSocket:callbackType:address:data:info:), &context) else {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
        self.cfSocket = cfSocket
    }

    var nativeHandle: CFSocketNativeHandle {
        return CFSocketGetNative(cfSocket)
    }

    var isValid: Bool {
        return CFSocketIsValid(cfSocket)
    }

    var address: Data {
        return CFSocketCopyAddress(cfSocket) as Data
    }

    var peerAddress: Data {
        return CFSocketCopyPeerAddress(cfSocket) as Data
    }

    var shouldCloseOnInvalidate: Bool {
        get { return CFSocketGetSocketFlags(cfSocket) & kCFSocketCloseOnInvalidate > 0 }
        set { CFSocketSetSocketFlags(cfSocket, kCFSocketCloseOnInvalidate) }
    }

    func enableCallBacks(_ callbacks: CFSocketCallBackType) {
        CFSocketEnableCallBacks(cfSocket, callbacks.rawValue)
    }

    func disableCallBacks(_ callbacks: CFSocketCallBackType) {
        CFSocketDisableCallBacks(cfSocket, callbacks.rawValue)
    }

    func setAddress(_ address: Data) throws {
        guard CFSocketSetAddress(cfSocket, address as CFData) == .success else {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
    }

    func setValue<T>(_ value: inout T, for level: Int32, option: Int32) throws {
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

    func send(address: Data? = nil, data: Data, timeout: TimeInterval) throws {
        guard CFSocketSendData(cfSocket, address as CFData?, data as CFData, timeout) == .success else {
            throw POSIXError(POSIXErrorCode(rawValue: errno)!)
        }
    }

    func schedule(in runLoop: RunLoop, forMode mode: RunLoop.Mode) {
        let source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, cfSocket, 0)
        CFRunLoopAddSource(runLoop.getCFRunLoop(), source, CFRunLoopMode(mode.rawValue as CFString))
    }
}

extension Socket: Equatable {
    static func == (lhs: Socket, rhs: Socket) -> Bool {
        return CFEqual(lhs.cfSocket, rhs.cfSocket)
    }
}

extension Socket: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(CFHash(cfSocket))
    }
}

private func socketCallBack(cfSocket: CFSocket!, callbackType: CFSocketCallBackType, address: CFData?, data: UnsafeRawPointer?, info: UnsafeMutableRawPointer!) {
    let socket = Unmanaged<Socket>.fromOpaque(info).takeUnretainedValue()
    switch callbackType {
    case .readCallBack:
        socket.delegate?.socketDidBecomeReadable(socket)
    case .acceptCallBack:
        let nativeHandle = data!.assumingMemoryBound(to: CFSocketNativeHandle.self).pointee
        socket.delegate?.socket(socket, didAccept: nativeHandle, address: address! as Data)
    case .dataCallBack:
        let data = Unmanaged<CFData>.fromOpaque(data!).takeUnretainedValue() as Data
        socket.delegate?.socket(socket, didReceive: data, address: address! as Data)
    case .connectCallBack:
        let errorCode = data!.assumingMemoryBound(to: Int32.self).pointee
        let error = POSIXErrorCode(rawValue: errorCode).flatMap { POSIXError($0) }
        socket.delegate?.socket(socket, didConnect: error)
    case .writeCallBack:
        socket.delegate?.socketDidBecomeWritable(socket)
    default:
        assertionFailure("Received unknown callback type: \(callbackType.rawValue)")
    }
}

protocol SocketDelegate: class {
    func socketDidBecomeReadable(_ socket: Socket)
    func socket(_ socket: Socket, didAccept nativeHandle: CFSocketNativeHandle, address: Data)
    func socket(_ socket: Socket, didReceive data: Data, address: Data)
    func socket(_ socket: Socket, didConnect error: Error?)
    func socketDidBecomeWritable(_ socket: Socket)
}
