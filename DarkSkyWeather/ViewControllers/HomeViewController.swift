//
//  ViewController.swift
//  DarkSkyWeather
//
//  Created by Ratheesh Konkala on 12/07/17.
//  Copyright © 2017 Ratheesh Konkala. All rights reserved.
//

import UIKit
import CoreLocation

class HomeViewController: UIViewController {
    @IBOutlet weak var locationLabel: UILabel!
    @IBOutlet weak var currentDateTime: UILabel!
    @IBOutlet weak var currentSummary: UILabel!
    @IBOutlet weak var currentTemperature: UILabel!
    @IBOutlet weak var tempTableView: UITableView!
    @IBOutlet weak var sunraiseLabel: UILabel!
    @IBOutlet weak var sunsetLabel: UILabel!
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var windSpeedLabel: UILabel!
    fileprivate var weather: Weather?
    fileprivate var otherInfo: OtherInfo?
    
    fileprivate var latitude: Double?
    fileprivate var longitude: Double?
    fileprivate var location: String?
    
    fileprivate var locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       self.enableLocationServices()
    }
    
    fileprivate func featchWeatherForecast() {
        
        //Creating url string with hardcoded lat and lng
        let parameters = String(format:"lat=%f&lon=%f&APPID=%@",self.latitude!,self.longitude!,OPEN_WEATHER_APIKEY)
        let urlString = OTHER_BASE_URL + parameters
        guard let compURL = URL(string:urlString) else {return}
        //Making a DarkSky API Call
        
        URLSession.shared.dataTask(with: compURL) { (data, response, err) in
            guard let data = data else {return}
            do {
                //Decoding using JSONDecoder
                self.otherInfo = try JSONDecoder().decode(OtherInfo.self, from: data)
                self.buildSunRaiseSetUI()
            }catch let jsonErr {
                print("Error descrption ", jsonErr)
            }
            }.resume()
        
        //Creating url string with hardcoded lat and lng
        let latLngString = String(format:"%f,%f",self.latitude!,self.longitude!)
        let jsonURLString = BASE_URL + latLngString
        guard let URL = URL(string:jsonURLString) else {return}
        //Making a DarkSky API Call
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
    
    //Preparing SunRise and set UI
    fileprivate func buildSunRaiseSetUI() {
        DispatchQueue.main.async {[unowned self] in
            self.windSpeedLabel.text    =   self.otherInfo?.wind.formattedSpeed
            self.sunraiseLabel.text     =   self.otherInfo?.sys.formattedSunRise
            self.sunsetLabel.text       =   self.otherInfo?.sys.formattedSunSet
        }
    }
    //Preparing UI
    fileprivate func buildUI() {
        DispatchQueue.main.async {[unowned self] in
            if let weather = self.weather {
                if let summary = weather.currently.summary {
                    self.currentSummary.text = summary
                }
                self.currentTemperature.text = weather.currently.formattedTemperature
                self.currentDateTime.text    = weather.currently.formattedTimeZone
            }
        }
        self.saveData()
    }
    //Saving the Data as a backup into CoreData.
    //Basically it is not need to save this data, as everytime we open the app we get new/refresh data.
    //So no point of having database for this app.
    fileprivate func saveData() {
        let todayWeatherRecord = TodaysWeather(context: StorageManager.context)
        todayWeatherRecord.datetime     =    (self.weather?.currently.time)!
        todayWeatherRecord.summary      =    self.weather?.currently.summary
        todayWeatherRecord.temperature  =    (self.weather?.currently.temperature)!
        todayWeatherRecord.location     =    self.weather?.timezone
        
        for weekRecrod in (self.weather?.daily.data)! {
            let otherWeatherRecord = OtherDayWeather(context: StorageManager.context)
            otherWeatherRecord.datetime =   weekRecrod.time!
            otherWeatherRecord.maxtemp  =   weekRecrod.temperatureHigh!
            otherWeatherRecord.mintemp  =   weekRecrod.temperatureLow!
            otherWeatherRecord.summary  =   weekRecrod.summary!
        }
        StorageManager.saveContext()
    }
    @IBAction func searchButtonAction(_ sender: UIButton) {
        guard let searchString = searchTextField.text, searchString.count > 3 else {
            self.showAlert(message: "Invalid search name")
            return
        }
        searchTextField.text = ""
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchString) { (placemarks, error) in
            if let placemark = placemarks?.first {
                self.latitude  = placemark.location?.coordinate.latitude
                self.longitude = placemark.location?.coordinate.longitude
                self.locationLabel.text   = placemark.country! + "\n" + placemark.name!
                self.featchWeatherForecast()
            }else {
               self.showAlert(message: "could't search address")
            }
        }
    }
    
    fileprivate func showAlert(message: String) {
        let alert = UIAlertController(title: "Information", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        DispatchQueue.main.async {[unowned self] in
         self.present(alert, animated: true, completion: nil)
        }
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

extension HomeViewController: CLLocationManagerDelegate{
    func enableLocationServices() {
        self.locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            self.locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            print("restricted/denied")
            break
            
        case .authorizedWhenInUse:
            // Enable basic location features
            self.locationManager.startUpdatingLocation()
            break
        case .authorizedAlways:
            print("always")
        }
    }
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
    {
        if status == CLAuthorizationStatus.authorizedAlways || status == CLAuthorizationStatus.authorizedWhenInUse
        {
            self.locationManager.startUpdatingLocation()
        }
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // get last location
        self.locationManager.stopUpdatingLocation()
        let location = locations.last
        self.latitude  = location?.coordinate.latitude
        self.longitude = location?.coordinate.longitude
        self.featchWeatherForecast()
        // Create Location
        let geolocation = CLLocation(latitude: self.latitude!, longitude: self.longitude!)
        let geocoder = CLGeocoder()
        // Geocode Location
        geocoder.reverseGeocodeLocation(geolocation) { (placemarks, error) in
             if let placemark = placemarks?.first {
                self.locationLabel.text   = placemark.country! + "\n" + placemark.name!
            }
        }
    }

}

