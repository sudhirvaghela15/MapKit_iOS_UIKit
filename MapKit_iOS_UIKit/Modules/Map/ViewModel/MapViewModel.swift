//
//  MapViewModel.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import Foundation
import MapKit.MKPlacemark

class MapViewModel: BaseViewModel {
	public var didUpdateUserPlacemark: BoxBind<(newValue: SCPlacemark, oldValue: SCPlacemark?)>?
	
	public var shouldShowTableView: BoxBind<Bool> = .init(false)
	
	private var _placemarks: [SCPlacemark] = []
	
	private var deviceLocation: CLLocation? {
		didSet {
			guard let deviceLocation = deviceLocation else { return }
			self.isLoadingPublisher.value = true
			MapMananger.reverseCoordinate(deviceLocation.coordinate) {[weak self] result in
				guard let self else { return }
				switch result {
					case let .success(placemarks):
						guard let mkPlacemark = placemarks.first else { return }
						let placemark = SCPlacemark(mkPlacemark: mkPlacemark)
						self.userPlacemark = placemark
					case let .failure(error):
						self.errorPublisher?.value = error
				}
				self.isLoadingPublisher.value = false
			}
		}
	}
	
	private(set) var userPlacemark: SCPlacemark? {
		didSet {
			guard let placemark = userPlacemark else { return }
			self.didUpdateUserPlacemark?.value = (newValue: placemark, oldValue: oldValue)
			
			guard placemark != oldValue else { return }
			
			if _placemarks.count == 0 {
				// add mock placemark
			} else {
				let tempPlacemarks = _placemarks
				_placemarks = []
				add(placemarks: tempPlacemarks) { [weak self] (result) in
					guard let self = self else { return }
					switch result {
					case .failure(let error):
						self.errorPublisher?.value = error
					case .success:
						self.didUpdateUserPlacemark?.value = (
							newValue: placemark,
							oldValue: oldValue
						)
					}
				}
			}
		}
	}
	
	init(title: String) {
		super.init()
		self.title = title
	}
	
	func update(deviece location: CLLocation) {
		self.deviceLocation = location
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
		DataManager.shared.fetchDirections(ofNew: placemark, toOld: _placemarks, current: userPlacemark) { result in
			self.isLoadingPublisher.value = false
		
			switch result {
				case let .success(directions):
					DataManager.shared.save(directions: directions)
					var placemarks = self._placemarks
					placemarks.append(placemark)
					self._placemarks = placemarks
					completion?(.success(Void()))
				case let .failure( error):
					completion?(.failure(error))
			}
		}
	}
	
	func add(placemarks: [SCPlacemark], completion: ((Result<Void, Error>) -> Void)?) {
		DispatchQueue.global().async {
			let queue = OperationQueue()
			queue.maxConcurrentOperationCount = 1
			
			placemarks.forEach({ (placemark) in
				let blockOperation = BlockOperation(block: {
					let semaphore = DispatchSemaphore(value: 0)
					DispatchQueue.main.async {
						self.add(placemark: placemark, completion: { (result) in
							switch result {
							case .failure(let error):
								completion?(.failure(error))
								semaphore.signal()
								queue.cancelAllOperations()
							case .success:
								semaphore.signal()
							}
						})
					}
					semaphore.wait()
				})
				queue.addOperation(blockOperation)
			})
			
			queue.waitUntilAllOperationsAreFinished()
			DispatchQueue.main.async {
				completion?(.success(Void()))
			}
		}
	}
}
