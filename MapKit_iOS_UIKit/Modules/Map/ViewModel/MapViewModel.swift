//
//  MapViewModel.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import Foundation
import MapKit.MKPlacemark

class MapViewModel: BaseViewModel {

	public var didUpdateUserPlacemark: BoxBind<(newValue: SCPlacemark?, oldValue: SCPlacemark?)> = .init((nil, nil))
	
	public var shouldShowTableView: BoxBind<Bool> = .init(false)
	
	public var didUpdatePolylines: BoxBind<[MKPolyline]> = .init([])
	
	public var placemarks: BoxBind<[SCPlacemark]> = .init([])
	
	var result: String? {
		return tourModel?.routeInformation
	}
	
	var routeInfo: (String?, String?) {
		return (tourModel?.distance, tourModel?.time)
	}
	
	private(set) var preferResult: PreferResult = .distance {
		didSet {
			tourModel = tourModel(preferResult: preferResult, in: tourModels)
		}
	}
	
	private(set) var tourModels: [TourModel] = [] {
		didSet {
			tourModel = tourModel(preferResult: preferResult, in: tourModels)
		}
	}
	
	private(set) var tourModel: TourModel? {
		didSet {
			guard let tourModel = tourModel else { return }
			didUpdatePolylines.value = tourModel.polylines
			placemarks.value = tourModel.destinations
		}
	}
	
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
			self.didUpdateUserPlacemark.value = (
				newValue: placemark,
				oldValue: oldValue
			)
			
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
						self.didUpdateUserPlacemark.value = (newValue: placemark, oldValue: oldValue)
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
	
	func deletePlacemark(at index: Int) {
		let placemark = placemarks.value[index]
		_placemarks.removeAll { (_placemark) -> Bool in
			return _placemark == placemark
		}
		tourModels = showResultCalculate(
			statAt: userPlacemark,
			desitinations: _placemarks
		)
	}
	
	func placemark(at coordinate: CLLocationCoordinate2D) -> SCPlacemark? {
		return _placemarks.first { (placemark) -> Bool in
			return placemark.coordinate.latitude == coordinate.latitude &&
				placemark.coordinate.longitude == coordinate.longitude
		}
	}
	
	func tourModel(preferResult: PreferResult, in tourModels: [TourModel]) -> TourModel? {
		switch preferResult {
		case .distance:
			return tourModels.sorted().first
		case .time:
			return tourModels.sorted(by: { (lhs, rhs) -> Bool in
				return lhs.sumOfExpectedTravelTime < rhs.sumOfExpectedTravelTime
			}).first
		}
	}
}

extension MapViewModel {
	
		/// Adding placemark to the map and saving in local storage for later use
		/// - Parameters:
		///   - placemark: SCPlacemark
		///   - completion: call back
	func add(placemark: SCPlacemark, completion: ((Result<Void, Error>) -> Void)? = nil) {
		
		self.isLoadingPublisher.value = true
		
		DataManager.shared.fetchDirections(ofNew: placemark, toOld: _placemarks, current: userPlacemark) { result in
			
			self.isLoadingPublisher.value = false
			
			switch result {
				case let .success(directions):
					
					DataManager.shared.save(directions: directions)
					
					var placemarks = self._placemarks
					
					placemarks.append(placemark)
					
					self._placemarks = placemarks
					
					self.tourModels = self.showResultCalculate(
						statAt: self.userPlacemark,
						desitinations: placemarks
					)
					
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
	
	/// show result calculter
	func showResultCalculate(
		statAt currentPlacemark: SCPlacemark?,
		desitinations: [SCPlacemark]
	) -> [TourModel] {
		
		var tourModels: [TourModel] = []
		
		guard desitinations.count == 1 else {
			/*
			 [1, 2, 3] -> [[1, 2, 3], [1, 3, 2], [2, 3, 1], [2, 1, 3], [3, 1, 2], [3, 2, 1]]
			*/
			let permutations = AlgorithmManager.permutations(desitinations)
			
			/*
			 [ [(1, 2),  (2, 3) ],  [ (1, 3),  (3, 2) ],  [ (2, 3),  (3, 1) ],  [(2, 1),  (1, 3) ] ,  [ (3, 1) , (1, 2) ],  [ (3, 2),  (2, 1) ] ]
			*/
			let tuplesCollection = permutations.map { (placemarks) -> [(SCPlacemark, SCPlacemark)] in
				return placemarks.toTuple()
			}
			
			/// parente loop
			for (index, tuples) in tuplesCollection.enumerated() {
				let tourModel = TourModel()
				tourModels.append(tourModel)
				
				/// nested loop
				for (nestedIndex, tuple) in tuples.enumerated() {
					/// current location to first location
					if nestedIndex == 0, let userPlacemark = currentPlacemark {
						let source = userPlacemark, destination =  tuple.0
						if let directions = DataManager.shared.findDirection(
							source: source,
							destination: destination
						) {
							tourModels[index].directions.append(directions)
						}
					}
					
					/// FIst location to second location
					let source = tuple.0, destination = tuple.1
					if let direction = DataManager.shared.findDirection(source: source, destination: destination) {
						tourModels[index].directions.append(direction)
					}
				}
			}
			return tourModels
		}
		
		///
		/// this blocke excecute when only one destination we have
		///
		if let source = userPlacemark, let destination = desitinations.first {
			if let directions = DataManager.shared.findDirection(source: source, destination: destination) {
				var tourModel = TourModel()
				tourModel.directions.append(directions)
				tourModels.append(tourModel)
			}
		}
		
		return tourModels
	}
}
