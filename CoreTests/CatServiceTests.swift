//
//  CatServiceTests.swift
//  CoreTests
//
//  Created by Danil Lahtin on 30.05.2020.
//  Copyright © 2020 Danil Lahtin. All rights reserved.
//

import XCTest
import Core

// TODO:
// - thread safety
// - cancel subscription

class CatServiceTests: XCTestCase {
    func test_subscribe_loadsCats() {
        let (sut, loader) = makeSut()
        
        XCTAssertEqual(loader.loadCallCount, 0)
        sut.subscribe()
        
        XCTAssertEqual(loader.loadCallCount, 1)
        sut.subscribe()
        
        XCTAssertEqual(loader.loadCallCount, 2)
        loader.complete(with: [], at: 1)
        sut.subscribe()
        
        XCTAssertEqual(loader.loadCallCount, 2)
    }
    
    func test_loadCompletionWithCats_notifies() {
        let (sut, loader) = makeSut()
        
        let observer0 = CatsObserver(sut: sut)
        let observer1 = CatsObserver(sut: sut)
        
        XCTAssertEqual(observer0.retrieved, [])
        XCTAssertEqual(observer1.retrieved, [])
        
        let cats = makeCats()
        loader.complete(with: cats)
        
        XCTAssertEqual(observer0.retrieved, [cats])
        XCTAssertEqual(observer1.retrieved, [cats])
    }
    
    func test_subscribeAfterSuccessfulLoad_notifiesWithPreviouslyLoadedCats() {
        let (sut, loader) = makeSut()
        
        sut.subscribe()
        let cats = makeCats()
        loader.complete(with: cats)
        
        XCTAssertEqual(CatsObserver(sut: sut).retrieved, [cats])
    }
    
    func test_loadCompletionWithCats_doesNotNotifyError() {
        let (sut, loader) = makeSut()
        
        sut.subscribe()
        loader.complete(with: [])
        
        XCTAssertEqual(ErrorObserver(sut: sut).retrieved, [])
    }
    
    func test_loadCompletionWithError_notifiesError() {
        let (sut, loader) = makeSut()
        let error = anyError()
        let errorObserver = ErrorObserver(sut: sut)
        
        sut.subscribe()
        loader.complete(with: error, at: 0)
        
        XCTAssertEqual(errorObserver.retrieved, [error])
        XCTAssertEqual(ErrorObserver(sut: sut).retrieved, [])
        
        sut.subscribe()
        loader.complete(with: error, at: 1)
        
        XCTAssertEqual(errorObserver.retrieved, [error, error])
        XCTAssertEqual(ErrorObserver(sut: sut).retrieved, [])
    }
    
    func test_cancelSubscription_doesNotNotify() {
        let (sut, loader) = makeSut()
        
        var retrieved = [[Cat]]()
        sut.subscribe(onNext: { retrieved.append($0) }).cancel()
        _ = sut.subscribe(onNext: { retrieved.append($0) })
        
        XCTAssertEqual(retrieved, [])
        
        loader.complete(with: makeCats())
        XCTAssertEqual(retrieved, [])
    }
    
    // MARK: - Helpers
    
    private func makeSut(
        file: StaticString = #file,
        line: UInt = #line) -> (sut: CatService, loader: CatsLoaderSpy)
    {
        let loader = CatsLoaderSpy()
        let sut = CatService(loader: loader)
        
        trackMemoryLeaks(for: sut, file: file, line: line)
        trackMemoryLeaks(for: sut, file: file, line: line)
        
        return (sut, loader)
    }
    
    private func makeCats() -> [Cat] {
        [Cat(id: UUID()), Cat(id: UUID()), Cat(id: UUID())]
    }
    
    private func anyError() -> NSError {
        NSError(domain: "TestDomain", code: 0, userInfo: nil)
    }
    
    private final class CatsObserver {
        private var subscription: Cancellable!
        private(set) var retrieved: [[Cat]] = []
        
        init(sut: CatService) {
            subscription = sut.subscribe(onNext: { [weak self] in
                self?.retrieved.append($0)
            })
        }
    }
    
    private final class ErrorObserver {
        private(set) var retrieved: [NSError] = []
        
        init(sut: CatService) {
            sut.subscribe(onError: { [weak self] in
                self?.retrieved.append($0 as NSError)
            })
        }
    }
    
    private final class CatsLoaderSpy: CatLoader {
        private var completions: [(Result<[Cat], Error>) -> ()] = []
        
        var loadCallCount: Int { completions.count }
        
        func load(_ completion: @escaping (Result<[Cat], Error>) -> ()) {
            completions.append(completion)
        }
        
        func complete(
            with cats: [Cat],
            at index: Int = 0,
            file: StaticString = #file,
            line: UInt = #line)
        {
            complete(with: .success(cats), at: index, file: file, line: line)
        }
        
        func complete(
            with error: Error,
            at index: Int = 0,
            file: StaticString = #file,
            line: UInt = #line)
        {
            complete(with: .failure(error), at: index, file: file, line: line)
        }
        
        func complete(
            with result: Result<[Cat], Error>,
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
}

private extension CatService {
    func subscribe() {
        _ = subscribe(onNext: { _ in })
    }
}
