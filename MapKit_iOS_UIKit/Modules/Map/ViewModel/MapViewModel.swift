//
//  MapViewModel.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import Foundation
import MapKit.MKPlacemark

class MapViewModel: BaseViewModel {
	
	init(title: String) {
		super.init()
		self.title = title
	}
	
	private var deviceLocation: CLLocation? {
		didSet {
			guard let deviceLocation = deviceLocation else { return }
		}
	}
}

extension MapViewModel {
	
		/// Adding placemark to the map and saving in local storage for later use
		/// - Parameters:
		///   - placemark: SCPlacemark
		///   - completion: call back
	func add(
		placemark: SCPlacemark,
		completion: ((Result<Void, Error>) -> Void)? = nil
	) {
		self.isLoadingPublisher.value = true
	}
}
