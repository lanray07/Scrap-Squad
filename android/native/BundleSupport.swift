import Foundation
// Android supplies content bytes through JNI. This fallback only satisfies the
// existing SwiftPM convenience loader, which is not called by the Android app.
extension Bundle { static var module: Bundle { .main } }
