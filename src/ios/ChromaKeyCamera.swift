@objc(ChromaKeyCamera) class ChromaKeyCamera : CDVPlugin, ChromaKeyCameraDelegate {
    
  var latestCall : CDVInvokedUrlCommand?
  var ckcviewController : ChromaKeyCameraViewController?

  @objc(start:) func start(_ command: CDVInvokedUrlCommand) {
    latestCall = command

    // argument order
    //[mode, backgroundMode, backgroundPhoto, backgroundVideo, color, threshold, smoothing]
    let argMode = command.arguments[0] as? String ?? ""
    let argBackgroundMode = command.arguments[1] as? String ?? ""
    let argBackgroundPhoto = command.arguments[2] as? String ?? ""
    let argBackgroundVideo = command.arguments[3] as? String ?? ""
    let argColor = command.arguments[4] as? String ?? ""
    let argThreshold = command.arguments[5] as? NSNumber ?? 0.0
    let argSmoothing = command.arguments[6] as? NSNumber ?? 0.0
    
    
    UIDevice.current.setValue(UIInterfaceOrientation.landscapeRight.rawValue, forKey: "orientation")
    
    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
    
        self.ckcviewController = ChromaKeyCameraViewController()
        
        self.ckcviewController!.modalPresentationStyle = .fullScreen
    
        switch argMode {
        case "video":
            self.ckcviewController!.mode = .video
        case "photo":
            self.ckcviewController!.mode = .photo
        default:
            self.returnError(message: "invalid mode")
            return
        }
    
        switch argBackgroundMode {
        case "video":
            self.ckcviewController!.backgroundMode = .video
            self.ckcviewController!.backgroundVideoURL = argBackgroundVideo
        case "photo":
            self.ckcviewController!.backgroundMode = .photo
            self.ckcviewController!.backgroundPhotoURL = argBackgroundPhoto
        default:
            self.returnError(message: "invalid background mode")
            return
        }
    
        switch argColor {
        case "red":
            self.ckcviewController!.color = .red
        case "blue":
            self.ckcviewController!.color = .blue
        case "green":
            self.ckcviewController!.color = .green
        default:
            self.returnError(message: "invalid color")
            return
        }
    
        self.ckcviewController!.threshold = argThreshold.floatValue
        self.ckcviewController!.smoothing = argSmoothing.floatValue
    
        self.ckcviewController!.delegate = self

        self.viewController.present(self.ckcviewController!, animated: true, completion: nil)
    }

  }
    
  func returnError(message: String) {
    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAs: message)
    self.commandDelegate!.send(pluginResult, callbackId: latestCall!.callbackId)
  }
    
  func error(message: String) {
    self.ckcviewController?.dismiss(animated: true, completion: nil)
    self.ckcviewController = nil
    returnError(message: message)
  }
  
  func success(path: String) {
    self.ckcviewController?.dismiss(animated: true, completion: nil)
    self.ckcviewController = nil
    let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAs: path)
    self.commandDelegate!.send(pluginResult, callbackId: latestCall!.callbackId)
  }
  
  func calibrationSuccess(threshold: Float, smoothing: Float) {
    self.ckcviewController?.dismiss(animated: true, completion: nil)
    self.ckcviewController = nil
  }
  
}
