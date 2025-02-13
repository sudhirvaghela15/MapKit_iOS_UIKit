//
//  MapViewController.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import UIKit
import MapKit
import SwiftUI

class MapViewController: BaseViewController<MapViewModel> {
	
	@IBOutlet weak var mapView: MKMapView! {
		didSet {
			mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMarkerAnnotationView.ClassName)
		}
	}
	@IBOutlet weak var tableView: UITableView!
	
// movableView
	@IBOutlet weak var movableView: UIVisualEffectView!
	@IBOutlet weak var constriantOfMovableViewHeight: NSLayoutConstraint!
	@IBOutlet weak var movableViewTopToMapViewBottom: NSLayoutConstraint!
	@IBOutlet weak var barButtonItemDone: UIBarButtonItem!
	@IBOutlet weak var barButtonItemEdit: UIBarButtonItem!
	@IBOutlet weak var toolbar: UIToolbar!
	
	@IBOutlet weak var segmentedControl: UISegmentedControl! {
		didSet {
			segmentedControl.setTitle("Distance", forSegmentAt: 0)
			segmentedControl.setTitle("Time", forSegmentAt: 1)
		}
	}
	
	// AddressResultTableViewController
	private lazy var searchController = makeSearchController()
	
	private lazy var addressResultTableViewController = AddressResultTableViewController.get()

	//locationManager
	private let locationManager = CLLocationManager()
	
	private var shouldUpdateLocation = true
	
	private let heightOfUnit: CGFloat = 44.0

	private var switchOnConstantOfMovableView: CGFloat {
		return -(mapView.bounds.height - heightOfUnit)
	}
	
	private var switchOffConstantOfMovableView: CGFloat {
		return -heightOfUnit * 2
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		layoutMovableView()
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		_ = searchController
		
		/// delegate setup
		tableView.delegate = self
		tableView.dataSource = self
		mapView.delegate = self
		
		setupLocationManager()
		
		cprint(locationManager.authorizationStatus)
		
		layoutLeftBarButtonItem()
		
		initObservers()

	}
	
	private
	func initObservers() {
		
		viewModel.placemarks.bind { [weak self] placemarks in
			guard let self else { return }
			mapView.removeAnnotations(mapView.annotations)
			let annotations = placemarks.enumerated().map { (arg0) -> SCAnnotation in
				let (offset, element) = arg0
				return SCAnnotation(placemark: element, sorted: offset + 1)
			}
			mapView.addAnnotations(annotations)
			tableView.reloadData()
		}
		
		viewModel.didUpdatePolylines.bind { [weak self] polylines in
			guard let self else { return }
			
			mapView.removeOverlays(mapView.overlays)
			mapView.addOverlays(polylines, level: .aboveRoads)
			if polylines.count > 0 {
				let rect = MapMananger.boundingMapRect(polylines: polylines)
				let verticalInset = mapView.frame.height / 10
				let horizatonInset = mapView.frame.width / 10
				let edgeInsets = UIEdgeInsets(top: verticalInset, left: horizatonInset, bottom: verticalInset + (heightOfUnit * 2), right: horizatonInset)
				mapView.setVisibleMapRect(rect, edgePadding: edgeInsets, animated: false)
			} else {
				mapView.showAnnotations([mapView.userLocation], animated: true)
			}
		}
		
		viewModel.didUpdateUserPlacemark.bind(listener: { [weak self] (newValue, oldValue) in
			guard let self, oldValue != newValue  else { return }
			tableView.reloadSections([SectionType.source.rawValue], with: .automatic)
		})
		
		viewModel.shouldShowTableView.bind(listener: { [weak self] value in
			guard let self else { return }
			(value ? openMovableView : closeMovableView)()
		})
	}
	
	private
	func leftBarButtonItem() -> UIBarButtonItem {
		return tableView.isEditing ? barButtonItemDone : barButtonItemEdit
	}
	
	private
	func setupLocationManager() {
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
		locationManager.requestWhenInUseAuthorization()
		locationManager.requestLocation()
	}
	
	private
	func layoutMovableView() {
		movableView.layer.cornerRadius = 22.0
		movableView.layer.masksToBounds = true
		constriantOfMovableViewHeight.constant = view.frame.height
	}
}

	// MARK: - Movable View's code
extension MapViewController {
	
	@IBAction private
	func tapGestureRecognizerDidPressed(_ sender: UITapGestureRecognizer) {
		viewModel.shouldShowTableView.value = !viewModel.shouldShowTableView.value
	}
	
