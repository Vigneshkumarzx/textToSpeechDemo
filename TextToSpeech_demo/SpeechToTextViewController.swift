//
//  SpeechToTextViewController.swift
//  TextToSpeech_demo
//
//  Created by vignesh kumar c on 05/06/23.
//

import UIKit
import Speech

class SpeechToTextViewController: UIViewController, SFSpeechRecognizerDelegate  {
    
    let audioEngine = AVAudioEngine()
    let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    let request = SFSpeechAudioBufferRecognitionRequest()
    var recognitionTask: SFSpeechRecognitionTask?
    var isRecording = false
    
    
    @IBOutlet weak var colorView: UIView!
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var startAndStopBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        speechRecognizer?.delegate = self
        self.requestSpeechAuthorization()
    }
    
    enum Color: String {
        case Red, Orange, Yellow, Green, Blue, Purple, Black, Gray
        
        var create: UIColor {
            switch self {
            case .Red:
                return UIColor.red
            case .Orange:
                return UIColor.orange
            case .Yellow:
                return UIColor.yellow
            case .Green:
                return UIColor.green
            case .Blue:
                return UIColor.blue
            case .Purple:
                return UIColor.purple
            case .Black:
                return UIColor.black
            case .Gray:
                return UIColor.gray
            }
        }
    }
    
    @IBAction func startAndStopTapped(_ sender: Any) {
        if isRecording == true {
            cancelRecording()
            isRecording = false
            startAndStopBtn.backgroundColor = UIColor.gray
        } else {
            self.recordAndRecognizeSpeech()
            isRecording = true
            startAndStopBtn.backgroundColor = UIColor.red
        }
    }
    
    func cancelRecording() {
        recognitionTask?.finish()
        recognitionTask = nil
        
        // stop audio
        request.endAudio()
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
    }
    
    func recordAndRecognizeSpeech() {
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            self.sendAlert(title: "Speech Recognizer Error", message: "There has been an audio engine error.")
            return print(error)
        }
        guard let myRecognizer = SFSpeechRecognizer() else {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not supported for your current locale.")
            return
        }
        if !myRecognizer.isAvailable {
            self.sendAlert(title: "Speech Recognizer Error", message: "Speech recognition is not currently available. Check back at a later time.")
           
            return
        }
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                
                let bestString = result.bestTranscription.formattedString
                var lastString: String = ""
                for segment in result.bestTranscription.segments {
                    let indexTo = bestString.index(bestString.startIndex, offsetBy: segment.substringRange.location)
                    lastString = String(bestString[indexTo...])
                }
                self.checkForColorsSaid(resultString: lastString)
                self.textLabel.text = lastString
            } else if let error = error {
                self.sendAlert(title: "Speech Recognizer Error", message: "There has been a speech recognition error.")
                print(error)
            }
        })
    }
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            OperationQueue.main.addOperation {
                switch authStatus {
                case .authorized:
                    self.startAndStopBtn.isEnabled = true
                case .denied:
                    self.startAndStopBtn.isEnabled = false
                    self.textLabel.text = "User denied access to speech recognition"
                case .restricted:
                    self.startAndStopBtn.isEnabled = false
                    self.textLabel.text = "Speech recognition restricted on this device"
                case .notDetermined:
                    self.startAndStopBtn.isEnabled = false
                    self.textLabel.text = "Speech recognition not yet authorized"
                @unknown default:
                    return
                }
            }
        }
    }
    
    func checkForColorsSaid(resultString: String) {
        guard let color = Color(rawValue: resultString) else { return }
        colorView.backgroundColor = color.create
        self.textLabel.text = resultString
    }
    
    func sendAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}

