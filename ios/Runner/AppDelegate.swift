import AppTrackingTransparency
import AVFoundation
import Flutter
import UIKit

final class NativeSoundPlayer {
  private var cache: [String: AVAudioPlayer] = [:]
  private var volume: Float = 1.0

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult, controller: FlutterViewController) {
    switch call.method {
    case "setVolume":
      if let value = call.arguments as? Double {
        volume = Float(value)
        cache.values.forEach { $0.volume = volume }
      }
      result(nil)
    case "play":
      guard let args = call.arguments as? [String: Any],
            let asset = args["asset"] as? String else {
        result(FlutterMethodNotImplemented)
        return
      }
      if let vol = args["volume"] as? Double {
        volume = Float(vol)
      }
      play(asset: asset, controller: controller)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func play(asset: String, controller: FlutterViewController) {
    if let player = cache[asset] {
      player.volume = volume
      player.currentTime = 0
      player.play()
      return
    }

    let key = controller.lookupKey(forAsset: asset)
    guard let path = Bundle.main.path(forResource: key, ofType: nil) else {
      return
    }
    let url = URL(fileURLWithPath: path)

    do {
      try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
      let player = try AVAudioPlayer(contentsOf: url)
      player.volume = volume
      player.prepareToPlay()
      cache[asset] = player
      player.play()
    } catch {
      // Ignore missing or corrupt assets.
    }
  }
}

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let soundPlayer = NativeSoundPlayer()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      FlutterMethodChannel(
        name: "com.alnlabs.pulimeka/tracking",
        binaryMessenger: controller.binaryMessenger
      ).setMethodCallHandler { call, result in
        switch call.method {
        case "getStatus":
          if #available(iOS 14, *) {
            result(ATTrackingManager.trackingAuthorizationStatus.rawValue)
          } else {
            result(3)
          }
        case "request":
          if #available(iOS 14, *) {
            ATTrackingManager.requestTrackingAuthorization { status in
              result(status.rawValue)
            }
          } else {
            result(3)
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }

      FlutterMethodChannel(
        name: "com.alnlabs.pulimeka/sounds",
        binaryMessenger: controller.binaryMessenger
      ).setMethodCallHandler { [weak self] call, result in
        guard let self else {
          result(nil)
          return
        }
        self.soundPlayer.handle(call, result: result, controller: controller)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