	@IBAction private
	func panGestureRecognizerDidPressed(_ sender: UIPanGestureRecognizer) {
		let touchPoint = sender.location(in: mapView)
		switch sender.state {
			case .began:
				break
			case .changed:
				movableViewTopToMapViewBottom.constant = -(mapView.bounds.height - touchPoint.y)
			case .ended, .failed, .cancelled:
				magnetTableView()
				break
			default:
				break
		}
	}
	
	@IBAction private
	func leftBarButtonItemDidPressed(_ sender: Any) {
		tableView.setEditing(!tableView.isEditing, animated: true)
		perform(#selector(layoutLeftBarButtonItem), with: nil, afterDelay: 0.25)
	}
	
	@IBAction private
	func segmentedControlValueChanged(_ sender: UISegmentedControl) {
		cprint(sender.selectedSegmentIndex)
		
	}
	
	@objc private
	func layoutLeftBarButtonItem() {
		func frameOfSegmentedControl(frame: CGRect, superframe: CGRect) -> CGRect {
			var newframe = frame
			newframe.size.width = superframe.width/2
			return newframe
		}
		segmentedControl.frame = frameOfSegmentedControl(frame: segmentedControl.frame, superframe: toolbar.frame)
		let container = UIBarButtonItem(customView: segmentedControl)
		let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
		let userTrackingBarButtonItem = MKUserTrackingBarButtonItem(mapView: self.mapView)
		toolbar.setItems(
				[
					leftBarButtonItem(),
					flexibleSpace,
					container,
					flexibleSpace,
					userTrackingBarButtonItem
				],
				animated: false
			)
	}
	
	private
	func openMovableView() {
		UIView.animate(withDuration: 0.25) {
			self.movableViewTopToMapViewBottom.constant = self.switchOnConstantOfMovableView
			self.view.layoutIfNeeded()
		}
	}
	
	private
	func closeMovableView() {
		UIView.animate(withDuration: 0.25) {
			self.movableViewTopToMapViewBottom.constant = self.switchOffConstantOfMovableView
			self.view.layoutIfNeeded()
		}
	}
	
	private
	func magnetTableView() {
		let buffer = self.toolbar.bounds.height // 44
		
		if viewModel.shouldShowTableView.value {
			let shouldHide = (movableViewTopToMapViewBottom.constant > (switchOnConstantOfMovableView + buffer))
			viewModel.shouldShowTableView.value = !shouldHide
		} else {
			let shouldShow = (movableViewTopToMapViewBottom.constant < (switchOffConstantOfMovableView - buffer))
			viewModel.shouldShowTableView.value = shouldShow
		}
	}
}

// MARK: - MKMap View Delegate
extension MapViewController: MKMapViewDelegate {
	
	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
		if shouldUpdateLocation, let deviceLocation = userLocation.location {
			shouldUpdateLocation = false
			viewModel.update(deviece: deviceLocation)
		}
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		guard let annotation = annotation as? SCAnnotation else { return nil }
		let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: MKMarkerAnnotationView.ClassName, for: annotation) as? MKMarkerAnnotationView
		annotationView?.canShowCallout = true
		annotationView?.leftCalloutAccessoryView = UIButton(type: .contactAdd)
		annotationView?.rightCalloutAccessoryView = UIButton(type: .infoLight)
		annotationView?.titleVisibility = .adaptive
		annotationView?.markerTintColor = .red
		annotationView?.glyphTintColor = .white
		annotationView?.displayPriority = .required
		annotationView?.glyphText = "\(annotation.sorted)"
		return annotationView
	}
	
	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		let renderer = MKPolylineRenderer(overlay: overlay)
		renderer.strokeColor = UIColor.red.withAlphaComponent(0.65)
		renderer.lineWidth = 4.0
		return renderer
	}
	
	func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
		guard let annotation = view.annotation,
		let placemark = viewModel.placemark(at: annotation.coordinate) else {
			print("view.annotation is nil")
			return
		}
		
		switch control {
			case let left where left == view.leftCalloutAccessoryView:
			/// favorite placemark logic
				break
			case let right where right == view.rightCalloutAccessoryView:
				let mapItems = [placemark.toMapItem]
				let options = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
				MKMapItem.openMaps(with: mapItems, launchOptions: options)
			default: break
		}
	}
}

// MARK: - CL Location Manager Delegate
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

