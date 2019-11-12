//
//  BackgroundTask.swift
//  ApolloDeveloperKit
//
//  Created by Ryosuke Ito on 11/12/19.
//  Copyright © 2019 Ryosuke Ito. All rights reserved.
//

#if os(iOS)
import UIKit

class BackgroundTask {
    #if swift(>=4.2)
    private static let invalidBackgroundTaskIdentifier = UIBackgroundTaskIdentifier.invalid
    #else
    private static let invalidBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    #endif
    private var backgroundTaskIdentifier = invalidBackgroundTaskIdentifier

    func beginBackgroundTaskIfPossible() {
        precondition(Thread.isMainThread)
        guard backgroundTaskIdentifier == BackgroundTask.invalidBackgroundTaskIdentifier else { return }
        backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = BackgroundTask.invalidBackgroundTaskIdentifier
        }
    }
}
#else
class BackgroundTask {
    func beginBackgroundTaskIfPossible() {
    }
}
#endif
