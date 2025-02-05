//
//  UIStoryboard+Extension.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import UIKit

public extension UIStoryboard {
	/// view controller instantiate
	/// - Returns: UIViewController
	func instantiate<T: UIViewController>() -> T? {
		return self.instantiateViewController(withIdentifier: String(describing: T.self)) as? T
	}
	
	func instantiate<T: UIViewController>(_ type: T.Type, creator: ((NSCoder) -> T?)? = nil) -> T {
		return self.instantiateViewController(identifier: String(describing: T.self), creator: creator)
	}
}
