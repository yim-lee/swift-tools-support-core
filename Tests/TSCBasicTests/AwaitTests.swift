/*
 This source file is part of the Swift.org open source project

 Copyright (c) 2014 - 2021 Apple Inc. and the Swift project authors
 Licensed under Apache License v2.0 with Runtime Library Exception

 See http://swift.org/LICENSE.txt for license information
 See http://swift.org/CONTRIBUTORS.txt for Swift project authors
*/

import XCTest
import Dispatch

import TSCBasic

class AwaitTests: XCTestCase {
    func testAwait() throws {
        let value = try tsc_await { async("Hi", $0) }
        XCTAssertEqual("Hi", value)

        do {
            let value = try tsc_await { throwingAsync("Hi", $0) }
            XCTFail("Unexpected success \(value)")
        } catch {
            XCTAssertEqual(error as? DummyError, DummyError.error)
        }
    }

    func testAwaitUntil() throws {
        let value = try tsc_await(until: Date().advanced(by: 1)) { async("Hi", $0) }
        XCTAssertEqual("Hi", value)

        do {
            let value = try tsc_await(until: Date().advanced(by: 1)) { throwingAsync("Hi", $0) }
            XCTFail("Unexpected success \(value)")
        } catch {
            XCTAssertEqual(error as? DummyError, DummyError.error)
        }
        
        do {
            let value = try tsc_await(until: Date().advanced(by: 0.01)) { async("Hi", delay: .milliseconds(100), $0) }
            XCTFail("Unexpected success \(value)")
        } catch {
            XCTAssertEqual(error as? TSCAwaitError, .timedOut)
        }
    }
    
    private func async(_ param: String, delay: DispatchTimeInterval? = nil, _ completion: @escaping (Result<String, Error>) -> Void) {
        if let delay = delay {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                completion(.success(param))
            }
        } else {
            DispatchQueue.global().async {
                completion(.success(param))
            }
        }
    }

    private func throwingAsync(_ param: String, delay: DispatchTimeInterval? = nil, _ completion: @escaping (Result<String, Error>) -> Void) {
        if let delay = delay {
            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                completion(.failure(DummyError.error))
            }
        } else {
            DispatchQueue.global().async {
                completion(.failure(DummyError.error))
            }
        }
    }
    
    private enum DummyError: Error {
        case error
    }
}
