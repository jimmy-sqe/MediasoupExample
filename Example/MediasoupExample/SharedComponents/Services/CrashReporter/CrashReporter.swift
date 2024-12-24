//
//  CrashReporter.swift
//  SqeIdFramework
//
//  Created by Marthin Satrya Pasaribu on 27/11/23.
//

import Foundation
import Sentry

public protocol CrashReporter {
    func sendErrorEvent(error: String, detail: String?, info: [String: Any]?)
}

class CrashReporterImpl: CrashReporter {
    static var hub: SentryHub?
    
    static private var signalReportWasSent = false
    private let token: String
    private let isClientUseSentry: Bool
    private lazy var sqeSdkRegex = try? NSRegularExpression(pattern: ".*sqe\\w+framework.*")
    
    static let signalNameMap: [Int32: String] = [
        SIGABRT: "SIGABRT",
        SIGALRM: "SIGALRM",
        SIGBUS:  "SIGBUS",
        SIGCHLD: "SIGCHLD",
        SIGCONT: "SIGCONT",
        SIGFPE:  "SIGFPE",
        SIGHUP:  "SIGHUP",
        SIGILL:  "SIGILL",
        SIGINT:  "SIGINT",
        SIGKILL: "SIGKILL",
        SIGPIPE: "SIGPIPE",
        SIGQUIT: "SIGQUIT",
        SIGSEGV: "SIGSEGV",
        SIGSTOP: "SIGSTOP",
        SIGTERM: "SIGTERM",
        SIGTRAP: "SIGTRAP",
        SIGTSTP: "SIGTSTP",
        SIGTTIN: "SIGTTIN",
        SIGTTOU: "SIGTTOU",
        SIGUSR1: "SIGUSR1",
        SIGUSR2: "SIGUSR2",
        SIGPROF: "SIGPROF",
        SIGSYS:  "SIGSYS",
        SIGURG:  "SIGURG",
        SIGVTALRM: "SIGVTALRM",
        SIGXCPU: "SIGXCPU",
        SIGXFSZ: "SIGXFSZ",
    ]
    
    init(token: String, isClientUseSentry: Bool) {
        self.token = token
        self.isClientUseSentry = isClientUseSentry
        
        if isClientUseSentry {
            initializeSentryWithHub()
        } else {
            initializeSentry()
        }
    }
    
    static func sendReport(subject: String, body: String?, info: [String: Any]?, shouldExit: Bool = false) {
        let errorEvent: Event = Event(level: .error)
        errorEvent.message = SentryMessage(formatted: subject)
        if let body = body {
            errorEvent.extra = [
                "message": body
            ]
            
            if let info {
                errorEvent.extra?.merge(info) { (_, new) in new }
            }
        }
        
        CrashReporterImpl.hub?.capture(event: errorEvent)
        SentrySDK.capture(event: errorEvent)
        
        #if !DEBUG
        if shouldExit {
            exit(0)
        }
        #endif
    }
    
    func sendErrorEvent(error: String, detail: String?, info: [String: Any]?) {
        DispatchQueue.main.async {
            CrashReporterImpl.sendReport(subject: error, body: detail, info: info)
        }
    }
    
    func initializeSentryWithHub() {
        self.registerSignalHandler()
        self.registerSetCaughtHandler()
        
        let options = Options()
        options.dsn = token
        let client = SentryClient(options: options)
        let scope = Scope()
        CrashReporterImpl.hub = SentryHub(client: client, andScope: scope)
    }
    
    func initializeSentry() {
        SentrySDK.start { option in
            option.dsn = self.token
            option.beforeSend = { event in
                if let eventExceptions = event.exceptions, !eventExceptions.isEmpty {
                    for exception in event.exceptions ?? [] {
                        let frames = exception.stacktrace?.frames.filter {
                            guard let sqeSdkRegex = self.sqeSdkRegex,
                                  let package = $0.package?.lowercased() else { return false }
                            
                            return sqeSdkRegex.matches(package)
                        } ?? []
                        if !frames.isEmpty {
                            return event
                        }
                    }
                } else if event.level == .error {
                    return event
                }
                return nil
            }
        }
    }
    
