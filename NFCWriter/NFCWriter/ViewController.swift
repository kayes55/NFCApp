//
//  ViewController.swift
//  NFCWriter
//
//  Created by Kayes on 2/12/25.
//

import UIKit
import CoreNFC

class ViewController: UIViewController, NFCNDEFReaderSessionDelegate {
    
    var session: NFCNDEFReaderSession?
    var message: String?

    @IBOutlet weak var messageTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }


    @IBAction func sendTagAction(_ sender: UIButton) {
        message = self.messageTextField.text
        session = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        session?.alertMessage = "Hold your iPhone Near to me"
        session?.begin()
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [any NFCNDEFTag]) {
        var str = "\(message)"
        var strIntoUIInt = [UInt8](str.utf8)
        
        if tags.count > 1 {
            let retryInterval = DispatchTimeInterval.milliseconds(500)
            session.alertMessage = "More than 1 tag is detected. Please remove all tags and try again"
            DispatchQueue.main.asyncAfter(deadline: .now() + retryInterval, execute: {
                self.session?.restartPolling()
            })
        }
        
        let tag = tags.first!
        session.connect(to: tag) { (error: Error?) in
            if nil != error {
                session.alertMessage = "Unable to connect to tag"
                session.invalidate()
                return
            }
            
            tag.queryNDEFStatus { (ndefcStatus, capacity, error: Error?) in
                guard error == nil else {
                    session.alertMessage = "Unable to query NDEF status of tag"
                    session.invalidate()
                    return
                }
                
                switch ndefcStatus {
                case .notSupported:
                    session.alertMessage = "Tag is not NDFE complient"
                    session.invalidate()
                case .readOnly:
                    session.alertMessage = "Tag is readonly!"
                    session.invalidate()
                case .readWrite:
                    tag.writeNDEF(.init(records: [.init(format: .nfcWellKnown, type: Data([06]), identifier: Data([0x0C]), payload: Data((strIntoUIInt)))])) { (error: Error?) in
                        if nil != error {
                            session.alertMessage = "write NDFE message fail: \(error)"
                        } else {
                            session.alertMessage = "write NDFE message successful@"
                        }
                        session.invalidate()
                    }
                 @unknown default:
                    session.alertMessage = "Unknown NDFE tag status"
                    session.invalidate()
                }
            }
        }
    }
    
    func readerSessionDidBecomeActive(_ session: NFCNDEFReaderSession) {
        
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        if let readerError = error as? NFCReaderError {
            if (readerError.code != .readerSessionInvalidationErrorFirstNDEFTagRead) && (readerError.code != .readerSessionInvalidationErrorUserCanceled) {
                let alertController = UIAlertController(title: "Session Invalidated!", message: error.localizedDescription, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
            }
        }
    }
}

