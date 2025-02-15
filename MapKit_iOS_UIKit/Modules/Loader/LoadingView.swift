//
//  ISLoading.swift
//  MVVMDemo
//
//  Created by sudhir on 26/06/22.
//

import UIKit

final class LoadingView: UIView {
    static let tagValue: Int = 1234123

    var isLoading: Bool = false {
        didSet { isLoading ? start() : stop() }
    }

    private let indicator = UIActivityIndicatorView(style: .large)

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialSetup()
		print("IIIII00111")
    }
	
	deinit {
		print("IIIIIDEINIT=00111")
	}

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialSetup() {
        tag = LoadingView.tagValue
        backgroundColor = UIColor.black.withAlphaComponent(0.5)
        indicator.color = .white
        indicator.translatesAutoresizingMaskIntoConstraints = false
        addSubview(indicator)
        indicator.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }

    func start() {
        indicator.startAnimating()
    }

    func stop() {
        indicator.stopAnimating()
    }
}
