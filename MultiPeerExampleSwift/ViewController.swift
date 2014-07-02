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
    
    func sessionDidChangeState()  {
        println("************************************************")
        println("connecting Peers: \(singleton._connectingPeers)")
        println("peers In Range: \(singleton._peersInRange)")
        println("connected Peers: \(singleton._session?.connectedPeers)")
        
        dispatch_async(dispatch_get_main_queue(), {self.connectionTableView.reloadData()})
    }
    
    //#pragma mark - UITableView Delegate Methods
    
    func tableView(_tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
        
        var cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "tableCell")
        
        switch indexPath.section {
        case 0:
            cell.textLabel.text = singleton._session?.connectedPeers[indexPath.row].displayName
        case 1:
            cell.textLabel.text = singleton._connectingPeers[indexPath.row].displayName
        default:
            cell.textLabel.text = singleton._peersInRange[indexPath.row].displayName
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
        default:
            return singleton._peersInRange.count
        }
    }
    
    func numberOfSectionsInTableView(_tableView: UITableView!) -> Int {
        return 3
    }
    
    func tableView(_tableView: UITableView!, titleForHeaderInSection section: Int) -> String! {
        switch section {
        case 0:
            return "Connected"
        case 1:
            return "Connecting"
        default:
            return "Devices In Range"
        }
    }
    
    func tableView(_tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath!) {
        _tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

}

