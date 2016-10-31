//
//  ViewController.swift
//  SwiftSocket
//
//  Created by Jacopo Mangiavacchi on 10/27/16.
//  Copyright © 2016 Jacopo. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var outputTextView: UITextView!
    
    var server: EchoServer?
    var connetionString: String { return "Active Connectio: \(server?.connectedSockets.count)" }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let port = 1337
        server = EchoServer(port: port)
        
        connectionLabel.text = connetionString
        //TODO: Get iOS IP address
        outputTextView.text = "Swift Echo Server Sample\nConnect to 127.0.0.1 \(port)\n"
        
        server?.onConnection = {
            self.outputTextView.text.append("-new connection\n")
        }

        server?.onDisconnection = {
            self.outputTextView.text.append("-connection closed\n")
        }

        server?.onMessage = { message in
            self.outputTextView.text.append("-message: \(message)\n")
        }

        
        server?.run()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

