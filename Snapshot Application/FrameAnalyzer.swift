
import UIKit
import AVFoundation

protocol FrameExtractorDelegate: class {
    func captured(image: UIImage)
    func changeBrightnessText(brightnessText: String, bgColour: String)
}

class FrameAnalyzer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate {
    
    private var position = AVCaptureDevice.Position.back
    private let quality = AVCaptureSession.Preset.medium
    
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    
    var brightness : String = "JUST RIGHT"
    
    weak var delegate: FrameExtractorDelegate?
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()
            self.captureSession.startRunning()
        }
    }
    
    /* 
    Changes between front and back iOS camera
    */
    public func flipCamera() {
        sessionQueue.async { [unowned self] in
            self.captureSession.beginConfiguration()
            guard let currentCaptureInput = self.captureSession.inputs.first as? AVCaptureInput else { return }
            self.captureSession.removeInput(currentCaptureInput)
            guard let currentCaptureOutput = self.captureSession.outputs.first as? AVCaptureOutput else { return }
            self.captureSession.removeOutput(currentCaptureOutput)
            self.position = self.position == .front ? .back : .front
            self.configureSession()
            self.captureSession.commitConfiguration()
        }
    }
    
    /*
    Sets focus mode and config for current camera session
    
    focusMode: focus mode for AVCaptureDevice
    exposureMode: exposure mode for AVCaptureDevice
    devicePoint: coords for user touch as CGPoint
    */
    public func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
        sessionQueue.async {
            print("focusing")
            let device = self.selectCaptureDevice()
            
            do {
                try device!.lockForConfiguration()
                
                /*
                 Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
                 Call set(Focus/Exposure)Mode() to apply the new point of interest.
                 */
                if (device!.isFocusPointOfInterestSupported) && (device!.isFocusModeSupported(focusMode)) {
                    device!.focusPointOfInterest = devicePoint
                    device!.focusMode = .autoFocus
                }

                device!.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device!.unlockForConfiguration()
            } catch {
                print("Could not lock device for configuration: \(error)")
            }
        }
    }
   
    
    // AVSession config for frame analysis
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    // Request camera access in iOS
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
            
        }
        
    }
    
    
    // Config and start frame analysis
    private func configureSession() {
        guard permissionGranted else { return }
        captureSession.sessionPreset = quality
        
        guard let captureDevice = selectCaptureDevice() else { return }
        
        
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        captureSession.sessionPreset = AVCaptureSession.Preset.photo
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        guard captureSession.canAddOutput(videoOutput) else { return }
        captureSession.addOutput(videoOutput)
        guard let connection = videoOutput.connection(with: AVFoundation.AVMediaType.video) else { return }
        guard connection.isVideoOrientationSupported else { return }
        guard connection.isVideoMirroringSupported else { return }
        connection.videoOrientation = .portrait
        connection.isVideoMirrored = position == .front
        
    }
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        return AVCaptureDevice.devices().filter {
            ($0 as AnyObject).hasMediaType(AVMediaType.video) &&
            ($0 as AnyObject).position == position
        }.first as? AVCaptureDevice
    }
    
    // Buffer to UIImage conversion
    private func imageFromSampleBuffer(sampleBuffer: CMSampleBuffer) -> UIImage? {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
        let ciImage = CIImage(cvPixelBuffer: imageBuffer)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
  
    
    // Brightness analysis via output from frame buffer
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let uiImage = imageFromSampleBuffer(sampleBuffer: sampleBuffer) else { return }
        
        DispatchQueue.main.async { [unowned self] in
            self.delegate?.captured(image: uiImage)
            
            
            let inputImage = uiImage
            let contextgrey = CIContext(options: nil)
            
            let currentFilter = CIFilter(name: "CIPhotoEffectNoir")
            currentFilter!.setValue(CIImage(image: inputImage), forKey: kCIInputImageKey)
            let output = currentFilter!.outputImage
            let cgimg = contextgrey.createCGImage(output!,from: output!.extent)
            let processedImage = UIImage(cgImage: cgimg!)
            let greyimage = processedImage
            
            let dsimage = self.imageWithImage(image: greyimage, scaledToSize: CGSize(width: 20, height:30));
            let cgimage = dsimage.cgImage
            let size = dsimage.size
            let dataSize = size.width * size.height * 4
            var pixelData = [UInt8](repeating: 0, count: Int(dataSize))
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let context = CGContext(data: &pixelData,
                                    width: Int(size.width),
                                    height: Int(size.height),
                                    bitsPerComponent: 8,
                                    bytesPerRow: 4 * Int(size.width),
                                    space: colorSpace,
                                    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
            let cgImage = cgimage
            context?.draw(cgImage!, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
            
            var blackcount = 0;
            var whitecount = 0;
            for i in 0..<600 {
                if ((pixelData[i*4]) < 5){
                    blackcount = blackcount+1
                }
                else if ((pixelData[i*4]) > 250){
                    whitecount = whitecount+1
                }
            }
            
            if (blackcount - whitecount > 25){
                self.delegate?.changeBrightnessText(brightnessText: "TOO DARK", bgColour: "");
                print("TOO DARK")
            }
            else if (blackcount - whitecount < -5){
                self.delegate?.changeBrightnessText(brightnessText: "TOO BRIGHT", bgColour: "");
                print("TOO BRIGHT")
            }
            else{
                self.delegate?.changeBrightnessText(brightnessText: "", bgColour: "#98FB98");
                print("JUST RIGHT")
            }
            print(pixelData)
            
            
            print("Got a frame!")
        }
    }
    
    /* 
    Scales size of frames for performance
    image: UIImage to resize
    newSize: CGSize(width, height)
    returns: UIImage
    */
    
    func imageWithImage(image:UIImage, scaledToSize newSize:CGSize) -> UIImage{
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0);
        image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
        let newImage:UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    

    
    
}
