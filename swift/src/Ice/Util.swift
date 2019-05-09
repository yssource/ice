//
// Copyright (c) ZeroC, Inc. All rights reserved.
//

import Dispatch
import IceObjc

func stringToEncodingVersion(_ s: String) throws -> EncodingVersion {
    let (major, minor) = try stringToMajorMinor(s)
    return EncodingVersion(major: major, minor: minor)
}

func stringToMajorMinor(_ s: String) throws -> (UInt8, UInt8) {
    let components = s.components(separatedBy: ".")
    guard components.count == 2 else {
        throw VersionParseException(str: "malformed value `\(s)'")
    }

    guard let major = UInt8(components[0] as String), let minor = UInt8(components[1]) else {
        throw VersionParseException(str: "invalid version value `\(s)'")
    }

    return (major, minor)
}

func createSentCallback(sentOn: DispatchQueue?,
                        sentFlags: DispatchWorkItemFlags?,
                        sent: ((Bool) -> Void)?) -> ((Bool) -> Void)? {
    guard let s = sent, let q = sentOn else {
        //
        // This is either a nil sent callback or a sent callback that is dispatch
        // directly without a queue
        //
        return sent
    }

    //
    // Create a closure to dispatch the sent callback in the specified queue
    //
    if let flags = sentFlags {
        return { sentSynchronously in
            q.async(flags: flags) {
                s(sentSynchronously)
            }
        }
    } else {
        return { sentSynchronously in
            q.async {
                s(sentSynchronously)
            }
        }
    }
}

func escapeString(string: String, special: String, communicator: Communicator) throws -> String {
    return try autoreleasepool {
        try ICEUtil.escapeString(string: string,
                                 special: special,
                                 communicator: (communicator as! CommunicatorI).handle)
    }
}

func checkSupportedEncoding(_ v: EncodingVersion) throws {
    let c = currentEncoding
    if v.major != c.major || v.minor > c.minor {
        throw UnsupportedEncodingException(reason: "", bad: v, supported: c)
    }
}