// MARK: - UISearchControllerDelegate
extension MapViewController: UISearchControllerDelegate {
	
	func makeSearchController() -> UISearchController {
		let searchController = UISearchController(
			searchResultsController: addressResultTableViewController)
		searchController.searchResultsUpdater = addressResultTableViewController
		searchController.delegate = self
		
		let searchBar = searchController.searchBar
		searchBar.sizeToFit()
		searchBar.placeholder = "Search"
		searchBar.searchTextField.leftView?.tintColor = UIColor.label
		searchBar.searchTextField.attributedPlaceholder = NSAttributedString(string: searchBar.placeholder ?? "", attributes: [.foregroundColor: UIColor.label])
//		searchBar.searchTextField.backgroundColor = .systemBrown
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

// MARK: - Table View Delegete and Datasource
extension MapViewController: UITableViewDelegate, UITableViewDataSource {
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return SectionType.allCases.count
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let type = SectionType(rawValue: section) else {
			return 0
		}
		
		switch type {
		case .result:
			return (viewModel.tourModel != nil) ? 1 : 0
		case .source:
			return (viewModel.userPlacemark != nil) ? 1 : 0
		case .destination:
			return viewModel.placemarks.value.count
		}
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(
			withIdentifier: "cell",
			for: indexPath
		)
		
		guard let type = SectionType(rawValue: indexPath.section) else {
			return cell
		}
		
		switch type {
			case .result:
				let cell2 = UITableViewCell(style: .default, reuseIdentifier: "cell2")
				cell2.contentConfiguration = UIHostingConfiguration {
					HStack {
						VStack(alignment: .leading, spacing: 2) {
							let (distance, duration) = viewModel.routeInfo
							
							Text("Estimation Arrival")
								.font(.title3)
								.multilineTextAlignment(.center)
							
							VStack(alignment: .leading) {
								Text(distance ?? "")
									.font(.caption)
								
								Text(duration ?? "")
									.font(.caption)
							}
						}.fontWeight(.bold)
						Spacer()
					}.padding(.horizontal, 16)
					.padding(.vertical, 5)
					.background(
						Color.orange
							.clipShape(RoundedRectangle(cornerRadius: 12))
					)
				}
				return cell2
				
			case .source:
				/// swift ui configureation
				let cell3 = UITableViewCell(style: .default, reuseIdentifier: "cell3")
				let placemark = viewModel.userPlacemark
				cell3.contentConfiguration = UIHostingConfiguration {
					
					HStack {
						VStack(alignment: .leading) {
							
							Text("Source: Current Location")
								.font(.headline)
								.lineLimit(1)
								.multilineTextAlignment(.leading)
							
							Text(placemark?.title ?? "")
								.font(.caption)
								.multilineTextAlignment(.leading)
							
						}
						Spacer()
					}.frame(maxWidth: .infinity)
					.padding(.horizontal, 16)
					.padding(.vertical, 10)
					.background(
						Color.cyan
							.clipShape(
								RoundedRectangle(cornerRadius: 12)
							)
					)
					.foregroundStyle(.black)
				}
				return cell3
				
			case .destination:
				/// ui kit configuaration
				let placemark = viewModel.placemarks.value[indexPath.row]
				cell.textLabel?.text = "\(indexPath.row + 1). " + (placemark.name ?? "")
				cell.detailTextLabel?.text = placemark.title
		}
			
		return cell
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		guard let type = SectionType(rawValue: indexPath.section) else {
			return false
		}
		switch type {
		case .result:
			return false
		case .source:
			return false
		case .destination:
			return true
		}
	}
	
	func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
		return .delete
	}
	
	func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		if editingStyle == .delete {
			viewModel.deletePlacemark(at: indexPath.row)
		}
	}

}

// MARK: - ScrollView Delegate
extension MapViewController: UIScrollViewDelegate {
	func scrollViewDidScroll(_ scrollView: UIScrollView) {
		if (scrollView.contentOffset.y < 0) || (scrollView.contentSize.height <= scrollView.frame.size.height) {
			movableViewTopToMapViewBottom.constant -= scrollView.contentOffset.y 
			cprint(movableViewTopToMapViewBottom.constant)
			scrollView.contentOffset = CGPoint.zero
		}
	}
	
	func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		 magnetTableView()
	}
}

// MARK: - UIGestureRecognizerDelegate
extension MapViewController: UIGestureRecognizerDelegate {
	
	func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
		return !tableView.frame.contains(touch.location(in: movableView))
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
