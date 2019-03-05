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
    
    ckcviewController = ChromaKeyCameraViewController()
    
    switch argMode {
    case "video":
        ckcviewController!.mode = .video
    case "photo":
        ckcviewController!.mode = .photo
    default:
        returnError(message: "invalid mode")
        return
    }
    
    switch argBackgroundMode {
    case "video":
        ckcviewController!.backgroundMode = .video
        ckcviewController!.backgroundVideoURL = argBackgroundVideo
    case "photo":
        ckcviewController!.backgroundMode = .photo
        ckcviewController!.backgroundPhotoURL = argBackgroundPhoto
    default:
        returnError(message: "invalid background mode")
        return
    }
    
    switch argColor {
    case "red":
        ckcviewController!.color = .red
    case "blue":
        ckcviewController!.color = .blue
    case "green":
        ckcviewController!.color = .green
    default:
        returnError(message: "invalid color")
        return
    }
    
    ckcviewController!.threshold = argThreshold.floatValue
    ckcviewController!.smoothing = argSmoothing.floatValue
    
    ckcviewController!.delegate = self
    self.viewController.present(ckcviewController!, animated: true, completion: nil)
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
