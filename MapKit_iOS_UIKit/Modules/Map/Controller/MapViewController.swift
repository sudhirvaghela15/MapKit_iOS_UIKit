//
//  MapViewController.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import UIKit

class MapViewController: BaseViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
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
