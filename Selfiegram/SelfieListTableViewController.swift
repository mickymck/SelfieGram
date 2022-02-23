//
//  SelfieListTableViewController.swift
//  Selfiegram
//
//  Created by Micky McKeon on 2/23/22.
//

import UIKit

class SelfieListTableViewController: UITableViewController {
    
    var selfies: [Selfie] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        // Load the list of selfies from the SelfieStore
        do {
            // Get the list of photos, sorted by date
            selfies = try SelfieStore.shared.listSelfies().sorted(by: { $0.created > $1.created
            })
        } catch let error {
            showError(message: "Failed to load selfies: \(error.localizedDescription)")
        }
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

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return selfies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let selfie = selfies[indexPath.row]
        cell.textLabel?.text = selfie.title
        return cell
    }
}
