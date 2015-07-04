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
    
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var skipButton: UIButton!
    
    var pageIndex: Int?
    
    var mainText : String!
    var subText: String!
    var image: UIImage!
    var backgroundColour: UIColor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
       
        self.contentImage.image = image
        self.contentMainText.text = mainText
        self.contentSubText.text = subText
        view.backgroundColor = self.backgroundColour
        self.pageControl.currentPage = pageIndex!
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