    private func registerSignalHandler() {
        signal(EXC_BREAKPOINT) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(EXC_CRASH) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(EXC_BAD_ACCESS) {  (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(EXC_BAD_INSTRUCTION) {  (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGINT) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGABRT) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGKILL) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGTRAP) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGBUS) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGSEGV) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGHUP) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGTERM) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGILL) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGFPE) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
        signal(SIGPIPE) { (i: Int32) in CrashReporterImpl.handleSignalError(i) }
    }
    
    private func registerSetCaughtHandler() {
        NSSetUncaughtExceptionHandler { (exception: NSException) in
            if let errorString = CrashReporterImpl.prepareStringError(title: "\(exception.name)", message: exception.reason) {
                CrashReporterImpl.prepareReport(errorString)
            }
        }
    }
    
    static private func handleSignalError(_ signal: Int32) {
        switch(signal) {
        case EXC_BREAKPOINT, EXC_CRASH, EXC_BAD_ACCESS, EXC_BAD_INSTRUCTION,
            SIGINT, SIGABRT, SIGKILL, SIGTRAP, SIGBUS, SIGSEGV, SIGHUP, SIGTERM, SIGILL, SIGFPE, SIGPIPE:
            if let signalTrace = CrashReporterImpl.prepareStringError(title: signalNameMap[signal] ?? "Unknown Signal", message: nil) {
                CrashReporterImpl.prepareReport(signalTrace)
            }
            exit(0)
        default:
            exit(0)
        }
    }
    
    static func prepareStringError(title: String, message: String?) -> String? {
        var isCrashCanReport = false
        var threadStackTrace = ""
        
        threadStackTrace.append(title)
        threadStackTrace.append("\n\n")
        if let message = message, !message.isEmpty {
            threadStackTrace.append(message)
            threadStackTrace.append("\n\n")
        }
        
        _ = Thread.callStackSymbols.map {
            if let errorId = getIdentifier(from: $0), errorId.lowercased() == AppConfiguration.sdkName {
                isCrashCanReport = true
            }
            threadStackTrace.append("\($0)\n")
        }
        threadStackTrace.append("isCrashCanReport \(isCrashCanReport)")
        return isCrashCanReport ? threadStackTrace : nil
    }

    static func prepareReport(_ stackTrace: String) {
        var result = ""
        Thread.callStackSymbols.forEach {
            result += "\($0) - "
        }
        
        if signalReportWasSent == true {
            return // Avoid sending multiple signal reports
        }
        signalReportWasSent = true
        let subject = "Crash \(stackTrace)"
        var body = ""
        body.append("User: ")
        body.append(getUserUUID())
        body.append("\n")
        body.append(prepareDeviceDetails())
        body.append("\n\n")
        body.append(stackTrace)
        body.append("Detail Result")
        body.append(result)
        CrashReporterImpl.sendReport(subject: subject, body: body, info: nil, shouldExit: true)
    }
    
    static private func getUserUUID() -> String {
        var uuid = ""
        if let existingUUID = UserDefaults.standard.value(forKey: "CrashReporterUUID") as? String {
            uuid = existingUUID
        } else {
            uuid = UUID().uuidString
            UserDefaults.standard.set(uuid, forKey: "CrashReporterUUID")
            UserDefaults.standard.synchronize()
        }
        return uuid
    }

    static private func prepareDeviceDetails() -> String {
        var subject = ""
        subject.append("Bundle identifier: ")
        subject.append(Bundle.main.bundleIdentifier ?? "")
        subject.append("\n")
        subject.append("Version: ")
        subject.append("\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!)")
        subject.append("\n")
        subject.append("Build: ")
        subject.append("\(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!)")
        subject.append("\n")
        subject.append("System: ")
        subject.append(UIDevice.current.systemName)
        subject.append(" ")
        subject.append(UIDevice.current.systemVersion)
        return subject
    }

    static private func getIdentifier(from string: String) -> String? {
        let pattern = "^\\s*(\\d+)\\s+(\\w+)\\s+0x"
        let regex = try? NSRegularExpression(pattern: pattern, options: [])

        let nsString = string as NSString
        let results = regex?.matches(in: string, options: [], range: NSRange(location: 0, length: nsString.length))

        if let match = results?.first {
            let firstGroup = nsString.substring(with: match.range(at: 1))
            if firstGroup == "8" {
                return nsString.substring(with: match.range(at: 2)).lowercased()
            }
        }

        return nil
    }
}
