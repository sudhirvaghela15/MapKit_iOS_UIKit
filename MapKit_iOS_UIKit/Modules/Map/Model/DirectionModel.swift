import MapKit

struct DirectionModel: Codable, Equatable {
	let source: SCPlacemark
	let destination: SCPlacemark
	let distance: CLLocationDistance
	let expectedTravelTime: TimeInterval
	let polylineData: Data
	var polyline: MKPolyline {
		let buf = UnsafeMutableBufferPointer<MKMapPoint>.allocate(capacity: polylineData.count / MemoryLayout<MKMapPoint>.size)
		let _ = polylineData.copyBytes(to: buf)
		return MKPolyline(points: buf.baseAddress!, count: buf.count)
	}
	
	var sourcePlacemark: MKPlacemark {
		get {
			let postalAddress = source.toPostalAddress
			return MKPlacemark(coordinate: source.coordinate, postalAddress: postalAddress)
		}
	}
	
	var destinationPlacemark: MKPlacemark {
		get {
			let postalAddress = destination.toPostalAddress
			return MKPlacemark(coordinate: destination.coordinate, postalAddress: postalAddress)
		}
	}
	
	init(source: MKPlacemark, destination: MKPlacemark, routes: [MKRoute]) {
		self.source = SCPlacemark(mkPlacemark: source)
		self.destination = SCPlacemark(mkPlacemark: destination)
		self.distance = routes.first!.distance
		self.expectedTravelTime = routes.first!.expectedTravelTime
		let polyline = routes.first!.polyline
		self.polylineData = Data(buffer: UnsafeBufferPointer(start: polyline.points(), count: polyline.pointCount))
	}
	
	init(source: SCPlacemark, destination: SCPlacemark, routes: [MKRoute]) {
		self.source = source
		self.destination = destination
		self.distance = routes.first!.distance
		self.expectedTravelTime = routes.first!.expectedTravelTime
		let polyline = routes.first!.polyline
		self.polylineData = Data(buffer: UnsafeBufferPointer(start: polyline.points(), count: polyline.pointCount))
	}
	
}
