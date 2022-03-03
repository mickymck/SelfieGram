

import UIKit
import CoreLocation
import simd

class SelfieListTableViewController: UITableViewController {
    
    var selfies: [Selfie] = []
    var lastLocation: CLLocation?
    let locationManager = CLLocationManager()
    
    // The formatter for creating the "1 minute ago"-style label
    let timeIntervalFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .spellOut
        formatter.maximumUnitCount = 1
        return formatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = "Selfies"
        // Load the list of selfies from the SelfieStore
        do {
            // Get the list of photos, sorted by date
            selfies = try SelfieStore.shared.listSelfies().sorted(by: { $0.created > $1.created
            })
        } catch let error {
            showError(message: "Failed to load selfies: \(error.localizedDescription)")
        }
        
        let addSelfieButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewSelfie))
        
        navigationItem.rightBarButtonItem = addSelfieButton
        
        self.locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tableView.reloadData()
    }
    
    func showError(message: String) {
        // Create an alert controller with the message we received
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        // Create an action for the alert
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        // Show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    func newSelfieTaken(image: UIImage) {
        let newSelfie = Selfie(title: "New Selfie")
        newSelfie.image = image
        
        if let location = self.lastLocation {
            newSelfie.position = Selfie.Coordinate(location: location)
        }
        
        do {
            try SelfieStore.shared.save(selfie: newSelfie)
        } catch let error {
            showError(message: "Can't save photo: \(error)")
            return
        }
        selfies.insert(newSelfie, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
    
    @objc func createNewSelfie() {
        lastLocation = nil
        
        let shouldGetLocation = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
        
        if shouldGetLocation {
            switch CLLocationManager.authorizationStatus() {
            case .denied, .restricted:
                return
            case .notDetermined:
                locationManager.requestWhenInUseAuthorization()
            default:
                break
            }
            locationManager.requestLocation()
        }
        
        guard let navigation = self.storyboard?
                .instantiateViewController(withIdentifier: "CaptureScene") as? UINavigationController,
              let capture = navigation.viewControllers.first as? CaptureViewController
        else { fatalError("Failed to create capture view controller") }
        
        capture.completion = { (image: UIImage?) in
            if let image = image {
                self.newSelfieTaken(image: image)
            }
            self.dismiss(animated: true, completion: nil)
        }
        
        self.present(navigation, animated: true, completion: nil)
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            if let indexPath = tableView.indexPathForSelectedRow {
                let selfie = selfies[indexPath.row]
                if let controller = segue.destination as? SelfieDetailViewController {
                    controller.selfie = selfie
                }
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selfies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let selfie = selfies[indexPath.row]
        cell.textLabel?.text = selfie.title
        if let interval = timeIntervalFormatter.string(from: selfie.created, to: Date()) {
            cell.detailTextLabel?.text = "\(interval) ago"
        } else {
            cell.detailTextLabel?.text = nil
        }
        cell.imageView?.image = selfie.image
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.performSegue(withIdentifier: "showDetail", sender: nil)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let share = UITableViewRowAction(style: .normal, title: "Share") { action, indexPath in
            guard let image = self.selfies[indexPath.row].image else {
                self.showError(message: "Unable to share selfie without an image")
                return
            }
            let activity = UIActivityViewController(activityItems: [image], applicationActivities: nil)
            self.present(activity, animated: true, completion: nil)
        }
        share.backgroundColor = self.view.tintColor
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { action, indexPath in
            let selfieToRemove = self.selfies[indexPath.row]
            do {
                try SelfieStore.shared.delete(selfie: selfieToRemove)
                self.selfies.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {
                self.showError(message: "Failed to delete \(selfieToRemove.title)")
            }
        }
        return [delete,share]
    }
}

extension SelfieListTableViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.lastLocation = locations.last
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        showError(message: error.localizedDescription)
    }
}
