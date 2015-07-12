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
    
    @IBOutlet weak var leftMainTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftSubTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightSubTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightMainTextConstraint: NSLayoutConstraint!
    @IBOutlet weak var topImageConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageWidthConstraint: NSLayoutConstraint!
    
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
        
        let font:UIFont? = UIFont(name: "Gotham Medium", size: 23.0)
        
        var paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 5
        paragraphStyle.alignment = .Center
        
        var attrString = NSMutableAttributedString(string: mainText)
        
        attrString.addAttributes([NSParagraphStyleAttributeName:paragraphStyle, NSFontAttributeName:UIFont(name: "Gotham Medium", size: 23.0)!], range: NSMakeRange(0, attrString.length))
        
        self.contentMainText.attributedText = attrString
        
        attrString = NSMutableAttributedString(string: subText)
        
        paragraphStyle.lineSpacing = 3
        
        attrString.addAttributes([NSParagraphStyleAttributeName:paragraphStyle, NSFontAttributeName:UIFont(name: "Gotham", size: 14.0)!], range: NSMakeRange(0, attrString.length))
        
        
        self.contentSubText.attributedText = attrString
        
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
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        var labelValue :CGFloat = leftMainTextConstraint.constant
        var imageTopValue :CGFloat = topImageConstraint.constant
        var imageWidthHeight : CGFloat = imageWidthConstraint.constant
        
        //Handle > iPhone 6
        if (UIScreen.mainScreen().bounds.size.width > 375.0) {
            labelValue = 65.0
        } else if (UIScreen.mainScreen().bounds.size.width < 375.0) {
            labelValue = 20.0
            imageTopValue = 28.0
        }
        
        //Handle < iPhone 6
        if (UIScreen.mainScreen().bounds.size.height < 559.0) {
            imageWidthHeight = 143.0
        }
        
        leftMainTextConstraint.constant = labelValue
        rightMainTextConstraint.constant = labelValue
        
        leftSubTextConstraint.constant = labelValue
        rightSubTextConstraint.constant = labelValue

        topImageConstraint.constant = imageTopValue
        
        imageHeightConstraint.constant = imageWidthHeight
        imageWidthConstraint.constant = imageWidthHeight
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
