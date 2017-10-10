//
//  MessagesViewController.swift
//  MinionTranslator MessagesExtension
//
//  Created by Wictor Kihlbaum on 2017-10-02.
//  Copyright © 2017 Wictor Kihlbaum. All rights reserved.
//

import UIKit
import Messages

class MessagesViewController: MSMessagesAppViewController, UITextFieldDelegate {
    
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func onTextFieldTouch() {
        if self.presentationStyle == .compact {
            self.requestPresentationStyle(.expanded)
        }
    }
    
    @IBAction func onSendMessage() {
        if self.messageTextField.hasText {
            self.dismissKeyboard()
            self.showCompactView()
            self.callAPI(message: self.getMessage())
            self.clearMessageTextField()
        }
    }
    
    @IBAction func onKeyboardSend() {
        self.onSendMessage()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.hasText
    }
    
    func showCompactView() {
        if self.presentationStyle == .expanded {
            self.requestPresentationStyle(.compact)
        }
    }
    
    func callAPI(message: String) {
        // Replace white spaces with %20 (Needed for a valid/accepted URL)
        let escapedMessage: String = message.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!
        let url = URL(string: "https://api.funtranslations.com/translate/minion.json?text=\(escapedMessage)")
        let session = URLSession.shared
        
        // Call API
        if let usableUrl = url {
            let task = session.dataTask(with: usableUrl, completionHandler: { (data, response, error) in
                if let responseData = data {
                    self.handleAPIResponse(data: responseData)
                }
            })
            // task.setValue("<insert API key>", forKey: "X-FunTranslations-Api-Secret")
            task.resume()
        }
    }
    
    func handleAPIResponse(data: Data) {
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
            let content = json["contents"] as! [String: Any]
            let originalMessage: String = content["text"] as! String
            let translatedMessage: String = content["translated"] as! String
            let message: MSMessage = self.createMessage(originalMessage: originalMessage, translatedMessage: translatedMessage)
            self.sendMessage(message: message)
        }
        catch {
            print("JSON Serialization error occurred")
        }
    }
    
    func sendMessage(message: MSMessage) {
        self.activeConversation?.insert(message)
    }
    
    func createMessage(originalMessage: String, translatedMessage: String) -> MSMessage {
        // Create message layout
        let layout: MSMessageTemplateLayout = MSMessageTemplateLayout()
        layout.caption = "🍌 \(translatedMessage)"
        layout.subcaption = "🇬🇧 \(originalMessage)"
        
        // Create message
        let message: MSMessage = MSMessage()
        message.layout = layout
        
        return message
    }
    
    func dismissKeyboard() {
        if self.messageTextField.isFirstResponder {
            self.resignFirstResponder()
        }
    }
    
    func getMessage() -> String {
        return self.messageTextField.text!
    }
    
    func clearMessageTextField() {
        self.messageTextField.text?.removeAll()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return self.presentationStyle == .expanded
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.sendButton.isEnabled = true
    }
    
    @IBAction func goBackFromAboutView(_ segue: UIStoryboardSegue) {}
    
    // MARK: - Conversation Handling
    
    override func didTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        if presentationStyle == .expanded {
            self.messageTextField.becomeFirstResponder()
        }
    }

}
