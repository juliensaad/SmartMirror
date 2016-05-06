//
//  SpeechRecognitionManager.swift
//  SmartMirror
//
//  Created by Julien Saad on 2016-05-06.
//  Copyright © 2016 Julien Saad. All rights reserved.
//

protocol SpeechRecognizerDelegate: class {
    func speechRecognizerDidAskForAction(action: Action)
}

enum Action: String {
    case Open = "Open"
    case Close = "Close"
}

class SpeechRecognizer: NSObject, OEEventsObserverDelegate {
    
    weak var delegate: SpeechRecognizerDelegate?
    
    lazy var eventsObserver: OEEventsObserver = self.initEventsObserver()
    
    func startRecognition() {
        let generator = OELanguageModelGenerator()
        let words = [Action.Open.rawValue, Action.Close.rawValue]
        
        let wordGroupName = "SpeechRecognition"
        
        let err = generator.generateLanguageModelFromArray(words, withFilesNamed: wordGroupName, forAcousticModelAtPath: OEAcousticModel.pathToModel("AcousticModelEnglish"))
        
        if (err == nil) {
            let lmPath = generator.pathToSuccessfullyGeneratedLanguageModelWithRequestedName(wordGroupName)
            let dicPath = generator.pathToSuccessfullyGeneratedDictionaryWithRequestedName(wordGroupName)
            
            try! OEPocketsphinxController.sharedInstance().setActive(true)
            OEPocketsphinxController.sharedInstance().startListeningWithLanguageModelAtPath(lmPath, dictionaryAtPath: dicPath, acousticModelAtPath: OEAcousticModel.pathToModel("AcousticModelEnglish"), languageModelIsJSGF: false)
            
            
            eventsObserver.delegate = self
            
        }
    }
    
    private func initEventsObserver() -> OEEventsObserver {
        return OEEventsObserver()
    }
    
    // MARK: OEEventsObserverDelegate
    
    func pocketsphinxDidReceiveHypothesis(hypothesis: String!, recognitionScore: String!, utteranceID: String!) {
        print("Received speech \(hypothesis) \(recognitionScore) \(utteranceID)")
        
        if hypothesis.containsString(Action.Open.rawValue) {
            delegate?.speechRecognizerDidAskForAction(.Open)
        }
        else if hypothesis.containsString(Action.Close.rawValue) {
            delegate?.speechRecognizerDidAskForAction(.Close)
        }
    }
    
    func pocketsphinxDidStartListening() {
        print("STARTED LISTENING");
    }
    
    func pocketsphinxDidStopListening() {
        print("Stopped listening");
    }
    
}
