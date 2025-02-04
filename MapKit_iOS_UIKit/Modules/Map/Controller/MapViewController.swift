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
	@IBOutlet weak var tableView: UITableView!
	
	// movableView
	@IBOutlet weak var movableView: UIVisualEffectView!
	@IBOutlet weak var constriantOfMovableViewHeight: NSLayoutConstraint!
	@IBOutlet weak var movableViewTopToMapViewBottom: NSLayoutConstraint!
	@IBOutlet weak var barButtonItemDone: UIBarButtonItem!
	@IBOutlet weak var barButtonItemEdit: UIBarButtonItem!
	@IBOutlet weak var toolbar: UIToolbar!
	
	private let heightOfUnit: CGFloat = 44.0
	private var switchOnConstantOfMovableView: CGFloat {
		return -((mapView.bounds.height / 2) - heightOfUnit)
	}
	
	private var switchOffConstantOfMovableView: CGFloat {
		return -heightOfUnit * 2
	}
	
	// AddressResultTableViewController
	private lazy var searchController = makeSearchController()
	private lazy var addressResultTableViewController = AddressResultTableViewController.get()

	//locationManager
	private let locationManager = CLLocationManager()
	private var shouldUpdateLocation = true
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		layoutMovableView()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		 _ = searchController
		self.mapView.delegate = self
		self.setupLocationManager()
		let status = locationManager.authorizationStatus
		layoutLeftBarButtonItem()
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

// MARK: - Movable View's code
extension MapViewController {
	func layoutMovableView() {
		movableView.layer.cornerRadius = 22.0
		movableView.layer.masksToBounds = true
		constriantOfMovableViewHeight.constant = view.frame.height / 2
	}
	
	@IBAction func tapGestureRecognizerDidPressed(_ sender: UITapGestureRecognizer) {
		viewModel.shouldShowTableView.value.toggle()
	}
	
	@IBAction func panGestureRecognizerDidPressed(_ sender: UIPanGestureRecognizer) {
		let touchPoint = sender.location(in: mapView)
		switch sender.state {
		case .began:
			break
		case .changed:
			movableViewTopToMapViewBottom.constant = -(mapView.bounds.height - touchPoint.y)
		case .ended, .failed, .cancelled:
			magnetTableView()
		default:
			break
		}
	}
	
	@IBAction func leftBarButtonItemDidPressed(_ sender: Any) {
		tableView.setEditing(!tableView.isEditing, animated: true)
		perform(#selector(layoutLeftBarButtonItem), with: nil, afterDelay: 0.25)
	}
	
	@objc
	func layoutLeftBarButtonItem() {
		func frameOfSegmentedControl(frame: CGRect, superframe: CGRect) -> CGRect {
			var newframe = frame
			newframe.size.width = superframe.width/2
			return newframe
		}
		
		let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		let userTrackingBarButtonItem = MKUserTrackingBarButtonItem(mapView: self.mapView)
		toolbar.setItems([leftBarButtonItem(), flexibleSpace, flexibleSpace, userTrackingBarButtonItem], animated: false)
	}
	
	private func leftBarButtonItem() -> UIBarButtonItem {
		return tableView.isEditing ? barButtonItemDone : barButtonItemEdit
	}
	
	func  magnetTableView() {
		let buffer = self.toolbar.bounds.height
		
		viewModel.shouldShowTableView.bind(listener: { [weak self] value in
			guard let self else { return }
			if value {
				openMovableView()
			} else {
				closeMovableView()
			}
		})
		
		if viewModel.shouldShowTableView.value {
			let shouldHide = (movableViewTopToMapViewBottom.constant > (switchOnConstantOfMovableView + buffer))
			viewModel.shouldShowTableView.value = !shouldHide
		} else {
			let shouldShow = (movableViewTopToMapViewBottom.constant < (switchOffConstantOfMovableView - buffer))
			viewModel.shouldShowTableView.value = shouldShow
		}
	}
	
	func openMovableView() {
		UIView.animate(withDuration: 0.25) {
			self.movableViewTopToMapViewBottom.constant = self.switchOnConstantOfMovableView
			self.view.layoutIfNeeded()
		}
	}
	
	func closeMovableView() {
		UIView.animate(withDuration: 0.25) {
			self.movableViewTopToMapViewBottom.constant = self.switchOffConstantOfMovableView
			self.view.layoutIfNeeded()
		}
	}
}


extension MapViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		UITableViewCell()
	}

}
