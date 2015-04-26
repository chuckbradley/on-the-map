//
//  LoginViewController.swift
//  On The Map
//
//  Created by Chuck Bradley on 4/6/15.
//  Copyright (c) 2015 FreedomMind. All rights reserved.
//

import UIKit
import Foundation


class LoginViewController: UIViewController, UITextFieldDelegate {
    
    
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var facebookButton: UIButton!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    var tapRecognizer: UITapGestureRecognizer? = nil

    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.attributedPlaceholder = NSAttributedString(string:"email",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])
        passwordField.attributedPlaceholder = NSAttributedString(string:"password",
            attributes:[NSForegroundColorAttributeName: UIColor.whiteColor()])

        tapRecognizer = UITapGestureRecognizer(target: self, action: "tapAway:")
        tapRecognizer!.numberOfTapsRequired = 1

        // TODO: when facebook login is available, remove hide:
        facebookButton.hidden = true
    
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.view.addGestureRecognizer(tapRecognizer!)
        activityIndicator.hidden = true
    }

    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.view.removeGestureRecognizer(tapRecognizer!)
    }



    @IBAction func loginButtonTouch(sender: AnyObject) {
        if emailField.text.isEmpty || passwordField.text.isEmpty {
            notify("Please enter both your email and password.")
        } else {
            attemptLogin()
        }
    }
    
    

    @IBAction func signupButtonTouch(sender: AnyObject) {
        UIApplication.sharedApplication().openURL(NSURL(string:"https://www.udacity.com/account/auth#!/signin")!)
    }


    // TODO: implement facebook login when SDK is fixed
    @IBAction func facebookButtonTouch(sender: AnyObject) {
        notify("Facebook Login not yet available")
    }



    func attemptLogin() {
        activityIndicator.hidden = false
        activityIndicator.startAnimating()

        Udacity.SINGLETON.logInUser(emailField.text!, withPassword: passwordField.text!) {
            success, error in
            if success {
                dispatch_async(dispatch_get_main_queue(), {
                    self.activityIndicator.hidden = true
                    self.messageTextView.text = ""
                    let controller = self.storyboard!.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
                    self.presentViewController(controller, animated: true, completion: nil)
                })
            } else if let error = error {
                dispatch_async(dispatch_get_main_queue(), {
                    self.activityIndicator.hidden = true
                    self.displayError(error)
                })
            }
        }
        
    }
    

    
    func displayError(errorString: String) {
        dispatch_async(dispatch_get_main_queue(), {
            self.messageTextView.text = errorString
        })
    }
    
    func notify(message:String) {
        let alertController: UIAlertController = UIAlertController(title: nil, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default) { action in })
        self.presentViewController(alertController, animated: true, completion: nil)
        
    }

    func tapAway(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
    }



    /* text field delegate methods */

    func textFieldDidBeginEditing(textField: UITextField) {
        displayError("")
    }


    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
            if !emailField.text.isEmpty {
                attemptLogin()
            }
        }
        return true
    }


    
}

