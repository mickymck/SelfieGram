//
//  SelfieListTableViewController.swift
//  Selfiegram
//
//  Created by Micky McKeon on 2/23/22.
//

import UIKit

class SelfieListTableViewController: UITableViewController {
    
    var selfies: [Selfie] = []
    
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
    
    @objc func createNewSelfie() {
        let imagePicker = UIImagePickerController()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            if UIImagePickerController.isCameraDeviceAvailable(.front) {
                imagePicker.cameraDevice = .front
            }
        } else {
            imagePicker.sourceType = .photoLibrary
        }
        imagePicker.delegate = self
        self.present(imagePicker, animated: true, completion: nil)
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
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        // If this is a deletion, delete the Selfie
        if editingStyle == .delete {
            let selfieToRemove = selfies[indexPath.row]
            do {
                try SelfieStore.shared.delete(selfie: selfieToRemove)
                selfies.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .fade)
            } catch {
                let title = selfieToRemove.title
                showError(message: "Failed to delete \(title)")
            }
        }
    }
}

extension SelfieListTableViewController:
    UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage ?? info[UIImagePickerController.InfoKey.originalImage] as? UIImage else {
            let message = "Couldn't get an image from the image picker"
            showError(message: message)
            return
        }
        self.newSelfieTaken(image: image)
        self.dismiss(animated: true, completion: nil)
    }
    
    func newSelfieTaken(image: UIImage) {
        let newSelfie = Selfie(title: "New Selfie")
        newSelfie.image = image
        do {
            try SelfieStore.shared.save(selfie: newSelfie)
        } catch let error {
            showError(message: "Can't save photo: \(error)")
            return
        }
        selfies.insert(newSelfie, at: 0)
        tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
    }
}
