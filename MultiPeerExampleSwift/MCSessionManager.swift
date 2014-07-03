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
}

class MCSessionManager:NSObject, MCSessionDelegate, MCNearbyServiceAdvertiserDelegate, MCNearbyServiceBrowserDelegate{
    
    class var sharedInstance:MCSessionManager {
    struct Static {
            static let instance : MCSessionManager = MCSessionManager()
        }
        return Static.instance
    }
    
    var _peerID:MCPeerID?// = MCPeerID(displayName:UIDevice.currentDevice().name)//NSUUID.UUID().UUIDString)
    let _serviceType = "serviceType2"
    var _session:MCSession?
    
    var _nearbyAdvertiser:MCNearbyServiceAdvertiser?
    var _nearbyBrowser:MCNearbyServiceBrowser?
    
    var _connectingPeers:NSMutableOrderedSet = NSMutableOrderedSet()
    var _peersInRange:NSMutableOrderedSet = NSMutableOrderedSet()
    
    var _delegate:MCSessionManagerDelegate?
    
    init()  {
        super.init()
        
        var notificationCenter = NSNotificationCenter.defaultCenter()
        
        notificationCenter.addObserver(self, selector:"startServices", name: UIApplicationWillEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector:"stopServices", name: UIApplicationDidEnterBackgroundNotification, object: nil)
        
        startServices()
        
    }
    
    func setupSession() {
        
        if !_peerID? {
            _peerID = MCPeerID(displayName: UIDevice.currentDevice().name)
        }
        
        if !_session? {
            _session = MCSession(peer: _peerID?)
            _session!.delegate = self
        }
        
        if !_nearbyBrowser? {
            _nearbyBrowser = MCNearbyServiceBrowser(peer: _peerID, serviceType: _serviceType)
            _nearbyBrowser!.delegate = self
        }
        
        if !_nearbyAdvertiser? {
            _nearbyAdvertiser = MCNearbyServiceAdvertiser(peer: _peerID, discoveryInfo: nil, serviceType: _serviceType)
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
    }
    
    func stopServices() {
        _nearbyAdvertiser?.stopAdvertisingPeer()
        _nearbyBrowser?.stopBrowsingForPeers()
        teardownSession()
    }
    
    //#pragma mark - MCSessionDelegate Methods
    
    func session(session: MCSession!, peer peerID: MCPeerID!, didChangeState state: MCSessionState) {
        
        switch state {
        case .Connected:
            println("\(_peerID?.displayName) is connected to \(peerID.displayName)")
            _connectingPeers.removeObject(peerID)
        case .Connecting:
            println("\(_peerID?.displayName) is connecting to \(peerID.displayName)")
            _connectingPeers.addObject(peerID)
        case .NotConnected:
            println("\(_peerID?.displayName) is not connected to \(peerID.displayName)")
            _connectingPeers.removeObject(peerID)
            _session?.disconnect()
        }
        
        _delegate?.sessionDidChangeState()
        
        println(session.connectedPeers)
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!)  {
        
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        
    }
    
    func session(session: MCSession!,
        didReceiveCertificate certificate: AnyObject[]!,
        fromPeer peerID: MCPeerID!,
        certificateHandler: ((Bool) -> Void)!) {
            certificateHandler(true)
    }
    
    //#pragma mark advertiser delegate methods
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        println("did receive an invitation from \(peerID.displayName)")
        
        
        var shouldAccept = (_peerID?.displayName.localizedCaseInsensitiveCompare(peerID.displayName) == NSComparisonResult.OrderedAscending)
        
        if shouldAccept {
            println("\(_peerID?.displayName) Accepted Invite \(peerID.displayName)")
            invitationHandler(true,_session)
            _connectingPeers.addObject(peerID)
        } else {
            println("\(_peerID?.displayName) declined Invitation \(peerID.displayName)")
            invitationHandler(false,_session)
        }
        
        //invitationHandler(true,_session)

        
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
        
        var shouldInvite = (_peerID?.displayName.localizedCaseInsensitiveCompare(peerID.displayName) == NSComparisonResult.OrderedDescending)
        
        if shouldInvite {
            println("\(_peerID?.displayName) sent invite to \(peerID.displayName)")
            browser.invitePeer(peerID, toSession: _session, withContext: nil, timeout: 10)
        } else {
            println("\(_peerID?.displayName) is not sending an invite to \(peerID.displayName)")
        }
        
        _peersInRange.addObject(peerID)
        _delegate?.sessionDidChangeState()

    }
    
    func browser(browser: MCNearbyServiceBrowser!, lostPeer peerID: MCPeerID!)  {
        println("\(_peerID?.displayName) lost peer \(peerID.displayName)")
        
        _connectingPeers.removeObject(peerID)
        _peersInRange.removeObject(peerID)
        
        _delegate?.sessionDidChangeState()
    }    
}
