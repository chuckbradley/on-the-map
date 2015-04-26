//
//  ListViewController.swift
//  On The Map
//
//  Created by Chuck Bradley on 4/6/15.
//  Copyright (c) 2015 FreedomMind. All rights reserved.
//

import UIKit

class ListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var locationList: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }


    override func viewWillAppear(animated: Bool) {
        loadLocations()
    }


    func loadLocations() {
        Udacity.SINGLETON.requestLocations() {
            success, error in
            if let error = error {
                self.notify(error)
            }
        }
    }


    func presentPostingViewController() {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PostingViewController") as! PostingViewController
        controller.modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
        presentViewController(controller, animated: true, completion: nil)
    }



    func notify(message:String) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default) { action in })
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }



    @IBAction func pinButtonTouch(sender: AnyObject) {
        // check for existing entry. If so, show alert. If not, proceed to PostingViewController
        if Udacity.SINGLETON.userHasLocation {

            let alertController: UIAlertController = UIAlertController(title: nil, message: "You have already posted a Student Location. Would you like to overwrite your current location?", preferredStyle: .Alert)
            
            let overwriteAction = UIAlertAction(title: "Overwrite", style: .Default) {
                action in
                self.presentPostingViewController()
            }
            alertController.addAction(overwriteAction)
            
            let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) {
                action in
                // cancel
            }
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)

        } else {
            presentPostingViewController()
        }
    }
    
    
    @IBAction func refreshButtonTouch(sender: AnyObject) {
        loadLocations()
        locationList.reloadData()
    }


    /* tableView delegate methods: */

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return Udacity.SINGLETON.locations.count
    }


    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("LocationCell") as! UITableViewCell
        let location = Udacity.SINGLETON.locations[indexPath.row]
        cell.textLabel!.text = location.annotation.title
        cell.imageView!.image = UIImage(named: "pin")
        return cell
    }


    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let location = Udacity.SINGLETON.locations[indexPath.row]
        if let url = location.mediaURL {
            UIApplication.sharedApplication().openURL(NSURL(string:url)!)
        }
    }


}

