//
//  SmartMirrorViewController.swift
//  SmartMirror
//
//  Created by Julien Saad on 2016-02-22.
//  Copyright © 2016 Julien Saad. All rights reserved.
//

import UIKit
import ForecastIO
import EventKitUI
import Alamofire

class SmartMirrorViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var temperatureIconView: SKYIconView!
    
    @IBOutlet weak var tableView: UITableView!
    let forecastIOClient = APIClient(apiKey: "bc1377d044b4156a4a333ae11d68d8cf")
    let eventStore = EKEventStore()
    var events:[EKEvent] = Array()
    
    var articles:[Article] = Array()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.backgroundColor = UIColor.blackColor()
        tableView.tableFooterView = UIView(frame: CGRectZero)
        
        updateDate()
        fetchTemperature()
        fetchEvents()
        fetchArticles()
        
        // Update information at a scheduled interval
        NSTimer.scheduledTimerWithTimeInterval(60 * 15, target: self, selector: #selector(SmartMirrorViewController.fetchTemperature), userInfo: nil, repeats: true)
        NSTimer.scheduledTimerWithTimeInterval(30, target: self, selector: #selector(SmartMirrorViewController.updateDate), userInfo: nil, repeats: true)
        NSTimer.scheduledTimerWithTimeInterval(60 * 5, target: self, selector: #selector(SmartMirrorViewController.fetchEvents), userInfo: nil, repeats: true)
        NSTimer.scheduledTimerWithTimeInterval(60 * 5, target: self, selector: #selector(SmartMirrorViewController.fetchArticles), userInfo: nil, repeats: true)
    }
    
    func updateDate() {
        let dayFormatter = NSDateFormatter()
        dayFormatter.dateFormat = "EEEE"
        
        let dayString: String = dayFormatter.stringFromDate(NSDate())
        
        let daystamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .LongStyle, timeStyle: .NoStyle).stringByReplacingOccurrencesOfString(", 2016", withString: "");
        
        
        self.dateLabel.text = "\(dayString), \(daystamp)"
        
        
        let timestamp = NSDateFormatter.localizedStringFromDate(NSDate(), dateStyle: .NoStyle, timeStyle: .ShortStyle)
        self.timeLabel.text = timestamp.stringByReplacingOccurrencesOfString(" AM", withString: "")
            .stringByReplacingOccurrencesOfString(" PM", withString: "");
        
    }
    
    func fetchTemperature() {
        temperatureIconView.color = UIColor.whiteColor()
        temperatureIconView.backgroundColor = UIColor.clearColor()
        temperatureIconView.play()
        
        forecastIOClient.units = Units.CA
        forecastIOClient.getForecast(latitude: 45.5330564, longitude: -73.5766394) { (currentForecast, error) -> Void in
            if let currentForecast = currentForecast {
                if let temperature = currentForecast.currently?.temperature {
                    let formattedTemperature = String(format: "%.0f", round(temperature))
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.temperatureLabel.text = "\(formattedTemperature)°"
                        
                        switch (currentForecast.currently!.icon!.rawValue) {
                        case "clear-day":
                            self.temperatureIconView.type = SKYIconType.ClearDay
                            
                        case "clear-night":
                            self.temperatureIconView.type = SKYIconType.ClearNight
                            
                        case "rain":
                            self.temperatureIconView.type = SKYIconType.Rain
                            
                        case "snow":
                            self.temperatureIconView.type = SKYIconType.Snow
                            
                        case "sleet":
                            self.temperatureIconView.type = SKYIconType.Sleet
                            
                        case "wind":
                            self.temperatureIconView.type = SKYIconType.Wind
                            
                        case "fog":
                            self.temperatureIconView.type = SKYIconType.Fog
                            
                        case "partly-cloudy-day":
                            self.temperatureIconView.type = SKYIconType.PartlyCloudyDay
                            
                        case "partly-cloudy-night":
                            self.temperatureIconView.type = SKYIconType.PartlyCloudyNight
                        default:
                            self.temperatureIconView.type = SKYIconType.ClearDay
                        }
                    })
                }
            }
        }
        
    }
    
    func fetchEvents() {
        
        eventStore.requestAccessToEntityType(EKEntityType.Event) { [weak self] (granted, error) -> Void in
            if let strongSelf = self {
                let calendars = strongSelf.eventStore.calendarsForEntityType(.Event)
                
                for calendar in calendars {
                    if calendar.title.containsString("Horaires") {
                        let endDate = NSDate(timeIntervalSinceNow: 172800 / 2); // Fetch events for 2 days
                        let predicate = strongSelf.eventStore.predicateForEventsWithStartDate(NSDate(), endDate: endDate, calendars: [calendar])
                        let events = strongSelf.eventStore.eventsMatchingPredicate(predicate)
                        strongSelf.events = events
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    strongSelf.tableView.reloadData()
                })
            }
        }
        
    }
    
    func fetchArticles() {
        Alamofire.request(.GET, "https://api.nytimes.com/svc/topstories/v1/home.json?api-key=9e3eaee4f548a208d2ffe7d29f7fba01:16:74568796", parameters: nil, encoding: .JSON, headers: nil).responseJSON { (response) -> Void in
            
            self.articles.removeAll()
            
            switch response.result {
            case .Success(let JSON):
                guard let results = JSON["results"] else {
                    return
                }
                
                let resultsArray = results as! NSArray
                
                for result in resultsArray {
                    let resultDic = result as! NSDictionary
                    let title = resultDic.objectForKey("title") as! String
                    let article = Article(title: title)
                    self.articles.append(article)
                }
                self.tableView.reloadData()
                
            case .Failure(let error):
                print("Request failed with error: \(error)")
            }
        }
        
    }
    
    // MARK: UITableView
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("cell")! as! SmartTableViewCell
        
        cell.userInteractionEnabled = false
        
        if indexPath.section == 0 {
            let event = events[indexPath.row]
            var startTimeString = NSDateFormatter.localizedStringFromDate(event.startDate, dateStyle: .NoStyle, timeStyle: .ShortStyle)
            let cal = NSCalendar.currentCalendar()
            var components = cal.components([.Era, .Year, .Month, .Day], fromDate:NSDate())
            let today = cal.dateFromComponents(components)!
            
            components = cal.components([.Era, .Year, .Month, .Day], fromDate:event.startDate);
            let otherDate = cal.dateFromComponents(components)!
            
            if !today.isEqualToDate(otherDate) {
                startTimeString = "Tomorrow \(startTimeString)"
            }
            cell.textLabel?.text = "\(event.title) - \(startTimeString)"
            cell.type = .Calendar
            
        } else {
            let article = articles[indexPath.row]
            cell.textLabel?.text = article.title
            cell.type = .Headline
        }
        
        
        
        cell.backgroundColor = UIColor.blackColor()
        cell.textLabel?.textColor = UIColor.whiteColor()
        cell.textLabel?.font = UIFont.systemFontOfSize(22, weight: UIFontWeightSemibold)
        cell.textLabel?.textAlignment = NSTextAlignment.Left
        cell.indentationWidth = 68
        cell.indentationLevel = 1
        
        return cell
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return min(events.count, 3)
        }
        else {
            return min(articles.count, 3)
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRectZero)
        view.backgroundColor = UIColor.clearColor()
        return view
    }
    
    
    override func prefersStatusBarHidden() -> Bool {
        return true;
    }
}


extension NSDate {
    func dayOfWeek() -> Int? {
        if
            let cal: NSCalendar = NSCalendar.currentCalendar(),
            let comp: NSDateComponents = cal.components(.Weekday, fromDate: self) {
                return comp.weekday
        } else {
            return nil
        }
    }
}
