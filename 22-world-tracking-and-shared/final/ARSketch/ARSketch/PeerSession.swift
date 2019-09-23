/*
 * Copyright (c) 2013-2014 Kim Pedersen
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import MultipeerConnectivity

class PeerSession: NSObject, MCAdvertiserAssistantDelegate {
  private let peerID = MCPeerID(displayName: UIDevice.current.name)
  static let serviceType = "arsketchsession"
  private(set) var mcSession: MCSession!
  private var advertiserAssistant: MCAdvertiserAssistant!
  private let receivedDataHandler: (Data, MCPeerID) -> Void
  
  init(receivedDataHandler: @escaping (Data, MCPeerID) -> Void) {
    self.receivedDataHandler = receivedDataHandler
    super.init()
    
    mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
    mcSession.delegate = self
    
    advertiserAssistant = MCAdvertiserAssistant(serviceType: PeerSession.serviceType, discoveryInfo: nil, session: self.mcSession)
    advertiserAssistant.delegate = self
    advertiserAssistant.start()
  }
  
  func sendToAllPeers(_ data: Data) {
    do {
      try mcSession.send(data,
                         toPeers: mcSession.connectedPeers,
                         with: .reliable)
    } catch {
      print("""
        error sending data to peers:
        \(error.localizedDescription)
        """)
    }
  }
  
  var connectedPeers: [MCPeerID] {
    return mcSession.connectedPeers
  }
}

extension PeerSession: MCSessionDelegate {
  func session(_ session: MCSession,
               peer peerID: MCPeerID,
               didChange state: MCSessionState) {
  }
  
  func session(_ session: MCSession,
               didReceive data: Data,
               fromPeer peerID: MCPeerID) {
    receivedDataHandler(data, peerID)
  }
  
  func session(_ session: MCSession,
               didReceive stream: InputStream,
               withName streamName: String,
               fromPeer peerID: MCPeerID) {
    fatalError("This service does not send/receive streams.")
  }
  
  func session(_ session: MCSession,
               didStartReceivingResourceWithName resourceName: String,
               fromPeer peerID: MCPeerID,
               with progress: Progress) {
    fatalError("This service does not send/receive resources.")
  }
  
  func session(_ session: MCSession,
               didFinishReceivingResourceWithName resourceName: String,
               fromPeer peerID: MCPeerID,
               at localURL: URL?,
               withError error: Error?) {
    fatalError("This service does not send/receive resources.")
  }
}
