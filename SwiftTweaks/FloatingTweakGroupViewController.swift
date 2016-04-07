//
//  FloatingTweakGroupViewController.swift
//  SwiftTweaks
//
//  Created by Bryan Clark on 4/6/16.
//  Copyright © 2016 Khan Academy. All rights reserved.
//

import Foundation

// MARK: - FloatingTweaksWindowPresenter
internal protocol FloatingTweaksWindowPresenter {
	func presentFloatingTweaksUIForTweakGroup(tweakGroup: TweakGroup)
	func dismissFloatingTweaksUI()
}

// MARK: - FloatingTweakGroupViewController

internal class FloatingTweakGroupViewController: UIViewController {
	internal static let height: CGFloat = 168
	internal static let margins: CGFloat = 5
	private static let minimizedWidth: CGFloat = 30

	var tweakGroup: TweakGroup? {
		didSet {
			titleLabel.text = tweakGroup?.title
			self.tableView.reloadData()
		}
	}

	private let presenter: FloatingTweaksWindowPresenter
	private let tweakStore: TweakStore

	internal init(tweakStore: TweakStore, presenter: FloatingTweaksWindowPresenter) {
		self.tweakStore = tweakStore
		self.presenter = presenter

		super.init(nibName: nil, bundle: nil)

		installSubviews()
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	internal var fullFrame: CGRect? {
		didSet {
			guard let fullFrame = fullFrame else { return }
			view.frame = fullFrame
		}
	}

	internal var minimizedFrameOriginX: CGFloat? {
		if let fullFrame = fullFrame {
			return fullFrame.size.width - FloatingTweakGroupViewController.minimizedWidth + fullFrame.origin.x*2
		} else {
			return nil
		}
	}

	// MARK: Subviews
	private static let closeButtonSize = CGSize(width: 42, height: 32)
	private static let navBarHeight: CGFloat = 32
	private static let windowCornerRadius: CGFloat = 5

	private let navBar: UIView = {
		let view = UIView()
		view.backgroundColor = AppTheme.Colors.floatingTweakGroupNavBG

		view.layer.shadowColor = AppTheme.Shadows.floatingNavShadowColor
		view.layer.shadowOpacity = AppTheme.Shadows.floatingNavShadowOpacity
		view.layer.shadowOffset = AppTheme.Shadows.floatingNavShadowOffset
		view.layer.shadowRadius = AppTheme.Shadows.floatingNavShadowRadius

		return view
	}()

	private let titleLabel: UILabel = {
		let label = UILabel()
		label.textColor = AppTheme.Colors.sectionHeaderTitleColor
		label.font = AppTheme.Fonts.sectionHeaderTitleFont
		return label
	}()

	private let closeButton: UIButton = {
		let button = UIButton()
		let buttonImage = UIImage(swiftTweaksImage: .FloatingCloseButton).imageWithRenderingMode(.AlwaysTemplate)
		button.setImage(buttonImage.imageTintedWithColor(AppTheme.Colors.controlTinted), forState: .Normal)
		button.setImage(buttonImage.imageTintedWithColor(AppTheme.Colors.controlTintedPressed), forState: .Highlighted)
		return button
	}()

	private let tableView: UITableView = {
		let tableView = UITableView(frame: .zero, style: .Plain)
		tableView.backgroundColor = .clearColor()
		tableView.registerClass(TweakTableCell.self, forCellReuseIdentifier: FloatingTweakGroupViewController.TweakTableViewCellIdentifer)
		tableView.contentInset = UIEdgeInsets(top: FloatingTweakGroupViewController.navBarHeight, left: 0, bottom: 0, right: 0)
		tableView.separatorColor = AppTheme.Colors.tableSeparator
		tableView.separatorInset = tableView.contentInset
		return tableView
	}()

	private let restoreButton: UIButton = {
		let button = UIButton()
		let buttonImage = UIImage(swiftTweaksImage: .FloatingMinimizedArrow).imageWithRenderingMode(.AlwaysTemplate)
		button.setImage(buttonImage.imageTintedWithColor(AppTheme.Colors.secondaryControl), forState: .Normal)
		button.setImage(buttonImage.imageTintedWithColor(AppTheme.Colors.secondaryControlPressed), forState: .Highlighted)
		button.hidden = true
		return button
	}()

	private let backgroundView = UIVisualEffectView(effect: UIBlurEffect(style: .Light))

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		layoutSubviews()
	}

