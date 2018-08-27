//
//  CoreDataService.swift
//  OrangeB
//
//  Created by Víctor Varillas on 23/08/2018.
//  Copyright © 2018 VVL. All rights reserved.
//

import SystemConfiguration
import Foundation

public let ReachabilityChangedNotification = "ReachabilityChangedNotification"

open class ReachabilityService: ServiceProtocol {
    // MARK: - *** ReachabilityService ***
    fileprivate static var sharedInstance: ReachabilityService?

    open static func start() {

        if sharedInstance == nil {
            let url:URL? = URL(string: "https://api.myjson.com/bins")!
            if url != nil && url!.host != nil {
                sharedInstance = ReachabilityService(hostname:url!.host!)
                _ = sharedInstance?.startNotifier()
            }
        } else {
            print("ERROR: ReachabilityService is trying to start 2 times")
        }
    }

    open static func stop() {
        sharedInstance?.stopNotifier()
        sharedInstance = nil
    }

    open static func isRunning() -> Bool {
        return sharedInstance != nil
    }

    // MARK: - *** Public ***
    /**
        Status of the network connection.
    
        - NotReachable: No network connection is reaching the server
        - ReachableViaWiFi: A wifi network connection can reach the server.
        - ReachableViaWWAN: A cellular connection can reach the server
    */
    public enum NetworkStatus {
        case notReachable, reachableViaWiFi, reachableViaWWAN
    }

    //The current Reachability Status
    open static var currentReachabilityStatus: NetworkStatus {
        if sharedInstance!.isReachable() {
            if sharedInstance!.isReachableViaWiFi() {
                return .reachableViaWiFi
            }
            if sharedInstance!.isRunningOnDevice {
                return .reachableViaWWAN
            }
        }
        return .notReachable
    }

    // MARK: - *** Private ***
    fileprivate var notificationCenter = NotificationCenter.default
    fileprivate var reachableOnWWAN: Bool

    fileprivate init(reachabilityRef: SCNetworkReachability) {
        reachableOnWWAN = true
        self.reachabilityRef = reachabilityRef
    }

    fileprivate convenience init(hostname: String) {
        let ref = SCNetworkReachabilityCreateWithName(nil, (hostname as NSString).utf8String!)
        self.init(reachabilityRef: ref!)
    }

