//
//  SocketServer.swift
//  SwiftSocket
//
//  Created by Jacopo Mangiavacchi on 10/27/16.
//  Copyright © 2016 Jacopo. All rights reserved.
//

import Foundation

class EchoServer {
    
    static let bufferSize = 4096
    
    let port: Int
    fileprivate var internalHostname: String?
    var hostname: String? { get {return internalHostname} }
    
    var listenSocket: Socket? = nil
    var continueRunning = true
    var connectedSockets = [Int32: Socket]()
    let socketLockQueue = DispatchQueue(label: "com.ibm.serverSwift.socketLockQueue")
    
    var onStarted:(()->())?
    var onConnection:(()->())?
    var onDisconnection:(()->())?
    var onMessage:((_ message: String)->())?
    
    init(port: Int) {
        self.port = port
    }
    
    deinit {
        // Close all open sockets...
        for socket in connectedSockets.values {
            socket.close()
        }
        self.listenSocket?.close()
    }
    
    
    func run() {
        
        let queue = DispatchQueue.global(qos: .userInteractive)
        
        queue.async { [unowned self] in  //unowned
            
            do {
                // Create an IPV6 socket...
                self.listenSocket = try Socket.create(family: .inet6)
                
                guard let socket = self.listenSocket else {
                    
                    print("Unable to unwrap socket...")
                    return
                }
                
                try socket.listen(on: self.port)

                self.internalHostname = socket.signature?.hostname
                print("Listening on \(self.hostname) : \(socket.listeningPort)")

                DispatchQueue.main.sync {
                    self.onStarted?()
                }
                
                repeat {
                    let newSocket = try socket.acceptClientConnection()
                    
                    DispatchQueue.main.sync {
                        self.onConnection?()
                    }
                    
                    print("Accepted connection from: \(newSocket.remoteHostname) on port \(newSocket.remotePort)")
                    print("Socket Signature: \(newSocket.signature?.description)")
                    
                    self.addNewConnection(socket: newSocket)
                    
                } while self.continueRunning
                
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error...")
                    return
                }
                
                if self.continueRunning {
                    
                    print("Error reported:\n \(socketError.description)")
                    
                }
            }
        }
    }
    
    func addNewConnection(socket: Socket) {
        
        
        // Add the new socket to the list of connected sockets...
        socketLockQueue.sync { [unowned self, socket] in
            self.connectedSockets[socket.socketfd] = socket
        }
        
        // Get the global concurrent queue...
        let queue = DispatchQueue.global(qos: .default)
        
        // Create the run loop work item and dispatch to the default priority global queue...
        queue.async { [unowned self, socket] in
            
            var shouldKeepRunning = true
            
            var readData = Data(capacity: EchoServer.bufferSize)
            
            do {
                // Write the welcome string...
                try socket.write(from: "Hello from Swift Socket Server.\n")
                
                repeat {
                    let bytesRead = try socket.read(into: &readData)
                    
                    if bytesRead > 0 {
                        guard let response = String(data: readData, encoding: .utf8) else {
                            
                            DispatchQueue.main.sync {
                                self.onDisconnection?()
                            }
                            
                            print("Error decoding response...")
                            readData.count = 0
                            break
                        }

                        DispatchQueue.main.sync {
                            self.onMessage?(response)
                        }
                        
                        print("Server received from connection at \(socket.remoteHostname):\(socket.remotePort): \(response) ")
                        let reply = "Server response: \n\(response)\n"
                        try socket.write(from: reply)
                        
                    }
                    
                    if bytesRead == 0 {
                        
                        shouldKeepRunning = false
                        break
                    }
                    
                    readData.count = 0
                    
                } while shouldKeepRunning
                
                print("Socket: \(socket.remoteHostname):\(socket.remotePort) closed...")
                socket.close()
                
                self.socketLockQueue.sync { [unowned self, socket] in
                    self.connectedSockets[socket.socketfd] = nil
                }
                
            }
            catch let error {
                guard let socketError = error as? Socket.Error else {
                    print("Unexpected error by connection at \(socket.remoteHostname):\(socket.remotePort)...")
                    return
                }
                if self.continueRunning {
                    print("Error reported by connection at \(socket.remoteHostname):\(socket.remotePort):\n \(socketError.description)")
                }
            }
        }
    }
}
