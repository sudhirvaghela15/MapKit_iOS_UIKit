//
//  BaseViewModel.swift
//  MapKit_iOS_UIKit
//
//  Created by sudhir on 24/11/24.
//

import Foundation

protocol ViewModel {
	var isLoadingPublisher: BoxBind<Bool> { get }
	var errorPublisher: BoxBind<Error>? { get }
	var title: String? { get set }
}


class BaseViewModel: ViewModel {
	var title: String? = nil
	
	var isLoadingPublisher: BoxBind<Bool> = BoxBind(false)

	var errorPublisher: BoxBind<any Error>? = nil
}
