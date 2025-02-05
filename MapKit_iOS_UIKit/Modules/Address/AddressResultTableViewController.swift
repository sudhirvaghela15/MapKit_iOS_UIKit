//
//  AddressResultTableViewController.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 26/11/24.
//

import UIKit
import MapKit

class AddressResultTableViewController: UITableViewController {
	
	public var dataSource: ((_ vc: AddressResultTableViewController) -> MKMapView)?
	public var favoritePlacemarks: ((_ vc: AddressResultTableViewController) -> [SCPlacemark])?
	public var selectPacemark: ((SCPlacemark) -> Void)?
	public var didReceviceError: ((_ error: Error) -> Void)?

	private var matchingPlacemarks = [SCPlacemark]()
	private var mapView: MKMapView {
		guard let dataSource = dataSource else {
			fatalError("Must have dataSource")
		}
		return dataSource(self)
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		matchingPlacemarks = favoritePlacemarks?(self) ?? []
    }
}

// MARK: - UITableViewDataSource
extension AddressResultTableViewController {
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return matchingPlacemarks.count
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
		let placemark = matchingPlacemarks[indexPath.row]
		cell.textLabel?.text = placemark.name
		cell.detailTextLabel?.text = placemark.title
		return cell
	}
}

// MARK: - UITableViewDelegate
extension AddressResultTableViewController {
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let placemark = matchingPlacemarks[indexPath.row]
		selectPacemark?(placemark)
		dismiss(animated: true, completion: nil)
	}
}

// MARK: - UISearchResultsUpdating
extension AddressResultTableViewController: UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		// https://stackoverflow.com/questions/30790244/uisearchcontroller-show-results-even-when-search-bar-is-empty
		view.isHidden = false
		
		guard let keywords = searchController.searchBar.text else { return }
		
		MapMananger.fetchLocalSearch(with: keywords, region: mapView.region) { [weak self] (status) in
			guard let self = self else { return }
			switch status {
			case .success(let response):
				self.matchingPlacemarks = response.mapItems.map{ SCPlacemark(mkPlacemark: $0.placemark) }
			case .failure(let error):
				didReceviceError?(error)
				self.matchingPlacemarks = self.favoritePlacemarks?(self) ?? []
			}
			self.tableView.reloadData()
		}
	}
}


extension AddressResultTableViewController {
	static func get() -> AddressResultTableViewController {
		guard let vc = UIStoryboard(name: "AddressResult", bundle: nil).instantiateViewController(withIdentifier: AddressResultTableViewController.ClassName) as? AddressResultTableViewController else {
			fatalError("AddressResultTableViewController doesn't exist")
		}
		return vc
	}
}
