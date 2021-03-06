//
//  LoadingStorageTests.swift
//  CoreTests
//
//  Created by Danil Lahtin on 30.05.2020.
//  Copyright © 2020 Danil Lahtin. All rights reserved.
//

import XCTest
import Core

private typealias Entity = UUID
private typealias Service = LoadingStorage<LoadingStorageTests.EntitiesLoaderSpy>

class LoadingStorageTests: XCTestCase {
    
    func test_subscribe_loadsEntities() {
        let (sut, loader) = makeSut()
        
        XCTAssertEqual(loader.loadCallCount, 0)
        sut.subscribeEntities()
        
        XCTAssertEqual(loader.loadCallCount, 1)
        sut.subscribeEntities()
        
        XCTAssertEqual(loader.loadCallCount, 2)
        loader.complete(with: [], at: 1)
        sut.subscribeEntities()
        
        XCTAssertEqual(loader.loadCallCount, 2)
    }
    
    func test_loadCompletionWithEntities_notifies() {
        let (sut, loader) = makeSut()
        
        let observer0 = SpyObserver<[Entity]>(sut: sut)
        let observer1 = SpyObserver<[Entity]>(sut: sut)
        
        XCTAssertEqual(observer0.retrieved, [])
        XCTAssertEqual(observer1.retrieved, [])
        
        let entities = makeEntities()
        loader.complete(with: entities)
        
        XCTAssertEqual(observer0.retrieved, [entities])
        XCTAssertEqual(observer1.retrieved, [entities])
    }
    
    func test_subscribeAfterSuccessfulLoad_notifiesWithPreviouslyLoadedEntities() {
        let (sut, loader) = makeSut()
        
        sut.subscribeEntities()
        let entities = makeEntities()
        loader.complete(with: entities)
        
        XCTAssertEqual(SpyObserver<[Entity]>(sut: sut).retrieved, [entities])
    }
    
    func test_loadCompletionWithEntities_doesNotNotifyError() {
        let (sut, loader) = makeSut()
        
        sut.subscribeEntities()
        loader.complete(with: [])
        
        XCTAssertEqual(SpyObserver<NSError>(sut: sut).retrieved, [])
    }
    
    func test_loadCompletionWithError_notifiesError() {
        let (sut, loader) = makeSut()
        let error = anyError()
        let errorObserver = SpyObserver<NSError>(sut: sut)
        
        sut.subscribeEntities()
        loader.complete(with: error, at: 0)
        
        XCTAssertEqual(errorObserver.retrieved, [error])
        XCTAssertEqual(SpyObserver<NSError>(sut: sut).retrieved, [])
        
        sut.subscribeEntities()
        loader.complete(with: error, at: 1)
        
        XCTAssertEqual(errorObserver.retrieved, [error, error])
        XCTAssertEqual(SpyObserver<NSError>(sut: sut).retrieved, [])
    }
    
    func test_cancelSubscription_doesNotNotify() {
        let (sut, loader) = makeSut()
        
        var retrieved = [[Entity]]()
        sut.subscribe(onNext: { retrieved.append($0) }).cancel()
        _ = sut.subscribe(onNext: { retrieved.append($0) })
        
        XCTAssertEqual(retrieved, [])
        
        loader.complete(with: makeEntities())
        XCTAssertEqual(retrieved, [])
    }
    
    func test_cancelErrorSubscription_doesNotNotify() {
        let (sut, loader) = makeSut()
        
        var retrieved = [NSError]()
        sut.subscribeEntities()
        sut.subscribe(onError: { retrieved.append($0 as NSError) }).cancel()
        _ = sut.subscribe(onError: { retrieved.append($0 as NSError) })
        
        XCTAssertEqual(retrieved, [])
        
        loader.complete(with: anyError())
        XCTAssertEqual(retrieved, [])
    }
    
    func test_refresh_loadsEntities() {
        let (sut, loader) = makeSut()
        
        XCTAssertEqual(loader.loadCallCount, 0)
        sut.subscribeEntities()
        
        XCTAssertEqual(loader.loadCallCount, 1)
        sut.refresh()
        
        XCTAssertEqual(loader.loadCallCount, 2)
        loader.complete(with: [], at: 1)
        sut.refresh()
        
        XCTAssertEqual(loader.loadCallCount, 3)
    }
    
    // MARK: - Helpers
    
    private func makeSut(
        file: StaticString = #file,
        line: UInt = #line) -> (sut: Service, loader: EntitiesLoaderSpy)
    {
        let loader = EntitiesLoaderSpy()
        let sut = Service(loader: loader)
        
        trackMemoryLeaks(for: sut, file: file, line: line)
        trackMemoryLeaks(for: sut, file: file, line: line)
        
        return (sut, loader)
    }
    
    private func makeEntities() -> [Entity] {
        [UUID(), UUID(), UUID()]
    }
    
    private func anyError() -> NSError {
        NSError(domain: "TestDomain", code: 0, userInfo: nil)
    }
    
    fileprivate final class EntitiesLoaderSpy: Loader {
        private var completions: [(Result<[Entity], Error>) -> ()] = []
        
        var loadCallCount: Int { completions.count }
        
        func load(_ completion: @escaping (Result<[Entity], Error>) -> ()) {
            completions.append(completion)
        }
        
        func complete(
            with entities: [Entity],
            at index: Int = 0,
            file: StaticString = #file,
            line: UInt = #line)
        {
            complete(with: .success(entities), at: index, file: file, line: line)
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
            with result: Result<[Entity], Error>,
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

private extension Service {
    func subscribeEntities() {
        _ = subscribe(onNext: { _ in })
    }
}


private extension SpyObserver where Value == [Service.Entity] {
    convenience init(sut: Service) {
        self.init(sut.subscribe(onNext:))
    }
}

private extension SpyObserver where Value == NSError {
    convenience init(sut: Service) {
        self.init { observeBlock in
            sut.subscribe(onError: {
                observeBlock($0 as NSError)
            })
        }
    }
}
