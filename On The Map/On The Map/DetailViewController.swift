//
//  DetailViewController.swift
//  On The Map
//
//  Created by Chuck Bradley on 4/21/15.
//  Copyright (c) 2015 FreedomMind. All rights reserved.
//

import UIKit
import MapKit

class DetailViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {


    @IBOutlet weak var nameField: UITextView!
    @IBOutlet weak var urlField: UITextView!
    @IBOutlet weak var mapStringField: UITextView!

    @IBOutlet weak var mapView: MKMapView!

    var textViewTapRecognizer:UITapGestureRecognizer = UITapGestureRecognizer()

    override func viewDidLoad() {
        super.viewDidLoad()
        // add tap recognizer to mapString textView
        mapStringField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapMapString:"))
        urlField.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "tapLink:"))
    }



    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mapView.removeAnnotations(mapView.annotations)
        nameField.text = "\(Udacity.SINGLETON.firstName) \(Udacity.SINGLETON.lastName)"

        Udacity.SINGLETON.requestUserLocation() {
            success, error in
            if let error = error {
                dispatch_async(dispatch_get_main_queue()) {
                    self.urlField.text = "Error: \(error)"
                    self.mapStringField.text = ""
                }
            } else if Udacity.SINGLETON.userHasLocation {
                dispatch_async(dispatch_get_main_queue()) {
                    self.urlField.text = Udacity.SINGLETON.userLocation!.mediaURL
                    self.mapStringField.text = Udacity.SINGLETON.userLocation!.mapString
                    self.mapView.addAnnotation(Udacity.SINGLETON.userLocation!.annotation)
                    let region = MKCoordinateRegionMakeWithDistance(Udacity.SINGLETON.userLocation!.annotation.coordinate, 10000, 10000)
                    self.mapView.setRegion(region, animated: true)
                }
            } else {
                dispatch_async(dispatch_get_main_queue()) {
                    self.urlField.text = "You haven't yet set your location."
                    self.mapStringField.text = "Post Location and URL"
                }
            }
        }
    }




    // if user has a location, the field displays the mediaURL.
    // Tapping it will display the link in Safari.
    func tapLink(sender:UITapGestureRecognizer) {
        if Udacity.SINGLETON.userHasLocation {
            UIApplication.sharedApplication().openURL(NSURL(string: urlField.text)!)
        }
    }
    
    
    
    // if user doesn't have a location, the field displays an action.
    // Tapping it will present the posting view controller so it can be edited.
    func tapMapString(sender:UITapGestureRecognizer) {
        if !Udacity.SINGLETON.userHasLocation {
            presentPostingViewController()
        }
    }
    
    
    
    
    

    @IBAction func pinButtonTouch(sender: AnyObject) {
        if Udacity.SINGLETON.userHasLocation {
            
            let alertController: UIAlertController = UIAlertController(title: nil, message: "You have already posted a Student Location. Would you like to overwrite your current location?", preferredStyle: .Alert)

            let overwriteAction = UIAlertAction(title: "Overwrite", style: .Default) {
                action in
                self.presentPostingViewController()
            }
            alertController.addAction(overwriteAction)
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel) {
                action in
                // cancel
            }
            alertController.addAction(cancelAction)
            
            self.presentViewController(alertController, animated: true, completion: nil)
            
        } else {
            presentPostingViewController()
        }
    }


    @IBAction func logoutButtonTouch(sender: AnyObject) {
        Udacity.SINGLETON.logOut()
        performSegueWithIdentifier("logout", sender: self)
    }


    func presentPostingViewController() {
        let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PostingViewController") as! PostingViewController
        controller.modalTransitionStyle = UIModalTransitionStyle.FlipHorizontal
        presentViewController(controller, animated: true, completion: nil)
    }

    
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        } else {
            pinView!.annotation = annotation
        }
        pinView!.pinColor = .Purple
        
        return pinView
    }


}