	private func installSubviews() {
		// Create the rounded corners and shadows
		view.layer.cornerRadius = FloatingTweakGroupViewController.windowCornerRadius
		view.layer.shadowColor = AppTheme.Shadows.floatingShadowColor
		view.layer.shadowOffset = AppTheme.Shadows.floatingShadowOffset
		view.layer.shadowRadius = AppTheme.Shadows.floatingShadowRadius
		view.layer.shadowOpacity = AppTheme.Shadows.floatingShadowOpacity

		// Set up the blurry background
		view.backgroundColor = .clearColor()
		backgroundView.layer.cornerRadius = FloatingTweakGroupViewController.windowCornerRadius
		backgroundView.clipsToBounds = true
		self.view.addSubview(backgroundView)

		// The table view
		tableView.delegate = self
		tableView.dataSource = self
		view.addSubview(tableView)

		// The "fake nav bar"
		closeButton.addTarget(self, action: #selector(FloatingTweakGroupViewController.closeButtonTapped), forControlEvents: .TouchUpInside)
		navBar.addSubview(closeButton)
		navBar.addSubview(titleLabel)
		view.addSubview(navBar)

		// The restore button
		restoreButton.addTarget(self, action: #selector(FloatingTweakGroupViewController.restore), forControlEvents: .TouchUpInside)
		view.addSubview(restoreButton)

		// The pan gesture recognizer
		let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(FloatingTweakGroupViewController.moveWindowPanGestureRecognized(_:)))
		panGestureRecognizer.delegate = self
		view.addGestureRecognizer(panGestureRecognizer)
	}

	private func layoutSubviews() {
		backgroundView.frame = self.view.bounds

		tableView.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: FloatingTweakGroupViewController.height))

		navBar.frame = CGRect(origin: .zero, size: CGSize(width: view.bounds.width, height: FloatingTweakGroupViewController.navBarHeight))

		// Round the top two corners of the nav bar
		navBar.layer.mask = {
			let maskPath = UIBezierPath(
				roundedRect: view.bounds,
				byRoundingCorners: [.TopLeft, .TopRight],
				cornerRadii: CGSize(
					width: FloatingTweakGroupViewController.windowCornerRadius,
					height: FloatingTweakGroupViewController.windowCornerRadius
				)).CGPath
			let mask = CAShapeLayer()
			mask.path = maskPath
			return mask
			}()

		closeButton.frame = CGRect(origin: .zero, size: FloatingTweakGroupViewController.closeButtonSize)
		titleLabel.frame = CGRect(
			origin: CGPoint(
				x: closeButton.frame.width,
				y: 0
			),
			size: CGSize(
				width: view.bounds.width - closeButton.frame.width,
				height: navBar.bounds.height
			)
		)

