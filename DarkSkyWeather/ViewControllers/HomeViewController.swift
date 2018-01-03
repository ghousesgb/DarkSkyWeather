//
//  ViewController.swift
//  DarkSkyWeather
//
//  Created by Ghouse Basha Shaik on 08/12/17.
//  Copyright © 2017 Ghouse. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController {
    @IBOutlet weak var timeZone: UILabel!
    @IBOutlet weak var currentDateTime: UILabel!
    @IBOutlet weak var currentSummary: UILabel!
    @IBOutlet weak var currentTemperature: UILabel!
    @IBOutlet weak var tempTableView: UITableView!
    
    fileprivate var weather: Weather?
    override func viewDidLoad() {
        super.viewDidLoad()
        //Creating url string with hardcoded lat and lng
        let jsonURLString = BASE_URL + "37.8267,-122.4233"
        guard let URL = URL(string:jsonURLString) else {return}
        //Making a API Call
        URLSession.shared.dataTask(with: URL) { (data, response, err) in
            guard let data = data else {return}
            do {
                //Decoding using JSONDecoder
                self.weather = try JSONDecoder().decode(Weather.self, from: data)
                self.buildUI()
                DispatchQueue.main.async {[unowned self] in
                    self.tempTableView.reloadData()
                }
            }catch let jsonErr {
                print("Error descrption ", jsonErr)
            }
        }.resume()
    }
    //Preparing UI
    fileprivate func buildUI() {
        DispatchQueue.main.async {[unowned self] in
            if let weather = self.weather {
                if let timezone = weather.timezone {
                    self.timeZone.text = timezone
                }
                if let summary = weather.currently.summary {
                    self.currentSummary.text = summary
                }
                self.currentTemperature.text = weather.currently.formattedTemperature
                self.currentDateTime.text    = weather.currently.formattedTimeZone
            }
        }
        self.saveData()
    }
    //Saving the Date as a backup into CoreData.
    //Basically it is not need to save this data, as everytime we open the app we get new/refresh data.
    //So no point of having database for this app.
    fileprivate func saveData() {
        let todayWeatherRecord = TodaysWeather(context: StorageManager.context)
        todayWeatherRecord.datetime     =    (self.weather?.currently.time)!
        todayWeatherRecord.summary      =    self.weather?.currently.summary
        todayWeatherRecord.temperature  =    (self.weather?.currently.temperature)!
        todayWeatherRecord.location     =   self.weather?.timezone
        
        for weekRecrod in (self.weather?.daily.data)! {
            let otherWeatherRecord = OtherDayWeather(context: StorageManager.context)
            otherWeatherRecord.datetime =   weekRecrod.time!
            otherWeatherRecord.maxtemp  =   weekRecrod.temperatureHigh!
            otherWeatherRecord.mintemp  =   weekRecrod.temperatureLow!
            otherWeatherRecord.summary  =   weekRecrod.summary!
        }
        StorageManager.saveContext()
    }
}

extension HomeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let weather = self.weather {
            return weather.daily.data.count
        }
        return 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "weekCell", for: indexPath) as? WeekTableViewCell
        let data = self.weather?.daily.data[indexPath.row]
        cell?.buildCellUI(data: data!)
        return cell!
    }
}

extension HomeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 65.0
    }
}

