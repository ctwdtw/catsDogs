//
//  SessionController.swift
//  CatsDogs
//
//  Created by Danil Lahtin on 09.06.2020.
//  Copyright © 2020 Danil Lahtin. All rights reserved.
//

import Core


final class SessionController {
    private let authorizeApi: AuthorizeApi
    private let logoutApi: LogoutApi
    private let tokenSaver: TokenSaver
    private let profileLoader: ProfileLoader
    private let tokenLoader: TokenLoader
    
    private(set) var profileInfo: ProfileInfo? {
        didSet {
            let state = profileInfo.map({ ProfileState.authorized($0.username) }) ?? .unauthorized
            didUpdateProfileState(state)
        }
    }
    
    public var didUpdateProfileState: (ProfileState) -> () = { _ in }
    
    init(authorizeApi: AuthorizeApi,
         logoutApi: LogoutApi,
         tokenSaver: TokenSaver,
         profileLoader: ProfileLoader,
         tokenLoader: TokenLoader) {
        self.authorizeApi = authorizeApi
        self.logoutApi = logoutApi
        self.tokenSaver = tokenSaver
        self.profileLoader = profileLoader
        self.tokenLoader = tokenLoader
    }
    
    func logout(_ completion: @escaping () -> ()) {
        logoutApi.logout { [weak self] _ in
            self?.profileInfo = nil
            completion()
        }
    }
}

extension SessionController: LoginRequest {
    func start(credentials: Credentials, _ completion: @escaping (Result<Void, Error>) -> ()) {
        authorizeApi.authorize(with: credentials) { [weak self, tokenSaver, profileLoader] in
            switch $0 {
            case .failure:
                completion($0.map({ _ in () }))
            case .success(let token):
                tokenSaver.save(token: token) {
                    switch $0 {
                    case .failure:
                        completion($0)
                    case .success:
                        profileLoader.load({
                            switch $0 {
                            case .failure(let error):
                                completion(.failure(error))
                            case .success(let profileInfo):
                                self?.profileInfo = profileInfo
                                completion(.success(()))
                            }
                        })
                    }
                }
            }
        }
    }
}
    
extension SessionController: SessionChecking {
    func check(_ completion: @escaping (SessionCheckResult) -> ()) {
        tokenLoader.load { [weak self, profileLoader] in
            switch $0 {
            case .success:
                profileLoader.load {
                    switch $0 {
                    case .success(let info):
                        self?.profileInfo = info
                        completion(.exists)
                    case .failure:
                        completion(.invalid)
                    }
                }
            case .failure:
                completion(.notFound)
            }
        }
    }
}
