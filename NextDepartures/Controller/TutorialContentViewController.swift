//
//  TutorialContentViewController.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 4/07/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit

class TutorialContentViewController: UIViewController {

    @IBOutlet weak var contentImage: UIImageView!
    @IBOutlet weak var contentMainText: UILabel!
    @IBOutlet weak var contentSubText: UILabel!
    @IBOutlet weak var letsGoButton: UIButton!
    
    
    var pageIndex: Int?
    
    var mainText : String!
    var subText: String!
    var image: UIImage!
    var backgroundColour: UIColor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
       
        contentMainText.alpha = 0
        contentSubText.alpha = 0
        
        self.contentImage.image = image
        self.contentMainText.text = mainText
        self.contentSubText.text = subText
        
        if pageIndex == 3 {
            var letsGoColour = UIColor(red: 224/255, green: 65/255, blue: 38/255, alpha: 1.0)
            
            self.letsGoButton.backgroundColor = letsGoColour
            letsGoButton.layer.cornerRadius = 5
            letsGoButton.layer.borderWidth = 1
            letsGoButton.layer.borderColor = letsGoColour.CGColor
            self.letsGoButton.hidden = false
        }
    }
    
    @IBAction func letsGoButtonTapped(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "ShownTutorial")
        self.parentViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        UIView.animateWithDuration(0.5, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: { () -> Void in
            self.contentMainText.alpha = 1.0
            self.contentSubText.alpha = 1.0
        }, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        view.layoutIfNeeded()
    }
    
    override func viewDidDisappear(animated: Bool) {
        contentMainText.alpha = 0
        contentSubText.alpha = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func skipButtonTapped(sender: AnyObject) {
    }
    
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
