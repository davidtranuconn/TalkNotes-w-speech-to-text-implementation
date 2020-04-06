//
//  NoteCreateChangeViewController.swift
//  TalkNotes
//
//  Created by David Tran on 2020. 03. 21..
//  Copyright © 2020. David Tran. All rights reserved.
//
 
import UIKit
import Speech
import AVKit

class NoteChangeViewController : UIViewController, UITextViewDelegate, SFSpeechRecognizerDelegate {
    
    @IBOutlet weak var noteTitleTextField: UITextField!
    @IBOutlet weak var noteTextTextView: UITextView!
    @IBOutlet weak var noteDoneButton: UIButton!
    @IBOutlet weak var noteDateLabel: UILabel!
    @IBOutlet weak var noteRecordButton: UIButton!
    
    private let noteCreationTimeStamp : Int64 = Date().toSeconds()
    private(set) var changingNote : SimpleNote?

    var audioEngine = AVAudioEngine()
    var speechRecognizer = SFSpeechRecognizer(locale:  Locale.init(identifier: "en-US"))
    var recognitionRequest : SFSpeechAudioBufferRecognitionRequest?
    var speechRecognitionTask: SFSpeechRecognitionTask?
    
    
    @IBAction func noteTitleChanged(_ sender: UITextField, forEvent event: UIEvent) {
        if self.changingNote != nil {
                noteDoneButton.isEnabled = true
                noteRecordButton.isEnabled = true
            } else {
                if ( sender.text?.isEmpty ?? true ) || ( noteTextTextView.text?.isEmpty ?? true ) {
                    noteDoneButton.isEnabled = false
                    noteRecordButton.isEnabled = false
                } else {
                    noteDoneButton.isEnabled = true
                    noteRecordButton.isEnabled = true
                }
            }
        }
    
    @IBAction func doneButtonClicked(_ sender: UIButton, forEvent event: UIEvent) {
        if self.changingNote != nil {
            changeItem()
        } else {
            addItem()
        }
    }
    
    func setChangingNote(changingNote : SimpleNote) {
        self.changingNote = changingNote
    }
    
    private func addItem() -> Void {
        let note = SimpleNote(
            noteTitle:     noteTitleTextField.text!,
            noteText:      noteTextTextView.text,
            noteTimeStamp: noteCreationTimeStamp)

        NoteStorage.storage.addNote(noteToBeAdded: note)
        
        performSegue(
            withIdentifier: "backToMasterView",
            sender: self)
    }

    private func changeItem() -> Void {
        // get changed note instance
        if let changingNote = self.changingNote {
            // change the note through note storage
            NoteStorage.storage.changeNote(
                noteToBeChanged: SimpleNote(
                    noteId:        changingNote.noteId,
                    noteTitle:     noteTitleTextField.text!,
                    noteText:      noteTextTextView.text,
                    noteTimeStamp: noteCreationTimeStamp)
            )
            // navigate back to list of notes
            performSegue(
                withIdentifier: "backToMasterView",
                sender: self)
        } else {
            let alert = UIAlertController(
                title: "Unexpected error",
                message: "Cannot change the note, unexpected error occurred. Try again later.",
                preferredStyle: .alert)
            
            // add OK action
            alert.addAction(UIAlertAction(title: "OK",
                                          style: .default ) { (_) in self.performSegue(
                                              withIdentifier: "backToMasterView",
                                              sender: self)})
            self.present(alert, animated: true)
        }
    }
    
    func setUpSpeech(){
        self.noteRecordButton.isEnabled = false
        self.speechRecognizer?.delegate = self
        
//        SFSpeechRecognizer.requestAuthorization { (authStatus) in
//
//            _ = false
//            switch authStatus{
//                case .notDetermined:
//                    self.noteRecordButton.isEnabled = false
//                case .denied:
//                    self.noteRecordButton.isEnabled = false
//                    print("User denied access to speech recognition")
//                case .restricted:
//                    self.noteRecordButton.isEnabled = false
//                    print("Speech recognition restricted on this device")
//                case .authorized:
//                    self.noteRecordButton.isEnabled = true
//                    print("Speech recognition not yet authorized")
//                @unknown default: break
//                    //...
//            }
//        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        _ = SFSpeechRecognizer(locale: Locale.init(identifier: "en-US"))
        self.setUpSpeech()
        
        // set text view delegate so that we can react on text change
        noteTextTextView.delegate = self
        
        // check if we are in create mode or in change mode
        if let changingNote = self.changingNote {
            noteDateLabel.text = NoteDateHelper.convertDate(date: Date.init(seconds: noteCreationTimeStamp))
            noteTextTextView.text = changingNote.noteText
            noteTitleTextField.text = changingNote.noteTitle
            noteDoneButton.isEnabled = true
            noteRecordButton.isEnabled = true
        } else {
            noteDateLabel.text = NoteDateHelper.convertDate(date: Date.init(seconds: noteCreationTimeStamp))
        }
        
        // For back button in navigation bar, change text
        let backButton = UIBarButtonItem()
        backButton.title = "Back"
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = backButton
    }

    @IBAction func recordButtonClicked(_ sender: Any) {
        if audioEngine.isRunning{
            self.audioEngine.stop()
            self.recognitionRequest?.endAudio()
            self.noteRecordButton.isEnabled = false
        } else {
            self.noteRecordButton.isEnabled = true
            self.startRecording()
        }
    }
    
    
    func startRecording() {
        if speechRecognitionTask != nil {
        speechRecognitionTask?.cancel()
        speechRecognitionTask = nil
    }
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.record, mode: AVAudioSession.Mode.measurement, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        }catch {
            print("audioSession properties weren't set because of an error.")
        }
        self.recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

        let inputNode = audioEngine.inputNode

        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true

        self.speechRecognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in

            var isFinal = false

            if result != nil {
                self.noteTextTextView.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            if error != nil || isFinal{
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)

                self.recognitionRequest = nil
                self.speechRecognitionTask = nil

                self.noteRecordButton.isEnabled = true
            }
        
        })
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        self.audioEngine.prepare()

        do {
            try self.audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        self.noteTextTextView.text = "Say something, I'm listening!"
    }
    
    //Handle the text changes here
    func textViewDidChange(_ textView: UITextView) {
        if self.changingNote != nil {
            //change
            noteDoneButton.isEnabled = true
        } else {
            //create
            if ( noteTitleTextField.text?.isEmpty ?? true ) || ( textView.text?.isEmpty ?? true ) {
                noteDoneButton.isEnabled = false
            } else {
                noteDoneButton.isEnabled = true
            }
        }
    }

}
