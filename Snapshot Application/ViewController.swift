//
//  ViewController.swift
//  Created by Bobo on 29/12/2016.
//

import UIKit

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate, FrameExtractorDelegate {
    func changeBrightnessText(brightnessText: String, bgColour: String) {
        self.brightness.text = brightnessText;
        
        self.shutterButton.backgroundColor = hexStringToUIColor(hex: bgColour);
    }
    
    var frameExtractor: FrameExtractor!
    var imagePicker: UIImagePickerController!
    var currentMode: String = "grid"
    var hidden: Bool = false;
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let position = touch.location(in: view)
            frameExtractor.focus(with: .locked, exposureMode: .autoExpose, at: position, monitorSubjectAreaChange: true)
        }
    }
    
    @IBOutlet weak var topbar: UIImageView!
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var overlayMenu: UIImageView!
    @IBOutlet weak var overlay: UIImageView!
    @IBAction func flipButton(_ sender: UIButton) {
        frameExtractor.flipCamera()
    }
    
    @IBAction func galleryButton(_ sender: UIButton) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        
        
        
        present(imagePicker, animated: true, completion:nil)
        
    }
    
    @IBOutlet weak var brightness: UILabel!
    
    @IBAction func cameraButton(_ sender: Any) {
        UIImageWriteToSavedPhotosAlbum(imageView.image!, nil, nil, nil)
       
        self.overlay.image = UIImage(named: "white.png");
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            if self.currentMode == "grid"{
                self.overlay.image = UIImage(named:"gridoverlaynew.png")
            }
            else if self.currentMode == "portrait"{
                self.overlay.image = UIImage(named:"snapshot portrait.png")
                
            }
            else if self.currentMode == "landscape"{
                self.overlay.image = UIImage(named:"snapshot mount.png")
            }
            
        }
        
       /* if let image = UIImage(named: "image.png"){
            if let data = UIImagePNGRepresentation(image){
                let filename = getDocumentsDirectory().appendingPathComponent("copy.png")
                try? data.write(to:filename)
            }
        }
       */
       //performSegue(withIdentifier: "showPhotoSegue", sender: nil)
       /* imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.showsCameraControls = false;
        

        present(imagePicker, animated: false, completion:nil)
        imagePicker.takePicture()*/
    }
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.topbar.image = UIImage(named:"white.png")
        self.overlay.image = UIImage(named:"gridoverlaynew.png")
        self.overlayMenu.image = UIImage(named:"default menu grid.png")
        frameExtractor = FrameExtractor()
        frameExtractor.delegate = self
        brightness.text = frameExtractor.brightness;
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeLeft.direction = .left
        self.view.addGestureRecognizer(swipeLeft)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeDown.direction = .down
        self.view.addGestureRecognizer(swipeDown)
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleGesture))
        swipeUp.direction = .up
        self.view.addGestureRecognizer(swipeUp)
    }
    
    @IBAction func landdscapeButton_TouchUpInside(_ sender: Any) {
        currentMode = "landscape"
        self.overlay.image = UIImage(named:"snapshot mount.png")
        self.overlayMenu.image = UIImage( named: "mountmenu.png")
    }
    
    @IBAction func gridButton_TouchUpInside(_ sender: Any) {
        currentMode = "grid"
        self.overlay.image = UIImage(named:"gridoverlaynew.png")
        self.overlayMenu.image = UIImage(named:"default menu grid.png")
    }
    
    @IBAction func portraitButton_TouchUpInside(_ sender: Any) {
        currentMode = "portrait"
        self.overlay.image = UIImage(named:"snapshot portrait.png")
        self.overlayMenu.image = UIImage( named: "portraitmenu.png")
    }
    
    
    @objc func handleGesture(gesture: UISwipeGestureRecognizer) -> Void {
        
        if gesture.direction == UISwipeGestureRecognizerDirection.right {
            
            if currentMode == "grid" && !hidden{
                currentMode = "landscape"
                self.overlay.image = UIImage(named:"snapshot mount.png")
                self.overlayMenu.image = UIImage( named: "mountmenu.png")
            }
            else if currentMode == "landscape" && !hidden{
                currentMode = "portrait"
                self.overlay.image = UIImage(named:"snapshot portrait.png")
                self.overlayMenu.image = UIImage( named: "portraitmenu.png")
            }
            else if currentMode == "portrait" && !hidden{
                currentMode = "grid"
                self.overlay.image = UIImage(named:"gridoverlaynew.png")
                self.overlayMenu.image = UIImage(named:"default menu grid.png")
            }}
        
        else if gesture.direction == UISwipeGestureRecognizerDirection.left {
            
            if currentMode == "grid" && !hidden{
                currentMode = "portrait"
                self.overlay.image = UIImage(named:"snapshot portrait.png")
                self.overlayMenu.image = UIImage( named: "portraitmenu.png")
            }
            else if currentMode == "landscape" && !hidden{
                currentMode = "grid"
                self.overlay.image = UIImage(named:"gridoverlaynew.png")
                self.overlayMenu.image = UIImage(named:"default menu grid.png")
            }
            else if currentMode == "portrait" && !hidden{
                currentMode = "landscape"
                self.overlay.image = UIImage(named:"snapshot mount.png")
                self.overlayMenu.image = UIImage( named: "mountmenu.png")
               
                }
        }
        
        
        else if gesture.direction == UISwipeGestureRecognizerDirection.down {
            hidden = true;
            self.overlay.image = UIImage(named:"")
            self.overlayMenu.image = UIImage( named: "")
            }
        
        else if gesture.direction == UISwipeGestureRecognizerDirection.up {
            hidden = false;
            if (currentMode == "grid"){
                self.overlay.image = UIImage(named:"gridoverlaynew.png")
                self.overlayMenu.image = UIImage(named:"default menu grid.png")
            }
            else if (currentMode == "landscape"){
                self.overlay.image = UIImage(named:"snapshot mount.png")
                self.overlayMenu.image = UIImage( named: "mountmenu.png")
            }
            else if (currentMode == "portrait"){
                self.overlay.image = UIImage(named:"snapshot portrait.png")
                self.overlayMenu.image = UIImage( named: "portraitmenu.png")
            }
        }
    }
    
    @IBOutlet weak var shutterButton: UIButton!
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        imagePicker.dismiss(animated: true, completion: nil)
        //imageView.image = info[UIImagePickerControllerOriginalImage] as? UIImage
    }
    
    
    func captured(image: UIImage) {
        imageView.image = image
    }
    
    func hexStringToUIColor (hex:String) -> UIColor {
        var cString:String = hex.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if (cString.hasPrefix("#")) {
            cString.remove(at: cString.startIndex)
        }
        
        if ((cString.count) != 6) {
            return UIColor.gray
        }
        
        var rgbValue:UInt32 = 0
        Scanner(string: cString).scanHexInt32(&rgbValue)
        
        return UIColor(
            red: CGFloat((rgbValue & 0xFF0000) >> 16) / 255.0,
            green: CGFloat((rgbValue & 0x00FF00) >> 8) / 255.0,
            blue: CGFloat(rgbValue & 0x0000FF) / 255.0,
            alpha: CGFloat(1.0)
        )
    }
    
}

