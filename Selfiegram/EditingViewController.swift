
import UIKit
import Vision

class EditingViewController: UIViewController {
    
    enum EyebrowType {
        case left, right
    }
    
    enum DetectionResult {
        case error(Error)
        case success([EyebrowPosition])
    }
    
    enum DetectionError: Error {
        case noResults
    }
    
    typealias EyebrowPosition = (type: EyebrowType, position: CGPoint)
    typealias DetectionCompletion = (DetectionResult) -> Void

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var optionsStackView: UIStackView!
    
    var image: UIImage?
    var renderedImage: UIImage?
    var eyebrows: [EyebrowPosition] = []
    var overlays: [Overlay] = []
    
    var currentOverlay: Overlay? = nil {
        didSet {
            guard currentOverlay != nil else { return }
            redrawImage()
        }
    }
    
    var completion: CaptureViewController.CompletionHandler?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        guard let image = image else {
            self.completion?(nil)
            return
        }
        
        self.imageView.image = image
        
        overlays = OverlayManager.shared.availableOverlays()
        
        for overlay in overlays {
            let overlayView = OverlaySelectionView(overlay: overlay) {
                self.currentOverlay = overlay
            }
            
            overlays.append(overlay)
            
            optionsStackView.addArrangedSubview(overlayView)
        }
        
        let addSelfieButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        
        navigationItem.rightBarButtonItem = addSelfieButton
        
        self.detectEyebrows(image: image) { eyebrows in
            self.eyebrows = eyebrows
        }
    }
    
    @objc func done() {
        let imageToReturn = self.renderedImage ?? self.image
        self.completion?(imageToReturn)
    }
    
    func redrawImage() {
        guard let overlay = self.currentOverlay,
              let image = self.image else {
                  return
              }
        
        UIGraphicsBeginImageContext(image.size)
        
        defer {
            UIGraphicsEndImageContext()
        }
        
        image.draw(at: CGPoint.zero)
        
        for eyebrow in self.eyebrows {
            let eyebrowImage: UIImage
            
            switch eyebrow.type {
            case .left:
                eyebrowImage = overlay.leftImage
            case .right:
                eyebrowImage = overlay.rightImage
            }
            
            var position = CGPoint(x: image.size.width - eyebrow.position.x,
                                   y: image.size.height - eyebrow.position.y)
            
            position.x -= eyebrowImage.size.width / 2.0
            position.y -= eyebrowImage.size.height / 2.0
            
            eyebrowImage.draw(at: position)
        }
        
        self.renderedImage = UIGraphicsGetImageFromCurrentImageContext()
        
        self.imageView.image = self.renderedImage
    }
    
    private func locateEyebrowsHandler(_ request: VNRequest, imageSize: CGSize, completion: DetectionCompletion) {
        guard let firstFace = request.results?.first as? VNFaceObservation else {
            completion(.error(DetectionError.noResults))
            return
        }
        
        func averagePosition(for landmark: VNFaceLandmarkRegion2D) -> CGPoint {
            
            let points = landmark.pointsInImage(imageSize: imageSize)
            
            var averagePoint = points.reduce(CGPoint.zero) {
                return CGPoint(x: $0.x + $1.x, y: $0.y + $1.y)
            }
            
            averagePoint.x /= CGFloat(points.count)
            averagePoint.y /= CGFloat(points.count)
            
            return averagePoint
        }
        
        var results: [EyebrowPosition] = []
        
        if let leftEyebrow = firstFace.landmarks?.leftEyebrow {
            let position = averagePosition(for: leftEyebrow)
            results.append( (type: .left, position: position) )
        }
        
        if let rightEyebrow = firstFace.landmarks?.rightEyebrow {
            let position = averagePosition(for: rightEyebrow)
            results.append( (type: .right, position: position) )
        }
        
        completion(.success(results))
    }
    
    func detectFaceLandmarks(image: UIImage, completion: @escaping DetectionCompletion) {
        
        let request = VNDetectFaceLandmarksRequest { [unowned self] request, error in
            
            if let error = error {
                completion(.error(error))
                return
            }
            
            self.locateEyebrowsHandler(request, imageSize: image.size, completion: completion)
        }
        
        let handler = VNImageRequestHandler(cgImage: image.cgImage!, orientation: .leftMirrored, options: [:])
        
        do {
            try handler.perform([request])
        } catch {
            completion(.error(error))
        }
    }
    
    func detectEyebrows(image: UIImage, completion: @escaping ([EyebrowPosition]) -> Void) {
        detectFaceLandmarks(image: image) { result in
            switch result {
            case .error(let error):
                NSLog("Error detecting eyebrows: \(error)")
                completion([])
            case .success(let results):
                completion(results)
            }
        }
    }
}

class OverlaySelectionView: UIImageView {
    let overlay: Overlay
    typealias TapHandler = () -> Void
    let tapHandler: TapHandler
    
    init(overlay: Overlay, tapHandler: @escaping TapHandler) {
        self.overlay = overlay
        self.tapHandler = tapHandler
        
        super.init(image: overlay.previewIcon)
        
        self.isUserInteractionEnabled = true
        
        let tappedMethod = #selector(OverlaySelectionView.tapped(tap:))
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: tappedMethod)
        
        self.addGestureRecognizer(tapRecognizer)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func tapped(tap: UITapGestureRecognizer) {
        self.tapHandler()
    }
}
