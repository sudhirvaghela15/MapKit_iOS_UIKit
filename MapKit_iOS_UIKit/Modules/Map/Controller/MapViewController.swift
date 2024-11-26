//
//  MapViewController.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import UIKit
import MapKit

class MapViewController: BaseViewController<MapViewModel> {
	
	@IBOutlet weak var mapView: MKMapView!
	
	private lazy var searchController = makeSearchController()
	private lazy var addressResultTableViewController = AddressResultTableViewController.get()
	
	private let locationManager = CLLocationManager()
	private var shouldUpdateLocation = true
	
	override func viewDidLoad() {
		super.viewDidLoad()
		 _ = searchController
		self.mapView.delegate = self
		self.setupLocationManager()
		let status = locationManager.authorizationStatus
		debugPrint("Log - \(status.rawValue)")
	}
	
	private func setupLocationManager() {
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
		locationManager.requestWhenInUseAuthorization()
		locationManager.requestLocation()
	}
}

// MARK: - MKMapViewDelegate
extension MapViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKPolylineRenderer(overlay: overlay)
		renderer.strokeColor = UIColor.red.withAlphaComponent(0.65)
		renderer.lineWidth = 4.0
		return renderer
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		guard let annotation = view.annotation else {
			print("view.annotation is nil")
			return
		}
	}
	
	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
		if shouldUpdateLocation, let deviceLocation = userLocation.location {
			shouldUpdateLocation = false
		}
	}
}

extension MapViewController: CLLocationManagerDelegate {
	private func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
		if status != .authorizedWhenInUse {
			manager.requestLocation()
		}
	}
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		if let location = locations.last{
			  let center = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
			  let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
			  self.mapView.setRegion(region, animated: true)
		  }
		mapView.setUserTrackingMode(.follow, animated: true)
	}
	
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		print("manager didFailWithError: \(error.localizedDescription)")
	}
}

// MARK: - Factory Method
extension MapViewController {
	static func get(viewModel: Value) -> UIViewController {
		let storyboard = UIStoryboard(
			name: "Map",
			bundle: Bundle.main
		)
		
		let view = storyboard.instantiate(MapViewController.self) { coder in
			MapViewController(coder: coder, viewModel: viewModel)
		}
		return view
	}
}


//MARK: - UISearchControllerDelegate
extension MapViewController: UISearchControllerDelegate {
	func makeSearchController() -> UISearchController {
			let searchController = UISearchController(
				searchResultsController: addressResultTableViewController)
			searchController.searchResultsUpdater = addressResultTableViewController
			searchController.delegate = self
			
			let searchBar = searchController.searchBar
			searchBar.sizeToFit()
			searchBar.placeholder = "Search"
			searchBar.searchTextField.leftView?.tintColor = UIColor.systemGray
			searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: searchBar.placeholder ?? "", attributes: [.foregroundColor: UIColor.systemGray])
			
			navigationItem.titleView = searchController.searchBar
			
			searchController.hidesNavigationBarDuringPresentation = false
			definesPresentationContext = true
		
			addressResultTableViewController.dataSource = { [unowned self] _ in
				return self.mapView
			}
		
//			addressResultTableViewController.favoritePlacemarks = { _ in
//
//			}
			
			addressResultTableViewController.selectPacemark = { [unowned self] placemark in
				searchController.searchBar.text = nil
				searchController.searchBar.resignFirstResponder()
				viewModel.add(placemark: placemark)
			}
		
			return searchController
		}
}
