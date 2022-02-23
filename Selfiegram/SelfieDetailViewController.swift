
import UIKit

class SelfieDetailViewController: UIViewController {

    @IBOutlet weak var selfieNameField: UITextField!
    @IBOutlet weak var dateCreatedLabel: UILabel!
    @IBOutlet weak var selfieImageView: UIImageView!
    
    var selfie: Selfie?
    
    let dateFormatter = { () -> DateFormatter in
        let d = DateFormatter()
        d.dateStyle = .short
        d.timeStyle = .short
        return d
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView() {
        guard let selfie = selfie else { return }
        guard let selfieNameField = selfieNameField,
              let dateCreatedLabel = dateCreatedLabel,
              let selfieImageView = selfieImageView
        else { return }
        selfieNameField.text = selfie.title
        dateCreatedLabel.text = dateFormatter.string(from: selfie.created)
        selfieImageView.image = selfie.image
    }
}
