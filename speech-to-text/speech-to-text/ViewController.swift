//
//  ViewController.swift
//  speech-to-text
//
//  Created by Christopher Webb-Orenstein on 11/19/16.
//  Copyright © 2016 Christopher Webb-Orenstein. All rights reserved.
//

import UIKit
import Speech

class ViewController: UIViewController, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var transcriptionTextView: UITextView!
    @IBOutlet weak var transcribeButton: UIButton!
    
    
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
    private let audio = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        transcribeButton.isEnabled = false
        speechRecognizer?.delegate = self
        
        SFSpeechRecognizer.requestAuthorization { authorization in
            
            var isEnabled = false
            
            switch authorization {
            case .authorized:
                isEnabled = true
            case .denied:
                isEnabled = false
            case .restricted:
                isEnabled = false
            case .notDetermined:
                isEnabled = false
            }
            
            OperationQueue.main.addOperation {
                self.transcribeButton.isEnabled = isEnabled
            }
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func transcribeTapped(_ sender: AnyObject) {
        if audio.isRunning {
            audio.stop()
            recognitionRequest?.endAudio()
            transcribeButton.isEnabled = false
            transcribeButton.setTitle("Transcribe", for: .normal)
        } else {
            start()
            transcribeButton.setTitle("Stop", for: .normal)
        }
    }
    
    func start() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(AVAudioSessionCategoryRecord)
            try session.setMode(AVAudioSessionModeMeasurement)
            try session.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("Session properties weren't set. Error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audio.inputNode else {
            fatalError("No input for audio engine")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create SFSpeechAudioBufferRecognitionRequest")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            if result != nil {
                self.transcriptionTextView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audio.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.transcribeButton.isEnabled = true
            }
        })
        
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audio.prepare()
        
        do {
            try audio.start()
        } catch {
            print("Audio couldn't start because of an error.")
        }
        
        transcriptionTextView.text = "Ready to transcribe speech to text."
        
    }
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            transcribeButton.isEnabled = true
        } else {
            transcribeButton.isEnabled = false
        }
    }
}

