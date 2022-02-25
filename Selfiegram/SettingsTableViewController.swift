
import UIKit

enum SettingsKey: String {
    case saveLocation
}

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var locationSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        locationSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
    }
    
    @IBAction func locationSwitchToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(locationSwitch.isOn, forKey: SettingsKey.saveLocation.rawValue)
    }
}
