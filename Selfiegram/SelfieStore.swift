
import Foundation
import UIKit.UIImage
import CoreLocation

class Selfie: Codable {
    let created: Date
    let id: UUID
    var title = "New Selfie"
    var position: Coordinate?
    var image: UIImage? {
        get {
            return SelfieStore.shared.getImage(id: self.id)
        }
        set {
            try? SelfieStore.shared.setImage(id: self.id, image: newValue)
        }
    }
    
    init(title: String) {
        self.title = title
        self.created = Date()
        self.id = UUID()
    }
    
    struct Coordinate: Codable, Equatable {
        var latitude: Double
        var longitude: Double
        
        var location: CLLocation {
            get {
                return CLLocation(latitude: self.latitude, longitude: self.longitude)
            }
            set {
                self.latitude = newValue.coordinate.latitude
                self.longitude = newValue.coordinate.longitude
            }
        }
        
        init(location: CLLocation) {
            self.latitude = location.coordinate.latitude
            self.longitude = location.coordinate.longitude
        }
    }
}

enum SelfieStoreError: Error {
    case cannotSaveImage(UIImage?)
}

final class SelfieStore {
    static let shared = SelfieStore()
    private var imageCache: [UUID: UIImage] = [:]
    private var documentsFolder: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .allDomainsMask).first!
    }
    
    /// Gets an image by id and caches it in local memory
    /// - parameter id: the id for the selfie whose image you are hoping to get
    /// - returns: the image for the selfie or nil if the image doesn't exist
    func getImage(id:UUID) -> UIImage? {
        // If image is in cache, return it
        if let image = imageCache[id] {
            return image
        }
        
        // Figure out where this image should live
        let imageURL = documentsFolder.appendingPathComponent("\(id.uuidString)-image.jpg")
        
        // Get the image from the file, exit if we fail
        guard let imageData = try? Data(contentsOf: imageURL) else { return nil }
        
        // Get the image from the data, exit if we fail
        guard let image = UIImage(data: imageData) else { return nil }
        
        // Store the loaded image in cache for next time
        imageCache[id] = image
        
        // Return the loaded image
        return image
    }
    
    /// Saves an image to disk
    /// - parameter id: the id of the Selfie you want this image associated with
    /// - parameter image: the image you want saved
    /// - throws: 'SelfieStoreError' if it fails to save to disk
    func setImage(id: UUID, image: UIImage?) throws {
        // Figure out where the file will end up
        let filename = "\(id.uuidString)-image.jpg"
        let destinationUrl = self.documentsFolder.appendingPathComponent(filename)
        
        if let image = image {
            // Attempt to convert the image to jpeg data
            guard let data = image.jpegData(compressionQuality: 0.9) else {
                throw SelfieStoreError.cannotSaveImage(image)
            }
            // Attempt to write the data
            try data.write(to: destinationUrl)
            
        } else {
            // The image is nil, and we will want to remove it
            try FileManager.default.removeItem(at: destinationUrl)
        }
        
        /// Cache this image in memory
        /// If image is nil, this has the effect of removing the entry from the cache dictionary
        imageCache[id] = image
    }
    
    /// Returns a list of Selfie objects loaded from disk
    ///- returns: an array of all selfies previously saved
    ///- throws: 'SelfieStoreError' if it fails to load properly from disk
    func listSelfies() throws -> [Selfie] {
        // Get the list of files in the Documents directory
        let contents = try FileManager.default.contentsOfDirectory(at: self.documentsFolder, includingPropertiesForKeys: nil)
        
        /// Get all the fiels whose path extension is JSON
        /// Load them as data, then decode them from JSON
        return try contents.filter { $0.pathExtension.lowercased() == "json" }
            .map { try Data(contentsOf: $0) }
            .map { try JSONDecoder().decode(Selfie.self, from: $0) }
    }
    
    /// Deletes a Selfie and its corresponding image from disk
    /// This function takes the id passed in and hands it to the other delete function
    /// - parameter selfie: the selfie you want to delete
    /// - throws: 'SelfieStoreError' if it fails to delete Selfie from disk
    func delete(selfie: Selfie) throws {
        try delete(id: selfie.id)
    }
    
    /// Deletes a Selfie and its corresponding image from disk
    /// - parameter id: the id property of the Selfie you want to delete
    /// - throws: 'SelfieStoreError' if it fails to delete Selfie from disk
    func delete(id: UUID) throws {
        
        let selfieDataFileName = "\(id.uuidString).json"
        let imageFileName = "\(id.uuidString)-image.jpg"
        
        let selfieDataUrl = self.documentsFolder.appendingPathComponent(selfieDataFileName)
        let imageUrl = self.documentsFolder.appendingPathComponent(imageFileName)
        
        //Remove both files for the given Selfie, if they exist
        if FileManager.default.fileExists(atPath: selfieDataUrl.path) {
            try FileManager.default.removeItem(at: selfieDataUrl)
        }
        
        if FileManager.default.fileExists(atPath: imageUrl.path) {
            try FileManager.default.removeItem(at: imageUrl)
        }
        
        // Wipe the image from cache, if it is there
        imageCache[id] = nil
    }
    
    /// Attempts to load a Selfie from disk
    /// - parameter id: the id property of the Selfie you want to load
    /// - returns: the Selfie with the matching id, or nil if it doesn't exist
    func load(id: UUID) -> Selfie? {
        let dataFileName = "\(id.uuidString).json"
        let dataUrl = self.documentsFolder.appendingPathComponent(dataFileName)
        
        // Attempt to load the data in this file, convert it to a photo, and return it. Return nil if any steps fail
        if let data = try? Data(contentsOf: dataUrl),
           let selfie = try? JSONDecoder().decode(Selfie.self, from: data) {
            return selfie
        } else {
            return nil
        }
    }
    
    /// Attempts to save a Selfie to disk
    /// - parameter selfie: the selfie to save to disk
    /// - throws: 'SelfieStoreError' if it fails to write the data
    func save(selfie: Selfie) throws {
        let selfieData = try JSONEncoder().encode(selfie)
        let fileName = "\(selfie.id.uuidString).json"
        let destinationUrl = self.documentsFolder.appendingPathComponent(fileName)
        try selfieData.write(to: destinationUrl)
    }
}
