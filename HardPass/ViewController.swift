//
//  ViewController.swift
//  HardPass
//
//  Created by Maxwell on 28/02/23.
//

import Cocoa
import SmartCardSecretKit
import SecretKit
import Combine

class ViewController: NSViewController {
    var store: SmartCard.Store!
    var secretsSink: AnyCancellable!
    var keyManagement: SmartCard.Secret?
    var fileURL: URL!

    @IBOutlet weak var readTextField: NSTextField!
    @IBOutlet weak var writeTextField: NSTextField!
    @IBOutlet weak var decryptButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appending(component: "data.encrypted")
        self.decryptButton.isEnabled = false
        store = SmartCard.Store()
        secretsSink = store.$secrets.sink { [weak self] keys in
            self?.keyManagement = keys.first { key in
                key.name.starts(with: "Key For Key Management (")
            }
            self?.decryptButton.isEnabled = self?.keyManagement != nil
            
            // FIXME: this should let you import the ssh string instead of using the public key from a connected key, so you can encrypt values without the key.
//            let keyPublicKey = OpenSSHKeyWriter().openSSHString(secret: keyManagement!)
            
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    @IBAction func doDecrypt(_ sender: Any) {
        if let keyManagement {
            let decryptedData = try? self.store.decrypt(data: Data(contentsOf: fileURL), with: keyManagement)
            if let decryptedData {
                self.readTextField.stringValue = String(data: decryptedData, encoding: .utf8)!
            } else {
                print("error...")
            }
        }
    }
    
    @IBAction func doSave(_ sender: Any) {
        if let keyManagement {
            let data = self.writeTextField.stringValue.data(using: .utf8)!
            let encrypted = try! self.store.encrypt(data: data, with: keyManagement)
            try! encrypted.write(to: fileURL, options: .atomic)
        }
    }
}

