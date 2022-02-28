
import UIKit
import MapKit

class SelfieDetailViewController: UIViewController {

    @IBOutlet weak var selfieNameField: UITextField!
    @IBOutlet weak var dateCreatedLabel: UILabel!
    @IBOutlet weak var selfieImageView: UIImageView!
    @IBOutlet weak var mapView: MKMapView!
    
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
        
        if let position = selfie.position {
            self.mapView.setCenter(position.location.coordinate, animated: false)
            mapView.isHidden = false
        }
    }
    
    @IBAction func doneButtonTapped(_ sender: UITextField) {
        
        self.selfieNameField.resignFirstResponder()
        
        guard let selfie = selfie else { return }
        
        guard let text = selfieNameField?.text else { return }
        
        selfie.title = text
        
        try? SelfieStore.shared.save(selfie: selfie)
    }
    
    @IBAction func expandMap(_ sender: Any) {
        if let coordinate = self.selfie?.position?.location {
            let options = [
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate.coordinate),
                MKLaunchOptionsMapTypeKey: NSNumber(value: MKMapType.mutedStandard.rawValue)
            ]
            let placemark = MKPlacemark(coordinate: coordinate.coordinate)
            let item = MKMapItem(placemark: placemark)
            
            item.name = selfie?.title
            item.openInMaps(launchOptions: options)
        }
    }
    
    @IBAction func sharedSelfie(_ sender: UIBarButtonItem) {
        guard let image = self.selfie?.image else {
            
            let alert = UIAlertController(title: "Error", message: "Unable to share selfie without an image", preferredStyle: .alert)
            
            let action = UIAlertAction(title: "OK", style: .default, handler: nil)
            
            alert.addAction(action)
            
            self.present(alert, animated: true)
            
            return
        }
        
        let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
        
        self.present(activity, animated: true, completion: nil)
    }
    
}