    fileprivate class func reachabilityForInternetConnection() -> ReachabilityService {
        var zeroAddress = sockaddr_in(sin_len: __uint8_t(0), sin_family: sa_family_t(0), sin_port: in_port_t(0), sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)

        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        })
        return ReachabilityService(reachabilityRef: defaultRouteReachability!)
    }

    fileprivate class func reachabilityForLocalWiFi() -> ReachabilityService {
        var localWifiAddress: sockaddr_in = sockaddr_in(sin_len: __uint8_t(0), sin_family: sa_family_t(0), sin_port: in_port_t(0), sin_addr: in_addr(s_addr: 0), sin_zero: (0, 0, 0, 0, 0, 0, 0, 0))
        localWifiAddress.sin_len = UInt8(MemoryLayout.size(ofValue: localWifiAddress))
        localWifiAddress.sin_family = sa_family_t(AF_INET)

        // IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
        let address: Int64 = 0xA9FE0000
        localWifiAddress.sin_addr.s_addr = in_addr_t(address.bigEndian)

        let defaultRouteReachability = withUnsafePointer(to: &localWifiAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        })
        return ReachabilityService(reachabilityRef: defaultRouteReachability!)
    }

    // MARK: - *** Notifier methods ***
    fileprivate func startNotifier() -> Bool {
        reachabilityObject = self
        _ = self.reachabilityRef!

        previousReachabilityFlags = reachabilityFlags

        let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags(rawValue: 0), queue: timer_queue)
        timer.schedule(deadline: DispatchTime.init(uptimeNanoseconds: UInt64(100000)), repeating: DispatchTimeInterval.seconds(5), leeway: DispatchTimeInterval.seconds(1))

        timer.setEventHandler(handler: { [unowned self] in
            self.timerFired()
        })

        timer.resume()
        return true
    }

    fileprivate func stopNotifier() {

        reachabilityObject = nil

        if let timer = dispatch_timer {
            timer.cancel()
            dispatch_timer = nil
        }
    }

    // MARK: - *** Connection test methods ***
    fileprivate func isReachable() -> Bool {
        return isReachableWithTest({ (flags: SCNetworkReachabilityFlags) -> (Bool) in
            return self.isReachableWithFlags(flags)
        })
    }

    fileprivate func isReachableViaWWAN() -> Bool {

        if isRunningOnDevice {
            return isReachableWithTest { flags -> Bool in
                // Check we're REACHABLE
                if self.isReachable(flags) {

                    // Now, check we're on WWAN
                    if self.isOnWWAN(flags) {
                        return true
                    }
                }
                return false
            }
        }
        return false
    }

    fileprivate func isReachableViaWiFi() -> Bool {

        return isReachableWithTest { flags -> Bool in

            // Check we're reachable
            if self.isReachable(flags) {

                if self.isRunningOnDevice {
                    // Check we're NOT on WWAN
                    if self.isOnWWAN(flags) {
                        return false
                    }
                }
                return true
            }
            return false
        }
    }

    fileprivate var isRunningOnDevice: Bool = {
        #if targetEnvironment(simulator)
            return false
            #else
            return true
        #endif
        }()

    fileprivate var reachabilityRef: SCNetworkReachability?
    fileprivate var reachabilityObject: AnyObject?
    fileprivate var dispatch_timer: DispatchSource?
    fileprivate lazy var timer_queue: DispatchQueue = {
        return DispatchQueue(label: "com.generic.reachability_timer_queue", attributes: [])
        }()
    fileprivate var previousReachabilityFlags: SCNetworkReachabilityFlags?

    func timerFired() {
        let currentReachabilityFlags = reachabilityFlags
        if let _ = previousReachabilityFlags {
            if currentReachabilityFlags != previousReachabilityFlags {
                DispatchQueue.main.async(execute: { [unowned self] in
                    self.reachabilityChanged(currentReachabilityFlags)
                    self.previousReachabilityFlags = currentReachabilityFlags
                    })
            }
        }
    }

    fileprivate func reachabilityChanged(_ flags: SCNetworkReachabilityFlags) {
        notificationCenter.post(name: Notification.Name(rawValue: ReachabilityChangedNotification), object:self)
    }

    fileprivate func isReachableWithFlags(_ flags: SCNetworkReachabilityFlags) -> Bool {

        let reachable = isReachable(flags)

        if !reachable {
            return false
        }

        if isConnectionRequiredOrTransient(flags) {
            return false
        }

        if isRunningOnDevice {
            if isOnWWAN(flags) && !reachableOnWWAN {
                // We don't want to connect when on 3G.
                return false
            }
        }

        return true
    }

    fileprivate func isReachableWithTest(_ test: (SCNetworkReachabilityFlags) -> (Bool)) -> Bool {
        var flags: SCNetworkReachabilityFlags = []
        let gotFlags = SCNetworkReachabilityGetFlags(reachabilityRef!, &flags) != false
        if gotFlags {
            return test(flags)
        }
        return false
    }

    // WWAN may be available, but not active until a connection has been established.
    // WiFi may require a connection for VPN on Demand.
    fileprivate func isConnectionRequired() -> Bool {
        return connectionRequired()
    }

    fileprivate func connectionRequired() -> Bool {
        return isReachableWithTest({ (flags: SCNetworkReachabilityFlags) -> (Bool) in
            return self.isConnectionRequired(flags)
        })
    }

    // Dynamic, on demand connection?
    fileprivate func isConnectionOnDemand() -> Bool {
        return isReachableWithTest({ (flags: SCNetworkReachabilityFlags) -> (Bool) in
            return self.isConnectionRequired(flags) && self.isConnectionOnTrafficOrDemand(flags)
        })
    }

    // Is user intervention required?
    fileprivate func isInterventionRequired() -> Bool {
        return isReachableWithTest({ (flags: SCNetworkReachabilityFlags) -> (Bool) in
            return self.isConnectionRequired(flags) && self.isInterventionRequired(flags)
        })
    }

    fileprivate func isOnWWAN(_ flags: SCNetworkReachabilityFlags) -> Bool {
        #if os(iOS)
            return flags.intersection(SCNetworkReachabilityFlags.isWWAN) != []
            #else
            return false
        #endif
    }
    fileprivate func isReachable(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.intersection(SCNetworkReachabilityFlags.reachable) != []
    }
    fileprivate func isConnectionRequired(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.intersection(SCNetworkReachabilityFlags.connectionRequired) != []
    }
    fileprivate func isInterventionRequired(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.intersection(SCNetworkReachabilityFlags.interventionRequired) != []
    }
    fileprivate func isConnectionOnTraffic(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.intersection(SCNetworkReachabilityFlags.connectionOnTraffic) != []
    }
    fileprivate func isConnectionOnDemand(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.intersection(SCNetworkReachabilityFlags.connectionOnDemand) != []
    }
    func isConnectionOnTrafficOrDemand(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.intersection(SCNetworkReachabilityFlags.connectionOnTraffic.union(SCNetworkReachabilityFlags.connectionOnDemand)) != []
    }
    fileprivate func isTransientConnection(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.intersection(SCNetworkReachabilityFlags.transientConnection) != []
    }
    fileprivate func isLocalAddress(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.intersection(SCNetworkReachabilityFlags.isLocalAddress) != []
    }
    fileprivate func isDirect(_ flags: SCNetworkReachabilityFlags) -> Bool {
        return flags.intersection(SCNetworkReachabilityFlags.isDirect) != []
    }
    fileprivate func isConnectionRequiredOrTransient(_ flags: SCNetworkReachabilityFlags) -> Bool {
        let testcase: SCNetworkReachabilityFlags = [.connectionRequired, .transientConnection]
        return flags.intersection(testcase) == testcase
    }

    fileprivate var reachabilityFlags: SCNetworkReachabilityFlags {
        guard let reachabilityRef = reachabilityRef else { return SCNetworkReachabilityFlags() }

        var flags = SCNetworkReachabilityFlags()
        let gotFlags = withUnsafeMutablePointer(to: &flags) {
            SCNetworkReachabilityGetFlags(reachabilityRef, UnsafeMutablePointer($0))
        }

        if gotFlags {
            return flags
        } else {
            return SCNetworkReachabilityFlags()
        }
    }

    deinit {
        stopNotifier()
        reachabilityRef = nil
    }

}
