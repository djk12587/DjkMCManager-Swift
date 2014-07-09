//
//  MCSessionManager.swift
//  MultiPeerExampleSwift
//
//  Created by Daniel Koza on 7/2/14.
//  Copyright (c) 2014 Allstate R&D. All rights reserved.
//

import Foundation
import MultipeerConnectivity


/*@class_protocol*/@objc protocol MCSessionManagerDelegate {
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
    
    weak var _delegate:MCSessionManagerDelegate?
    
    var inMesh = false
    
    func setupSession() {
        
        if !_peerID? {
            var timeString:String = "\(NSDate.timeIntervalSinceReferenceDate())"
            _peerID = MCPeerID(displayName:UIDevice.currentDevice().name + " " + timeString)//timeString)
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
        
        dispatch_async(dispatch_get_main_queue(), {
            switch state {
            case .Connected:
                println("\(self._session?.myPeerID.displayName) is connected to \(peerID.displayName)")
                self._connectingPeers.removeObject(peerID)
            case .Connecting:
                println("\(self._session?.myPeerID.displayName) is connecting to \(peerID.displayName)")
                self._connectingPeers.addObject(peerID)
            case .NotConnected:
                println("\(self._session?.myPeerID.displayName) is not connected to \(peerID.displayName)")
                self._connectingPeers.removeObject(peerID)
            }
            
            self._delegate?.sessionDidChangeState()
            println(session.connectedPeers)
            })
    }
    
    func session(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!)  {
        
        dispatch_async(dispatch_get_main_queue(), {
            let message = NSString(data: data, encoding: NSUTF8StringEncoding)
            println("\(self._session?.myPeerID.displayName) didReceiveDataFromPeer:\(peerID.displayName) withMessage:\(message)")
            self._delegate?.sessionManager(session, didReceiveData: data, fromPeer: peerID)
            })
    }
    
    func session(session: MCSession!, didStartReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, withProgress progress: NSProgress!) {
        
        dispatch_async(dispatch_get_main_queue(), {
            println("\(self._session?.myPeerID.displayName) didStartReceivingResourceWithName: \(resourceName) fromPeer:\(peerID.displayName)")
            })
        
        
    }
    
    func session(session: MCSession!, didFinishReceivingResourceWithName resourceName: String!, fromPeer peerID: MCPeerID!, atURL localURL: NSURL!, withError error: NSError!) {
        dispatch_async(dispatch_get_main_queue(), {
            println("\(self._session?.myPeerID.displayName) didFinishReceivingResourceWithName: \(resourceName) fromPeer:\(peerID.displayName)")
            })
    }
    
    func session(session: MCSession!, didReceiveStream stream: NSInputStream!, withName streamName: String!, fromPeer peerID: MCPeerID!) {
        dispatch_async(dispatch_get_main_queue(), {
            println("\(self._session?.myPeerID.displayName) didReceiveStreamWithName: \(streamName) fromPeer:\(peerID.displayName)")
            })
    }
    
    func session(session: MCSession!, didReceiveCertificate certificate: [AnyObject]!, fromPeer peerID: MCPeerID!, certificateHandler: ((Bool) -> Void)!) {
        certificateHandler(true)
    }
    
    func invitePeerToMesh(peerID:MCPeerID) {
        if invitePeerLogic(peerID) {
            _nearbyBrowser?.invitePeer(peerID, toSession: _session?, withContext: nil, timeout: 10)
        }
    }
    
    func invitePeerLogic(peerToInvite:MCPeerID) -> Bool {
        
        var shouldInvite = true
        
        for aPeer:MCPeerID! in _session!.connectedPeers {
            if aPeer.displayName == peerToInvite.displayName {
                println("\(_session?.myPeerID.displayName) is already connected to \(peerToInvite.displayName)")
                shouldInvite = false
            }
        }
        
        if shouldInvite {
            shouldInvite = (_session?.myPeerID.displayName.localizedCaseInsensitiveCompare(peerToInvite.displayName) == NSComparisonResult.OrderedDescending)
        }
        
        if shouldInvite {
            println("\(_session?.myPeerID.displayName) sent invite to \(peerToInvite.displayName)")
        } else {
            println("\(_session?.myPeerID.displayName) is not sending an invite to \(peerToInvite.displayName)")
        }
        
        return shouldInvite
    }
    
    //#pragma mark advertiser delegate methods
    
    func advertiser(advertiser: MCNearbyServiceAdvertiser!, didReceiveInvitationFromPeer peerID: MCPeerID!, withContext context: NSData!, invitationHandler: ((Bool, MCSession!) -> Void)!) {
        
        println("\(_session?.myPeerID.displayName) did receive an invitation from \(peerID.displayName)")
        println("\(_session?.myPeerID.displayName) accepted Invite from \(peerID.displayName)")
        
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
    
    func browser(_browser: MCNearbyServiceBrowser!, foundPeer peerID: MCPeerID!, withDiscoveryInfo info: [NSObject : AnyObject]!) {

        if invitePeerLogic(peerID) {
            _browser.invitePeer(peerID, toSession: _session, withContext: nil, timeout: 10)
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
