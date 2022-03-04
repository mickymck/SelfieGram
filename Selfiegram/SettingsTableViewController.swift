
import UIKit
import UserNotifications

enum SettingsKey: String {
    case saveLocation
}

class SettingsTableViewController: UITableViewController {
    
    @IBOutlet weak var locationSwitch: UISwitch!
    @IBOutlet weak var reminderSwitch: UISwitch!
    
    private let notificationId = "SelfiegramReminder"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationSwitch.isOn = UserDefaults.standard.bool(forKey: SettingsKey.saveLocation.rawValue)
        updateReminderSwitch()
    }
    
    func addNotificationRequest() {
        let current = UNUserNotificationCenter.current()
        current.removeAllPendingNotificationRequests()
        
        let content = UNMutableNotificationContent()
        content.title = NSString.localizedUserNotificationString(forKey: "Take your selfie now. NOW.", arguments: nil)
        
        var components = DateComponents()
        components.setValue(10, for: Calendar.Component.hour)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        
//        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: self.notificationId, content: content, trigger: trigger)
        
        current.add(request) { error in
            self.updateReminderSwitch()
        }
    }
    
    func updateReminderSwitch() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized:
                UNUserNotificationCenter.current()
                    .getPendingNotificationRequests { requests in
                        let active = requests
                            .filter { $0.identifier == self.notificationId }
                            .count > 0
                        self.updateReminderUI(enabled: true, active: active)
                    }
            case .denied:
                self.updateReminderUI(enabled: false, active: false)
            default:
                self.updateReminderUI(enabled: true, active: false)
            }
        }
    }
    
    func updateReminderUI(enabled: Bool, active: Bool) {
        OperationQueue.main.addOperation {
            self.reminderSwitch.isEnabled = enabled
            self.reminderSwitch.isOn = active
        }
    }
    
    @IBAction func locationSwitchToggled(_ sender: UISwitch) {
        UserDefaults.standard.set(locationSwitch.isOn, forKey: SettingsKey.saveLocation.rawValue)
    }
    @IBAction func reminderSwitchToggled(_ sender: UISwitch) {
        let current = UNUserNotificationCenter.current()
        
        switch reminderSwitch.isOn {
        case true:
            let notificationOptions: UNAuthorizationOptions = [.alert]
            current.requestAuthorization(options: notificationOptions) { granted, error in
                if granted {
                    self.addNotificationRequest()
                }
                self.updateReminderSwitch()
            }
        case false:
            current.removeAllPendingNotificationRequests()
        }
    }
}
