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
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        outputTextView.text = ""
        
        let port = 1337
        server = EchoServer(port: port)
        
        connectionLabel.text = "Active Connection: \(server!.connectedSockets.count)"
        
        server?.onStarted = {
            self.outputTextView.text.append("Swift Echo Server Sample\nConnect to \(self.server!.hostname!) \(port)\n")
        }

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

