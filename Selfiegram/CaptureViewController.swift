
import UIKit
import AVKit

class CaptureViewController: UIViewController {
    
    @IBOutlet weak var cameraPreview: PreviewView!
    
    typealias CompletionHandler = (UIImage?) -> Void
    var completion: CompletionHandler?

    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    
    var currentOrientation: AVCaptureVideoOrientation {
        let orientationMap: [UIDeviceOrientation: AVCaptureVideoOrientation]
        orientationMap = [
            .portrait: .portrait,
            .landscapeLeft: .landscapeLeft,
            .landscapeRight: .landscapeRight,
            .portraitUpsideDown: .portraitUpsideDown
        ]
        
        let currentOrientation = UIDevice.current.orientation
        
        let videoOrientation = orientationMap[currentOrientation, default: .portrait]
        
        return videoOrientation
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func close(_ sender: UIBarButtonItem) {
    }
}

class PreviewView: UIView {
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func setSession(_ session: AVCaptureSession) {
        guard self.previewLayer == nil else {
            NSLog("Warning: \(self.description) attempted to set its" +
                  " preview layer more than once. This is not allowed.")
            return
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.layer.addSublayer(previewLayer)
        
        self.previewLayer = previewLayer
        
        self.setNeedsLayout()
    }
    
    override func layoutSubviews() {
        previewLayer?.frame = self.bounds
    }
    
    func setCameraOrientation(_ orientation: AVCaptureVideoOrientation) {
        previewLayer?.connection?.videoOrientation = orientation
    }
}
