//
//  ProfileViewController.swift
//  UI
//
//  Created by Danil Lahtin on 07.06.2020.
//  Copyright © 2020 Danil Lahtin. All rights reserved.
//

import UIKit
import Core

public final class ProfileViewController: UIViewController {
    public let profileViewContainerView = UIView()
    public let signInButtonContainerView = UIView()
    public let profileNameLabel = UILabel()
    public let signInButton = UIButton()
    
    public var onSignIn: () -> () = {}
    
    private var state: ProfileState = .unauthorized
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        signInButton.addTarget(self, action: #selector(onSigninButtonTapped), for: .touchUpInside)
        render(state: state)
    }
    
    public func profileUpdated(state: ProfileState) {
        self.state = state
        
        render(state: state)
    }
    
    private func render(state: ProfileState) {
        switch state {
        case .authorized(let user):
            signInButtonContainerView.isHidden = true
            profileViewContainerView.isHidden = false
            profileNameLabel.text = user
        case .unauthorized:
            signInButtonContainerView.isHidden = false
            profileViewContainerView.isHidden = true
        }
    }
    
    @objc
    func onSigninButtonTapped() {
        onSignIn()
    }
}
