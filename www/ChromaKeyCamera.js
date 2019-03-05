var exec = require('cordova/exec');

function checkArg(arg, def) {
  if(arg) {
    return arg
  }
  if(def) {
    return def
  }
  throw(new Error('missing mandatory argument'))
}

// var mode : OperationMode = .video
// var backgroundMode : BackgroundMode = .video
// var backgroundPhotoURL : String = ""
// var backgroundVideoURL : String = ""
// var color : Color = .blue
// var threshold : Float = 0.4
// var smoothing : Float = 0.1

exports.start = function(arg, success, error) {
  try {
    var mode = checkArg(arg.mode, 'photo')
    var backgroundMode = checkArg(arg.backgroundMode, 'photo')
    var backgroundPhoto = checkArg(arg.backgroundPhoto, backgroundMode == 'video' ? 'not required' : undefined)
    var backgroundVideo = checkArg(arg.backgroundVideo, backgroundMode == 'photo' ? 'not required' : undefined)
    var color = checkArg(arg.color, 'blue')
    var threshold = checkArg(arg.threshold, 0.4)
    var smoothing = checkArg(arg.smoothing, 0.1)
  }
  catch (err) {
    error(err)
    return
  }
  exec(success, error, 'ChromaKeyCamera', 'start', [mode, backgroundMode, 
    backgroundPhoto, backgroundVideo, color, threshold, smoothing])
}
