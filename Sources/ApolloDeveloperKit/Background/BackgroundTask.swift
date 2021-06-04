//
//  BackgroundTask.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 11/12/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

#if os(iOS)
import UIKit

protocol BackgroundTaskExecutor {
    func beginBackgroundTask(withName name: String?, expirationHandler handler: (() -> Void)?) -> UIBackgroundTaskIdentifier
    func endBackgroundTask(_ identifier: UIBackgroundTaskIdentifier)
}

extension UIApplication: BackgroundTaskExecutor {
    // Already conformed.
}

final class BackgroundTask {
    private(set) var currentIdentifier: UIBackgroundTaskIdentifier
    private let executor: BackgroundTaskExecutor

    init(executor: BackgroundTaskExecutor = UIApplication.shared) {
        self.executor = executor
        self.currentIdentifier = .invalid
    }

    func beginBackgroundTaskIfPossible() {
        precondition(Thread.isMainThread)
        guard currentIdentifier == .invalid else { return }
        currentIdentifier = executor.beginBackgroundTask(withName: "com.github.manicmaniac.ApolloDeveloperKit.BackgroundTask") {
            self.executor.endBackgroundTask(self.currentIdentifier)
            self.currentIdentifier = .invalid
        }
    }
}
#else
final class BackgroundTask {
    func beginBackgroundTaskIfPossible() {
    }
}
#endif
