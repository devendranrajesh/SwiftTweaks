//
//  TweaksViewController.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 11/5/15.
//  Copyright © 2015 Khan Academy. All rights reserved.
//

import UIKit

public protocol TweaksViewControllerDelegate {
	func tweaksViewControllerRequestsDismiss(tweaksViewController: TweaksViewController, completion: (() -> ())?)
}

public class TweaksViewController: UIViewController {

	private let tweakStore: TweakStore

	private var navController: UINavigationController! // self required for init

	public var delegate: TweaksViewControllerDelegate?
	internal var floatingTweaksWindowPresenter: FloatingTweaksWindowPresenter?

	internal static let dismissButtonTitle = NSLocalizedString("Dismiss", comment: "Button to dismiss TweaksViewController.")

	public init(tweakStore: TweakStore) {
		self.tweakStore = tweakStore

		super.init(nibName: nil, bundle: nil)

		let tweakRootVC = TweaksRootViewController(tweakStore: tweakStore, delegate: self)
		navController = UINavigationController(rootViewController: tweakRootVC)
		navController.toolbarHidden = false
		view.addSubview(navController.view)
	}

	public required init?(coder aDecoder: NSCoder) {
	    fatalError("init(coder:) has not been implemented")
	}
}

extension TweaksViewController: TweaksRootViewControllerDelegate {
	internal func tweaksRootViewControllerDidPressDismissButton(tweaksRootViewController: TweaksRootViewController) {
		delegate?.tweaksViewControllerRequestsDismiss(self, completion: nil)
	}

	internal func tweaksRootViewController(tweaksRootViewController: TweaksRootViewController, requestsFloatingUIForTweakGroup tweakGroup: TweakGroup) {
		delegate?.tweaksViewControllerRequestsDismiss(self) {
			self.floatingTweaksWindowPresenter?.presentFloatingTweaksUIForTweakGroup(tweakGroup)
		}
	}
}
