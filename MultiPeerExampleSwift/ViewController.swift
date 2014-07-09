//
//  ViewController.swift
//  MultiPeerExampleSwift
//
//  Created by Daniel Koza on 7/1/14.
//  Copyright (c) 2014 Allstate R&D. All rights reserved.
//

import UIKit
import MultipeerConnectivity


class ViewController: UIViewController, MCSessionManagerDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var singleton = MCSessionManager.sharedInstance
    
    @IBOutlet var connectionTableView: UITableView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        singleton._delegate = self
        
        connectionTableView.contentInset = UIEdgeInsetsMake(20.0, 0.0, 0.0, 0.0)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        connectionTableView.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func connectionList(sender: AnyObject) {
        //println("Peer List \(_session?.connectedPeers)")
        println("connecting Peers: \(singleton._connectingPeers)")
        println("peers In Range: \(singleton._peersInRange)")
        println("connected Peers: \(singleton._session?.connectedPeers)")
    }
    
    @IBAction func leaveMeshAction(sender: AnyObject) {
        if singleton.inMesh {
            singleton.stopServices()
        }
    }
    
    @IBAction func joinMeshAction(sender: AnyObject) {
        if !singleton.inMesh {
            singleton.startServices()
        }
    }
    
    func sessionDidChangeState()  {
       // dispatch_async(dispatch_get_main_queue(), {
            self.connectionTableView.reloadData()
         //   })
    }
    
    func sessionManager(session: MCSession!, didReceiveData data: NSData!, fromPeer peerID: MCPeerID!) {

        dispatch_async(dispatch_get_main_queue(), {
            println("sessionManager")
            
            let message = NSString(data: data, encoding: NSUTF8StringEncoding)
            let alert = UIAlertView()
            alert.title = "Message Received!"
            alert.message = message
            alert.addButtonWithTitle("Okay")
            alert.show()
            
            })
    }
    
    //#pragma mark - UITableView Delegate Methods
    
    func tableView(_tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        
        var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "tableCell")
        
        switch indexPath.section {
        case 0:
            cell.textLabel.text = singleton._session?.connectedPeers[indexPath.row].displayName
        case 1:
            cell.textLabel.text = singleton._connectingPeers[indexPath.row].displayName
        case 2:
            cell.textLabel.text = singleton._peersInRange[indexPath.row].displayName
        default:
            if singleton._session?.myPeerID? {
                cell.textLabel.text = singleton._session?.myPeerID.displayName
            } else {
                cell.textLabel.text = "not in mesh"
            }
        }

        return cell
    }
    
    func tableView(_tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            
            if let session = singleton._session? {
                return session.connectedPeers.count
            } else {
                return 0
            }
        case 1:
            return singleton._connectingPeers.count
        case 2:
            return singleton._peersInRange.count
        default:
            return 1
        }
    }
    
    func numberOfSectionsInTableView(_tableView: UITableView!) -> Int {
        return 4
    }
    
    func tableView(_tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        switch section {
        case 0:
            return "Connected - Tap to send a message"
        case 1:
            return "Connecting"
        case 2:
            return "Devices In Range"
        default:
            return "My ID"
        }
    }
    
    func tableView(_tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        _tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            let message = "\(singleton._peerID?.displayName) says hello!"
            let data = message.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true)
            var error:NSError?
            let alert = UIAlertView()
            
            var singlePeerArray = [MCPeerID]()
            singlePeerArray.append(singleton._session?.connectedPeers[indexPath.row] as MCPeerID)
            
            if singleton._session?.sendData(data, toPeers:singlePeerArray, withMode: MCSessionSendDataMode.Reliable, error: &error) {
                alert.title = "Success"
                alert.message = "Message sent!"
                alert.addButtonWithTitle("Okay")
            } else {
                alert.title = "Failure"
                alert.message = "Message was not sent!"
                alert.addButtonWithTitle("Okay")
            }
            
            alert.show()
            
        case 2:
            singleton.invitePeerToMesh(singleton._peersInRange[indexPath.row] as MCPeerID)
        default:
            println("")
        }
        
    }
}

