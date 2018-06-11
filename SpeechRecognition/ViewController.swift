//
//  ViewController.swift
//  SpeechRecognition
//
//  Created by Saikumar on 11/06/18.
//  Copyright © 2018 hedgehoglab. All rights reserved.
//


// https://www.appcoda.com/siri-speech-framework/
// https://medium.com/ios-os-x-development/speech-recognition-with-swift-in-ios-10-50d5f4e59c48

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    
    @IBOutlet weak var outPutDataTextView: UITextView!
    @IBOutlet weak var inputVoiceButton: UIButton!
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    
    private var recognizationRequest :SFSpeechAudioBufferRecognitionRequest?
    private var recognizationTask :SFSpeechRecognitionTask?
    private var audioEngine = AVAudioEngine()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        var isButtonEnabled = false

        SFSpeechRecognizer.requestAuthorization { (status) in
            switch status {  //5
            case .authorized:
                isButtonEnabled = true
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }
            
            OperationQueue.main.addOperation() {
                self.inputVoiceButton.isEnabled = isButtonEnabled
            }
        }
        
    }

   
    @IBAction func inPutVoiceButtonAction(_ sender: UIButton) {
        
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognizationRequest?.endAudio()
            inputVoiceButton.isEnabled = false
            inputVoiceButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            inputVoiceButton.setTitle("Stop Recording", for: .normal)
        }
        
    }
    
    func startRecording(){
        if recognizationTask != nil {
            recognizationTask?.cancel()
            recognizationTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print(error.localizedDescription)
        }
        
        
        recognizationRequest = SFSpeechAudioBufferRecognitionRequest()
        
        let inputNode = audioEngine.inputNode
        
        guard let recognizationRequest = recognizationRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognizationRequest.shouldReportPartialResults = true
        
        recognizationTask = speechRecognizer?.recognitionTask(with: recognizationRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.outPutDataTextView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognizationRequest = nil
                self.recognizationTask = nil
                
                self.inputVoiceButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognizationRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        self.outPutDataTextView.text = "Say something, I'm listening!"
    }
    
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            inputVoiceButton.isEnabled = true
        } else {
            inputVoiceButton.isEnabled = false
        }
    }
    

}

