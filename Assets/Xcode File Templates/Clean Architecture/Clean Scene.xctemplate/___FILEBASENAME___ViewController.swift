//___FILEHEADER___

import UIKit

class ___VARIABLE_productName:identifier___ViewController: UIViewController, HasDependencies {
    
    // MARK: - Controls


    // MARK: - Scene variables
    
    private lazy var interactor: ___VARIABLE_productName:identifier___BusinessLogic = ___VARIABLE_productName:identifier___Interactor(
        presenter: ___VARIABLE_productName:identifier___Presenter(viewController: self)
    )
    
    private lazy var router: ___VARIABLE_productName:identifier___Routable = ___VARIABLE_productName:identifier___Router(
        viewController: self
    )

    // MARK: - Internal variables

    
    // MARK: - Controller cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        loadData()
    }
}

// MARK: - Events

private extension ___VARIABLE_productName:identifier___ViewController {
    
    func configure() {

    }

    func loadData() {
        interactor.fetch(
            with: ___VARIABLE_productName:identifier___Models.Request()
        )
    }
}

// MARK: - Scene cycle

extension ___VARIABLE_productName:identifier___ViewController: ___VARIABLE_productName:identifier___Displayable {

    func displayFetched(with viewModel: ___VARIABLE_productName:identifier___Models.ViewModel) {
        
    }
}

// MARK: - Interactions

private extension ___VARIABLE_productName:identifier___ViewController {

}

// MARK: - Delegates

extension ___VARIABLE_productName:identifier___ViewController {

}