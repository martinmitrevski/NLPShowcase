
import UIKit

class LoadingView: UIView {
    
    @IBOutlet fileprivate var activityIndicator: UIActivityIndicatorView!
    
    func show() {
        self.isHidden = false
        activityIndicator.startAnimating()
    }
    
    func hide() {
        self.isHidden = true
        activityIndicator.stopAnimating()
    }
}
