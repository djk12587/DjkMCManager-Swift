//
//  MCSessionManager.swift
//  MultiPeerExampleSwift
//
//  Created by Daniel Koza on 7/2/14.
//  Copyright (c) 2014 Allstate R&D. All rights reserved.
//

import Foundation
import MultipeerConnectivity


protocol MCSessionManagerDelegate {
    func sessionDidChangeState()
    func sessionManager(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!)
}

class MCSessionManager:NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate{
    
    class var sharedInstance:MCSessionManager {
    struct Static {
            static let instance : MCSessionManager = MCSessionManager()
        }
        return Static.instance
    }
    
    var _peerID:MCPeerID?
    let _serviceType = "serviceType2"
    var _session:MCSession?
    
    var _nearbyAdvertiser:MCNearbyServiceAdvertiser?
    var _nearbyBrowser:MCNearbyServiceBrowser?
    
    var _connectingPeers:NSMutableOrderedSet = NSMutableOrderedSet()
    var _peersInRange:NSMutableOrderedSet = NSMutableOrderedSet()
    
    var _delegate:MCSessionManagerDelegate?
    
    var inMesh = false
    
    func setupSession() {
        
        if !_peerID? {
            var timeString:String = "\(NSDate.timeIntervalSinceReferenceDate())"
            _peerID = MCPeerID(displayName:UIDevice.currentDevice().name)//timeString)
        }
        
        if !_session? {
            _session = MCSession(peer: _peerID?)
            _session!.delegate = self
        }
        
        if !_nearbyBrowser? {
            _nearbyBrowser = MCNearbyServiceBrowser(peer: _session?.myPeerID, serviceType: _serviceType)
            _nearbyBrowser!.delegate = self
        }
        
        if !_nearbyAdvertiser? {
            _nearbyAdvertiser = MCNearbyServiceAdvertiser(peer: _session?.myPeerID, discoveryInfo: nil, serviceType: _serviceType)
            _nearbyAdvertiser!.delegate = self
        }

        _connectingPeers.removeAllObjects()
        _peersInRange.removeAllObjects()
    }
    
    func teardownSession() {
        _session?.disconnect()
        _connectingPeers.removeAllObjects()
        _peersInRange.removeAllObjects()
    }
    
    func startServices() {
        setupSession()
        _nearbyAdvertiser?.startAdvertisingPeer()
        _nearbyBrowser?.startBrowsingForPeers()
        _delegate?.sessionDidChangeState()
        
        inMesh = true
    }
    
    func stopServices() {
        teardownSession()
        _nearbyAdvertiser?.stopAdvertisingPeer()
        _nearbyBrowser?.stopBrowsingForPeers()
        
        _session = nil
        _peerID = nil
        _nearbyAdvertiser = nil
        _nearbyBrowser = nil
        
        _delegate?.sessionDidChangeState()
        
        inMesh = false
    }
    
    //#pragma mark - MCSessionDelegate Methods
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        
        switch state {
        case .Connected:
            println("\(_session?.myPeerID.displayName) is connected to \(peerID.displayName)")
            _connectingPeers.removeObject(peerID)
        case .Connecting:
            println("\(_session?.myPeerID.displayName) is connecting to \(peerID.displayName)")
            _connectingPeers.addObject(peerID)
        case .NotConnected:
            println("\(_session?.myPeerID.displayName) is not connected to \(peerID.displayName)")
            _connectingPeers.removeObject(peerID)
        }
        
        _delegate?.sessionDidChangeState()
        
        println(session.connectedPeers)
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!)  {
        let message = NSString(data: data, encoding: NSUTF8StringEncoding)
        println("\(_session?.myPeerID.displayName) didReceiveDataFromPeer:\(peerID.displayName) withMessage:\(message)")
        _delegate?.sessionManager(session, didReceiveData: data, fromPeer: peerID)
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        println("\(_session?.myPeerID.displayName) didStartReceivingResourceWithName: \(resourceName) fromPeer:\(peerID.displayName)")
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        println("\(_session?.myPeerID.displayName) didFinishReceivingResourceWithName: \(resourceName) fromPeer:\(peerID.displayName)")
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        println("\(_session?.myPeerID.displayName) didReceiveStreamWithName: \(streamName) fromPeer:\(peerID.displayName)")
    }
    
    func session(session: MCSession!,
        didReceiveCertificate certificate: AnyObject[]!,
        fromPeer peerID: MCPeerID!,
        certificateHandler: ((Bool) -> Void)!) {
            certificateHandler(true)
    }
    
    func invitePeerToMesh(peerID:MCPeerID) {
        _nearbyBrowser?.invitePeer(peerID, toSession: _session?, withContext: nil, timeout: 10)
    }
    
    //#pragma mark advertiser delegate methods
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        println("\(_session?.myPeerID.displayName) did receive an invitation from \(peerID.displayName)")
        
        println("\(_session?.myPeerID.displayName) accepted Invite \(peerID.displayName)")
        invitationHandler(true,_session)
        
        _delegate?.sessionDidChangeState()
    }
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didNotStartAdvertisingPeer error: NSError!) {
        println(error)
    }
    
    //#pragma mark browser delegate methods
    
    func browser(browser: MCNearbyServiceBrowser!,didNotStartBrowsingForPeers error: NSError!) {
        println(error)
    }
    
    func browser(browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: NSDictionary!)  {
        
        var shouldInvite = (_session?.myPeerID.displayName.localizedCaseInsensitiveCompare(peerID.displayName) == NSComparisonResult.OrderedDescending)
        
        if shouldInvite {
            println("\(_session?.myPeerID.displayName) sent invite to \(peerID.displayName)")
            browser.invitePeer(peerID, toSession: _session, withContext: nil, timeout: 10)
        } else {
            println("\(_session?.myPeerID.displayName) is not sending an invite to \(peerID.displayName)")
        }
        
        _peersInRange.addObject(peerID)
        _delegate?.sessionDidChangeState()

    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!)  {
        println("\(_session?.myPeerID.displayName) lost peer \(peerID.displayName)")
        
        _connectingPeers.removeObject(peerID)
        _peersInRange.removeObject(peerID)
        
        _delegate?.sessionDidChangeState()
    }
}
