//
//  AppStartFlowTests.swift
//  CatsDogsTests
//
//  Created by Danil Lahtin on 09.06.2020.
//  Copyright © 2020 Danil Lahtin. All rights reserved.
//

import XCTest
@testable import CatsDogs

enum SessionCheckResult {
    case exists
    case invalid
    case notFound
}

final class SessionCheckingSpy {
    private var completions: [(SessionCheckResult) -> ()] = []
    var requestsCount: Int { completions.count }
    
    func check(_ completion: @escaping (SessionCheckResult) -> () = { _ in }) {
        completions.append(completion)
    }
    
    func complete(
        with result: SessionCheckResult,
        at index: Int = 0,
        file: StaticString = #file,
        line: UInt = #line)
    {
        guard completions.indices.contains(index) else {
            XCTFail(
                "Completion at index \(index) not found, has only \(completions.count) completions",
                file: file,
                line: line)
            return
        }
        
        completions[index](result)
    }
}

final class AppStartFlow {
    let sessionChecking: SessionCheckingSpy
    let main: Flow
    let auth: Flow
    
    init(sessionChecking: SessionCheckingSpy, main: Flow, auth: Flow) {
        self.sessionChecking = sessionChecking
        self.main = main
        self.auth = auth
    }
    
    func start() {
        sessionChecking.check { [main, auth] in
            switch $0 {
            case .exists:
                main.start()
            case .invalid, .notFound:
                auth.start()
            }
        }
    }
}


class AppStartFlowTests: XCTestCase {
    func test_start_startsSessionCheck() {
        let sessionChecking = SessionCheckingSpy()
        let (sut, _, _) = makeSut(sessionChecking: sessionChecking)
        
        XCTAssertEqual(sessionChecking.requestsCount, 0)
        sut.start()
        
        XCTAssertEqual(sessionChecking.requestsCount, 1)
    }
    
    func test_start_doesNotStartFlows() {
        let (sut, main, auth) = makeSut()

        sut.start()
        
        XCTAssertEqual(main.startedCount, 0)
        XCTAssertEqual(auth.startedCount, 0)
    }
    
    func test_sessionCheckCompletionWithExists_startsMain() {
        let sessionChecking = SessionCheckingSpy()
        let (sut, main, auth) = makeSut(sessionChecking: sessionChecking)
        
        sut.start()
        
        sessionChecking.complete(with: .exists)
        
        XCTAssertEqual(main.startedCount, 1)
        XCTAssertEqual(auth.startedCount, 0)
    }
    
    func test_sessionCheckCompletionWithValid_startsAuth() {
        let sessionChecking = SessionCheckingSpy()
        let (sut, main, auth) = makeSut(sessionChecking: sessionChecking)
        
        sut.start()
        
        sessionChecking.complete(with: .invalid)
        
        XCTAssertEqual(main.startedCount, 0)
        XCTAssertEqual(auth.startedCount, 1)
    }
    
    func test_sessionCheckCompletionWithNotFound_startsAuth() {
        let sessionChecking = SessionCheckingSpy()
        let (sut, main, auth) = makeSut(sessionChecking: sessionChecking)
        
        sut.start()
        
        sessionChecking.complete(with: .notFound)
        
        XCTAssertEqual(main.startedCount, 0)
        XCTAssertEqual(auth.startedCount, 1)
    }
    
    // MARK: - Helpers
    
    private func makeSut(
        sessionChecking: SessionCheckingSpy = .init(),
        file: StaticString = #file,
        line: UInt = #line) -> (sut: AppStartFlow, main: FlowSpy, auth: FlowSpy)
    {
        let main = FlowSpy()
        let auth = FlowSpy()
        let sut = AppStartFlow(sessionChecking: sessionChecking, main: main, auth: auth)
        
        trackMemoryLeaks(for: sut, file: file, line: line)
        trackMemoryLeaks(for: main, file: file, line: line)
        trackMemoryLeaks(for: auth, file: file, line: line)
        trackMemoryLeaks(for: sessionChecking, file: file, line: line)
        
        return (sut, main, auth)
    }
}
