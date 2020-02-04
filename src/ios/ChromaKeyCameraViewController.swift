//
//  ChromaKeyCameraViewController.swift
//  ChromaKeyCamera
//
//  Created by Jonathan Rauprich on 03.11.18.
//  Copyright © 2018 Jonathan Rauprich. All rights reserved.
//

import UIKit
import ABGPUImage2
import AVFoundation
import AVKit


enum OperationMode {
    case video
    case photo
    case calibrate
}

enum BackgroundMode {
    case video
    case photo
}

enum CameraSounds : UInt32 {
    case Shutter = 1108
    case BeginRecord = 1117
    case EndRecord = 1114
}

protocol ChromaKeyCameraDelegate: AnyObject {
    func error(message:String)
    func success(path:String)
    func calibrationSuccess(threshold:Float,smoothing:Float)
}

class ChromaKeyCameraViewController : UIViewController {
    weak var delegate: ChromaKeyCameraDelegate?
    var renderView : RenderView!
    var camera : Camera!
    var movie : MovieInput!
    var movieOutput : MovieOutput!
    var picture : PictureInput!
    var blend : ChromaKeyBlend!
    var margins : UILayoutGuide!
    
    // photo controls
    var photoButton : UIButton!
    var saveButton : UIButton!
    var redoButton : UIButton!
    
    // video controls
    var startRecordButton : UIButton!
    var rewindAndStartRecordButton: UIButton!
    var stopRecordButton: UIButton!
    var saveVideoButton: UIButton!
    var redoVideoButton: UIButton!
    
    // external configuration
    // set these bevor using
    var mode : OperationMode = .video
    var backgroundMode : BackgroundMode = .video
    var backgroundPhotoURL : String = ""
    var backgroundVideoURL : String = ""
    var color : Color = .blue
    var threshold : Float = 0.4
    var smoothing : Float = 0.1
    
    var photoURL : URL!
    var movieURL : URL!
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.landscapeRight
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
        view.backgroundColor = UIColor.green
        margins = view.layoutMarginsGuide
        
