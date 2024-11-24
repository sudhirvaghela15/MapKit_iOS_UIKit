//
//  MapViewController.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import UIKit

class MapViewController: BaseViewController {
	private lazy var searchController = makeSearchController()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		_ = searchController
		navigationController?.navigationBar.prefersLargeTitles = true
	}
	
	func makeSearchController() -> UISearchController {
		let searchController = UISearchController(
			searchResultsController: MapViewController
				.get(viewModel: MapViewModel(title: "Address List")))
		
		let searchBar = searchController.searchBar
		searchBar.sizeToFit()
		searchBar.placeholder = "Search"
		searchBar.searchTextField.leftView?.tintColor = UIColor.systemGray
		searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: searchBar.placeholder ?? "", attributes: [.foregroundColor: UIColor.systemGray])
		
		navigationItem.titleView = searchController.searchBar
		
		searchController.hidesNavigationBarDuringPresentation = false
		definesPresentationContext = true
		return searchController
	}
}

// MARK: - Factory Method
extension MapViewController {
	static func get(viewModel: ViewModel) -> UIViewController {
		let storyboard = UIStoryboard(
			name: "Map",
			bundle: Bundle.main
		)
		
		let view = storyboard.instantiate(MapViewController.self) { coder in
			MapViewController(coder: coder, viewModel: viewModel)
		}
		view.title = viewModel.title
		
		return view
	}
}