		restoreButton.frame = CGRect(
			origin: .zero,
			size: CGSize(
				width: FloatingTweakGroupViewController.minimizedWidth,
				height: view.bounds.height
			)
		)
	}

	// MARK: Actions

	@objc private func closeButtonTapped() {
		presenter.dismissFloatingTweaksUI()
	}

	@objc private func moveWindowPanGestureRecognized(gestureRecognizer: UIPanGestureRecognizer) {
		switch (gestureRecognizer.state) {
		case .Began:
			gestureRecognizer.setTranslation(self.view.frame.origin, inView: self.view)
		case .Changed:
			view.frame.origin.x = gestureRecognizer.translationInView(self.view).x
		case .Possible, .Ended, .Cancelled, .Failed:
			let gestureIsMovingToTheRight = (gestureRecognizer.velocityInView(nil).x > 10)
			let viewIsKindaNearTheRight = view.frame.origin.x > 30
			if gestureIsMovingToTheRight && viewIsKindaNearTheRight {
				minimize()
			} else {
				restore()
			}
		}
	}

	private func minimize() {
		// TODO map the continuous gesture's velocity into the animation.
		guard let minimizedFrameOriginX = minimizedFrameOriginX else { return }

		self.restoreButton.alpha = 0
		self.restoreButton.hidden = false

		UIView.animateWithDuration(
			0.3,
			delay: 0,
			usingSpringWithDamping: 0.8,
			initialSpringVelocity: 0,
			options: .BeginFromCurrentState,
			animations: {
				self.view.frame.origin.x = minimizedFrameOriginX
				self.tableView.alpha = 0
				self.navBar.alpha = 0
				self.restoreButton.alpha = 1
		}) { _ in

		}
	}

	@objc private func restore() {
		// TODO map the continuous gesture's velocity into the animation
		guard let fullFrame = fullFrame else { return }

		UIView.animateWithDuration(
			0.3,
		   delay: 0,
		   usingSpringWithDamping: 0.8,
		   initialSpringVelocity: 0,
		   options: .BeginFromCurrentState,
		   animations: {
			self.view.frame.origin.x = fullFrame.origin.x
			self.tableView.alpha = 1
			self.navBar.alpha = 1
			self.restoreButton.alpha = 0
		}) { _ in
			self.restoreButton.hidden = true
		}
	}
}

extension FloatingTweakGroupViewController: UIGestureRecognizerDelegate {
	func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
		guard let hitView = gestureRecognizer.view?.hitTest(gestureRecognizer.locationInView(gestureRecognizer.view), withEvent: nil) else {
			return true
		}

		// We don't want to move the window if you're trying to drag a slider or a switch!
		// But if you're dragging on the restore button, that's what we do want!
		if hitView.isKindOfClass(UIControl.self) && hitView != restoreButton {
			return false
		} else {
			return true
		}
	}
}

// MARK: Table View

extension FloatingTweakGroupViewController: UITableViewDelegate {
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		guard let tweak = tweakAtIndexPath(indexPath) else { return }
		switch tweak.tweakViewDataType {
		case .UIColor:
			let alert = UIAlertController(title: "Can't edit colors here.", message: "Sorry, haven't built out the floating UI for it yet!", preferredStyle: .Alert)
			alert.addAction(UIAlertAction(title: "Dismiss", style: .Default, handler: nil))
			presentViewController(alert, animated: true, completion: nil)
		case .Boolean, .Integer, .CGFloat, .Double:
			break
		}
	}
}

extension FloatingTweakGroupViewController: UITableViewDataSource {
	private static let TweakTableViewCellIdentifer = "TweakTableViewCellIdentifer"

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return tweakGroup?.tweaks.count ?? 0
	}

	func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}

	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

		let cell = tableView.dequeueReusableCellWithIdentifier(FloatingTweakGroupViewController.TweakTableViewCellIdentifer, forIndexPath: indexPath) as! TweakTableCell

		guard let tweak = tweakAtIndexPath(indexPath) else { return cell }

		cell.textLabel?.text = tweak.tweakName
		cell.isInFloatingTweakGroupWindow = true
		cell.viewData = tweakStore.currentViewDataForTweak(tweak)
		cell.delegate = self
		cell.backgroundColor = .clearColor()
		cell.contentView.backgroundColor = .clearColor()

		return cell
	}

	private func tweakAtIndexPath(indexPath: NSIndexPath) -> AnyTweak? {
		return tweakGroup?.sortedTweaks[indexPath.row]
	}
}

// MARK: TweakTableCellDelegate

extension FloatingTweakGroupViewController: TweakTableCellDelegate {
	func tweakCellDidChangeCurrentValue(tweakCell: TweakTableCell) {
		if let
			indexPath = tableView.indexPathForCell(tweakCell),
			viewData = tweakCell.viewData,
			tweak = tweakAtIndexPath(indexPath)
		{
			tweakStore.setValue(viewData, forTweak: tweak)
		}
	}
}