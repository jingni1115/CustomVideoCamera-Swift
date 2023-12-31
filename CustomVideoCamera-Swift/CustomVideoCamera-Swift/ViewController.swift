//
//  ViewController.swift
//  CustomVideoCamera-Swift
//
//  Created by 김지은 on 2023/11/14.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet weak var imgGallery: UIImageView!
    @IBOutlet weak var vScreen: UIView!
    
    var captureSession = AVCaptureSession()
    var videoPreviewLayer = AVCaptureVideoPreviewLayer()
    var movieFileOutput = AVCaptureMovieFileOutput()
    var audioFileOutput = AVCaptureAudioDataOutput()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setCamera()
    }
    
    func setCamera() {
        self.captureSession = AVCaptureSession()
        self.captureSession.beginConfiguration()
        
        // AVCaptureSession 설정
        guard let videoDevice = AVCaptureDevice.default(for: AVMediaType.video),
              let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio),
              let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
              let audioInput = try? AVCaptureDeviceInput(device: audioDevice) else {
            // Error handling
            return
        }
        
        self.movieFileOutput = AVCaptureMovieFileOutput()
        self.audioFileOutput = AVCaptureAudioDataOutput()
        
        self.captureSession.addInput(videoInput)
        self.captureSession.addInput(audioInput)
        self.captureSession.sessionPreset = .hd1280x720
        self.captureSession.addOutput(self.movieFileOutput)
        self.captureSession.addOutput(self.audioFileOutput)
        self.captureSession.commitConfiguration()
        
        self.setPreviewCamera()
    }
    
    func setPreviewCamera() {
        //preview
        self.videoPreviewLayer = AVCaptureVideoPreviewLayer(session: self.captureSession)
        DispatchQueue.main.async {
            self.videoPreviewLayer.frame = self.vScreen.bounds
        }
        self.videoPreviewLayer.videoGravity = .resizeAspectFill
        DispatchQueue.main.async {
            self.vScreen.layer.addSublayer(self.videoPreviewLayer)
        }
        DispatchQueue.global(qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
    func startRecording() {
        let outputFileName = NSUUID().uuidString
        let outputFilePath = (NSTemporaryDirectory() as NSString).appendingPathComponent(outputFileName).appending(".mov")
        let outputURL = URL(fileURLWithPath: outputFilePath)
        
        movieFileOutput.startRecording(to: outputURL, recordingDelegate: self)
    }
    
    func stopRecording() {
        movieFileOutput.stopRecording()
    }
    
    private func camera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: AVMediaType.video, position: .unspecified)
        
        let devices = discoverySession.devices
        return devices.filter { $0.position == position }.first
    }
    
    private func switchCamera(captureSession: AVCaptureSession?) {
        captureSession?.beginConfiguration()
        let currentInput = captureSession?.inputs.first as? AVCaptureDeviceInput
        captureSession?.removeInput(currentInput!)
        
        let newCameraDevice = currentInput?.device.position == .back ? camera(with: .front) : camera(with: .back)
        let newVideoInput = try? AVCaptureDeviceInput(device: newCameraDevice!)
        captureSession?.addInput(newVideoInput!)
        captureSession?.commitConfiguration()
    }
    
    @IBAction func lightButtonPressed(_ sender: UIButton) {
        //카메라 디바이스 가져오기
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        //플래시를 지원한다면
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                
                //현재 off상태이면 on시키기
                if device.torchMode == .off {
                    device.torchMode = .on
                    //플래시 버튼 이미지 변경
                    sender.setImage(UIImage.init(systemName: "lightbulb"), for: .normal)
                }
                //현재 on상태이면 off시키기
                else {
                    device.torchMode = .off
                    //플래시 버튼 이미지 변경
                    sender.setImage(UIImage.init(systemName: "lightbulb.slash"), for: .normal)
                }
                
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    @IBAction func recordButtonPressed(_ sender: UIButton) {
        if !movieFileOutput.isRecording {
            startRecording()
            sender.setTitle("Recording", for: .normal)
        } else {
            stopRecording()
            sender.setTitle("Record", for: .normal)
        }
    }
    
    @IBAction func screenTransitionButtonPressed(_ sender: Any) {
        switchCamera(captureSession: captureSession)
    }
}
extension ViewController: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // 비디오 촬영이 시작됐을 때의 동작
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording video: \(error.localizedDescription)")
        } else {
            // 휴대폰 갤러리에 저장하고 싶다면
            UISaveVideoAtPathToSavedPhotosAlbum(outputFileURL.path, nil, nil, nil)
        }
    }
}
