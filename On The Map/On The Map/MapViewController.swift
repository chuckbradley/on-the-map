//
//  MapViewController.swift
//  On The Map
//
//  Created by Chuck Bradley on 4/6/15.
//  Copyright (c) 2015 FreedomMind. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, MKMapViewDelegate {

    var annotations = [MKPointAnnotation]()
    
    @IBOutlet weak var mapView: MKMapView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        mapView.removeAnnotations(self.annotations)
        loadLocations()
    }

    
    func loadLocations() {
        Udacity.SINGLETON.requestLocations() {
            success, error in
            if success {
                self.annotations = []
                for location in Udacity.SINGLETON.locations {
                    self.annotations.append(location.annotation)
                }
                dispatch_async(dispatch_get_main_queue(), {
                    self.mapView.addAnnotations(self.annotations)
                })
            } else if let errorString = error {
                self.notify(errorString)
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
        dispatch_async(dispatch_get_main_queue(), {
            self.mapView.removeAnnotations(self.annotations)
            self.loadLocations()
        })
    }



    /* Delegate Methods */

    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinColor = .Red
            if Udacity.SINGLETON.userHasLocation && annotation.title == Udacity.SINGLETON.userLocation!.annotation.title {
                pinView!.pinColor = .Purple
            }
            pinView!.rightCalloutAccessoryView = UIButton.buttonWithType(.DetailDisclosure) as! UIButton
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }



    func mapView(mapView: MKMapView!, annotationView: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if control == annotationView.rightCalloutAccessoryView {
            let app = UIApplication.sharedApplication()
            app.openURL(NSURL(string: annotationView.annotation.subtitle!)!)
        }
    }


}

