//
//  BaseViewController.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

protocol ViewController  {
	associatedtype Value
	var viewModel: Value { get }
	
	func initViews()
	func setupBindings()
}

// MARK: - Base View Controller
import UIKit

class BaseViewController<VM: ViewModel>: UIViewController, ViewController {
	var viewModel: VM
	
	init?(coder: NSCoder, viewModel: VM) {
		self.viewModel = viewModel
		super.init(coder: coder)
		debugPrint("init of ", String(describing: self))
	}

	@available(*, unavailable, renamed: "-")
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		initViews()
		setupBindings()
	}
	
	func initViews() {
		
	}

	func setupBindings() {
		viewModel.isLoadingPublisher.bind { isLoading in
			(cprint("Loading", isLoading) ? LoadingView.showLoadingView : LoadingView.hideLoadingView)()
		}

		viewModel.errorPublisher?.bind { [weak self] error in
			let alertController = UIAlertController(title: "error", message: error.localizedDescription, preferredStyle: .alert)
			let okAction = UIAlertAction(title:" ok", style: .default, handler: nil)
			alertController.addAction(okAction)
			self?.present(alertController, animated: true, completion: nil)
		}
	}
	
	deinit {
		debugPrint("deinit of ", String(describing: self))
	}
}