        // init our save urls
        let documentDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        photoURL = URL(string:"photo.jpg", relativeTo:documentDirectory)
        movieURL = URL(string:"movie.mp4", relativeTo:documentDirectory)
        
    }
    
    func clearMovieFile() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: movieURL.path) {
            try? fileManager.removeItem(atPath: movieURL.path)
        }
    }
    
    func clearPhotoFile() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: photoURL.path) {
            try? fileManager.removeItem(atPath: photoURL.path)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        renderView = RenderView()
        renderView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(renderView)
        
        renderView.fillMode = .preserveAspectRatio
        // make render view fullscreen
        renderView.leadingAnchor.constraint(equalTo: margins.leadingAnchor, constant: -20).isActive = true
        renderView.trailingAnchor.constraint(equalTo: margins.trailingAnchor, constant: 20).isActive = true
        renderView.topAnchor.constraint(equalTo: margins.topAnchor, constant: -20).isActive = true
        renderView.bottomAnchor.constraint(equalTo: margins.bottomAnchor, constant: 0).isActive = true
        
        // movie
        // let playMovieURL = URL(string:"ab.mp4", relativeTo:Bundle.main.resourceURL!)
        // let imageUrl = URL(string:"abtest.png", relativeTo:Bundle.main.resourceURL!)

        setupInputs()
        buildPipeLine()
        startPipeLine()
        
        switch mode {
        case .calibrate:
            drawControls()
        case .video:
            drawVideoControls()
        case .photo:
            drawPhotoControls()
        }
        
        // put global close button on top right
        let closeButton = UIButton(frame: CGRect(x: Int(UIScreen.main.bounds.width - 90), y: 40, width: 70, height: 70))
        closeButton.setImage(UIImage(named: "close"), for: .normal)
        closeButton.addTarget(self, action: #selector(closeButtonPressed), for: .touchUpInside)
        
        view.addSubview(closeButton)
    }

    func setupInputs () {
        do {
            switch backgroundMode {
            case .photo:
                let image = UIImage(contentsOfFile: (URL(string: backgroundPhotoURL)?.path)!)
                if(image == nil) {
                    delegate?.error(message: "could not load background image")
                    return
                }
                picture = try PictureInput(image: image!)
            case .video:
                movie = try MovieInput(url: URL(string:backgroundVideoURL)!, playAtActualSpeed: true, loop: true)
            }
            camera = try Camera(sessionPreset:AVCaptureSession.Preset.hd1280x720)
            blend = ChromaKeyBlend()
            blend.colorToReplace = color
            blend.thresholdSensitivity = threshold
            blend.smoothing = smoothing
        }
        catch {
            delegate?.error(message: "Could not start recording \(error)")
        }

    }
    
    func buildPipeLine () {
        camera.addTarget(blend)
        switch backgroundMode {
        case .photo:
            picture.addTarget(blend)
        case .video:
            movie.addTarget(blend)
        }
        blend.addTarget(renderView)
    }
    
    func startPipeLine () {
        camera.startCapture()
        switch backgroundMode {
        case .photo:
            picture.processImage()
        case .video:
            movie.start(atTime: CMTime(seconds: 0.0, preferredTimescale: 1))
        }
    }
    
    func resumePipeLine() {
        camera.startCapture()
        switch backgroundMode {
        case .photo: break
        case .video:
            movie.start()
        }
    }
    
    func pausePipeLine () {
        camera.stopCapture()
        switch backgroundMode {
        case .photo: break
            //picture.processImage()
        case .video:
            movie.pause()        }
    }
    
    @objc func closeButtonPressed(sender:UIButton) {
        delegate?.error(message:"user closed")
    }
    
    func playSound(sound:CameraSounds) {
        // create a sound ID, in this case its the tweet sound.
        let systemSoundID: SystemSoundID = sound.rawValue
        // to play sound
        AudioServicesPlaySystemSound (systemSoundID)
    }

    // VIDEO UI
    func drawVideoControls() {
        startRecordButton = UIButton(frame: CGRect(x: 20, y: Int(UIScreen.main.bounds.height / 2 - 90), width: 70, height: 70))
        startRecordButton.setImage(UIImage(named: "record"), for: .normal)
        startRecordButton.addTarget(self, action: #selector(startRecordButtonPressed), for: .touchUpInside)
        startRecordButton.isHidden = false
        view.addSubview(startRecordButton)
        
        rewindAndStartRecordButton = UIButton(frame: CGRect(x: 20, y: Int(UIScreen.main.bounds.height / 2 + 20), width: 70, height: 70))
        rewindAndStartRecordButton.setImage(UIImage(named: "recordrewind"), for: .normal)
        rewindAndStartRecordButton.addTarget(self, action: #selector(rewindAndStartRecordButtonPressed), for: .touchUpInside)
        rewindAndStartRecordButton.isHidden = false
        view.addSubview(rewindAndStartRecordButton)
        
        stopRecordButton = UIButton(frame: CGRect(x: 20, y: Int(UIScreen.main.bounds.height / 2 - 35), width: 70, height: 70))
        stopRecordButton.setImage(UIImage(named: "recordstop"), for: .normal)
        stopRecordButton.addTarget(self, action: #selector(stopRecordButtonPressed), for: .touchUpInside)
        stopRecordButton.isHidden = true
        view.addSubview(stopRecordButton)
        
        if(backgroundMode == .photo) {
            rewindAndStartRecordButton.isHidden = true
            startRecordButton.frame = stopRecordButton.frame
        }
        
        redoVideoButton = UIButton(frame: CGRect(x: Int(UIScreen.main.bounds.width - 180), y: Int(UIScreen.main.bounds.height - 90), width: 70, height: 70))
        redoVideoButton.setImage(UIImage(named: "redo"), for: .normal)
        redoVideoButton.addTarget(self, action: #selector(redoVideoButtonPressed), for: .touchUpInside)
        redoVideoButton.isHidden = true
        view.addSubview(redoVideoButton)
        
        saveVideoButton = UIButton(frame: CGRect(x: Int(UIScreen.main.bounds.width - 90), y: Int(UIScreen.main.bounds.height - 90), width: 70, height: 70))
        saveVideoButton.setImage(UIImage(named: "accept"), for: .normal)
        saveVideoButton.addTarget(self, action: #selector(saveVidoButtonPressed), for: .touchUpInside)
        saveVideoButton.isHidden = true
        view.addSubview(saveVideoButton)
    }
    
    @objc func redoVideoButtonPressed(sender:UIButton) {
        redoVideoButton.isHidden = true
        saveVideoButton.isHidden = true
        startRecordButton.isHidden = false
        if(backgroundMode == .video) {
            rewindAndStartRecordButton.isHidden = false
        }
        
        resumePipeLine()
    }
    
    @objc func saveVidoButtonPressed(sender:UIButton) {
        delegate?.success(path: self.movieURL.absoluteString)
    }
    
    @objc func rewindAndStartRecordButtonPressed(sender:UIButton) {
        pausePipeLine()
        startPipeLine()
        startRecordButtonPressed(sender:sender)
    }
    
    @objc func startRecordButtonPressed(sender:UIButton) {
        clearMovieFile()
        playSound(sound:.BeginRecord)
        print("starting record")
        do {
            movieOutput = try MovieOutput(URL:movieURL, size:Size(width:1280, height:720), liveVideo:true)
            
            camera.audioEncodingTarget = movieOutput
            blend.addTarget(movieOutput!)
            movieOutput.startRecording()
            
            startRecordButton.isHidden = true
            rewindAndStartRecordButton.isHidden = true
            stopRecordButton.isHidden = false
            
        } catch {
            delegate?.error(message: "Could not start recording \(error)")
        }
    }
    
    @objc func stopRecordButtonPressed(sender:UIButton) {
        playSound(sound:.EndRecord)
        movieOutput?.finishRecording() {
            self.camera.audioEncodingTarget = nil
            self.movieOutput = nil
            self.pausePipeLine()
            
            // whait for atleast a frame
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(75)) {
                let player = AVPlayer(url: self.movieURL)
                
                // Create a new AVPlayerViewController and pass it a reference to the player.
                let controller = AVPlayerViewController()
                controller.player = player
                
                // Modally present the player and call the player's play() method when complete.
                self.present(controller, animated: false)
            }
            
        }
        
        stopRecordButton.isHidden = true
        saveVideoButton.isHidden = false
        redoVideoButton.isHidden = false
    }
    
    // PHOTO UI
    func drawPhotoControls() {
        photoButton = UIButton(frame: CGRect(x: 20, y: Int(UIScreen.main.bounds.height / 2 - 35), width: 70, height: 70))
        photoButton.setImage(UIImage(named: "record"), for: .normal)
        photoButton.addTarget(self, action: #selector(photoButtonPressed), for: .touchUpInside)
        photoButton.isHidden = false
        view.addSubview(photoButton)

        redoButton = UIButton(frame: CGRect(x: Int(UIScreen.main.bounds.width - 180), y: Int(UIScreen.main.bounds.height - 90), width: 70, height: 70))
        redoButton.setImage(UIImage(named: "redo"), for: .normal)
        redoButton.addTarget(self, action: #selector(redoButtonPressed), for: .touchUpInside)
        redoButton.isHidden = true
        view.addSubview(redoButton)

        
        saveButton = UIButton(frame: CGRect(x: Int(UIScreen.main.bounds.width - 90), y: Int(UIScreen.main.bounds.height - 90), width: 70, height: 70))
        saveButton.setImage(UIImage(named: "accept"), for: .normal)
        saveButton.addTarget(self, action: #selector(saveButtonPressed), for: .touchUpInside)
        saveButton.isHidden = true
        view.addSubview(saveButton)
    }
    
    @objc func redoButtonPressed (sender:UIButton) {
        photoButton.isHidden = false
        redoButton.isHidden = true
        saveButton.isHidden = true
        
        resumePipeLine()
    }
    
    @objc func saveButtonPressed (sender:UIButton) {
        delegate?.success(path: photoURL.absoluteString)
    }
    
    @objc func photoButtonPressed (sender:UIButton) {
        clearPhotoFile()
        
        blend.saveNextFrameToURL(photoURL!, format:.jpeg)
        
        // wait atleast a frame
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(75)) {
            self.pausePipeLine()
            self.playSound(sound:.Shutter)
            self.photoButton.isHidden = true
            self.redoButton.isHidden = false
            self.saveButton.isHidden = false
        }

    }
    
    func drawControls() {
        let sliderTreshold = UISlider(frame: CGRect(x: 50, y: 50, width: 800, height: 50))
        sliderTreshold.minimumValue = 0.0
        sliderTreshold.maximumValue = 0.8
        sliderTreshold.value = threshold
        sliderTreshold.addTarget(self, action: #selector(ChromaKeyCameraViewController.sliderTresholdValueChanged), for: .valueChanged)
        view.addSubview(sliderTreshold)
        
        let sliderSmoothing = UISlider(frame: CGRect(x: 50, y: 100, width: 800, height: 50))
        sliderSmoothing.minimumValue = 0.0
        sliderSmoothing.maximumValue = 0.5
        sliderSmoothing.value = smoothing
        sliderSmoothing.addTarget(self, action: #selector(ChromaKeyCameraViewController.sliderSmoothingValueChanged), for: .valueChanged)
        view.addSubview(sliderSmoothing)
    }
    
    @objc func sliderTresholdValueChanged(sender: UISlider) {
        threshold = sender.value
        blend.thresholdSensitivity = threshold
    }
    
    @objc func sliderSmoothingValueChanged(sender: UISlider) {
        smoothing = sender.value
        blend.smoothing = smoothing
    }
}
