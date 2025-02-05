//
//  Binding.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import Foundation

/*!
 * @discussion  : Generic Class for store value and listern
 * @Generic     : T
 */
class BoxBind<T> {
	
	typealias Listener = (T) -> Void
	
	private var listener: Listener?
	
	var value: T {
		didSet {
			listener?(value)
		}
	}
	
	init(_ value:T) {
		self.value = value
	}
	
	func bind(listener: Listener?) {
		self.listener = listener
	}
	
	func reload() {
		self.listener?(value)
	}
}
