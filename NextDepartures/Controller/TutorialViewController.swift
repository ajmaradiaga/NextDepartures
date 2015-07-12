//
//  TutorialViewController.swift
//  NextDepartures
//
//  Created by Antonio Maradiaga on 4/07/2015.
//  Copyright (c) 2015 Antonio Maradiaga. All rights reserved.
//

import UIKit

class TutorialViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    var pageViewController : UIPageViewController!
    
    var viewControllers = NSMutableArray()
    
    let mainTexts = ["Welcome to Next Departures", "Never miss a stop with tracking", "Know your location wherever you are","Saving your favourite stop is super easy"]
    let subTexts = ["Easily search, track and get notification for available public transport around you in real time", "Just swipe and select your desired destination point. we will notify you when it’s near", "Push that little blue button when you are lost, it will show your current location on map","Life is a little bit simpler with favourites. Just save your favourite stop and get an instant access"]
    let images = ["WelcomeImage","NeverMissStop", "KnowYourLocation", "SuperEasyFavourites"]
    let colours = [UIColor(red: 53/255, green: 192/255, blue: 124/255, alpha: 1.0), UIColor(red: 180/255, green: 85/255, blue: 194/255, alpha: 1.0), UIColor(red: 22/255, green: 166/255, blue: 238/255, alpha: 1.0), UIColor(red: 248/255, green: 206/255, blue: 49/255, alpha: 1.0)]
    
    var pageIndex: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        initialise()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func skitButtonTapped(sender: AnyObject) {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "ShownTutorial")
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func initialise() {
        pageViewController = self.storyboard?.instantiateViewControllerWithIdentifier("TutorialPageVC") as! UIPageViewController
        
        self.pageViewController.dataSource = self
        self.pageViewController.delegate = self
        
        for var i = 0; i < mainTexts.count; i++ {
            var vc = viewControllerAtIndex(i)!
           self.viewControllers.addObject(vc)
        }
        
        //let pageContentViewController = self.viewControllerAtIndex(0)
        self.pageViewController.setViewControllers([self.viewControllers.objectAtIndex(0)], direction: UIPageViewControllerNavigationDirection.Forward, animated: true, completion: nil)
        
        self.view.backgroundColor = self.colours[0]
        
        
        /* We are substracting 30 because we have a start again button whose height is 30*/
        self.pageViewController.view.frame = CGRectMake(0, 60, self.view.frame.width, self.view.frame.height - 60)
        self.addChildViewController(pageViewController)
        self.view.addSubview(pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
    
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as! TutorialContentViewController).pageIndex!
        index++
        if(index >= self.images.count){
            return nil
        }
        //return self.viewControllerAtIndex(index)
        return viewControllers.objectAtIndex(index) as? UIViewController
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var index = (viewController as! TutorialContentViewController).pageIndex!
        if(index <= 0){
            return nil
        }
        index--
        return viewControllers.objectAtIndex(index) as? UIViewController
    }
    
    func pageViewController(pageViewController: UIPageViewController, willTransitionToViewControllers pendingViewControllers: [AnyObject]) {
        
        
        if pendingViewControllers.count > 0 {
            var index = (pendingViewControllers[0] as! TutorialContentViewController).pageIndex!
            
            self.view.backgroundColor = self.colours[index]
        }
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
    }
    
    func viewControllerAtIndex(index : Int) -> UIViewController? {
        if((self.mainTexts.count == 0) || (index >= self.mainTexts.count)) {
            return nil
        }
        var pageContentViewController = self.storyboard?.instantiateViewControllerWithIdentifier("TutorialContentVC") as! TutorialContentViewController
        
        pageContentViewController.image = UIImage(named:self.images[index])!
        pageContentViewController.mainText = self.mainTexts[index]
        pageContentViewController.subText = self.subTexts[index]
        pageContentViewController.backgroundColour = self.colours[index]
        pageContentViewController.pageIndex = index
        return pageContentViewController
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return mainTexts.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
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
