//
//  ViewController.swift
//  Lab03
//
//  Created by jkunwar on 2022-07-23.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var weatherConditionLabel: UILabel!
    
    @IBOutlet weak var weatherConditionImage: UIImageView!
    
    @IBOutlet weak var tempratureLabel: UILabel!
    
    @IBOutlet weak var locationLabel: UILabel!
    
    private var weatherImages: [String: String] = [
        //Clear
        "1000_0": "moon.stars.fill",
        "1000_1": "sun.max.fill",
        //Partially cloudy
        "1003_0": "cloud.moon.fill",
        "1003_1": "cloud.sun.fill",
        //Cloudy
        "1006_0": "cloud.fill",
        "1006_1": "cloud.fill",
        //Light rain with thunder
        "1273_0": "cloud.bolt.rain.fill",
        "1273_1": "cloud.bolt.rain.fill",
        //Moderate or heavy rain with thunder
        "1276_0": "cloud.bolt.rain.fill",
        "1276_1": "cloud.bolt.rain.fill",
        "1150_0": "cloud.sun.rain.fill",
        "1150_1": "cloud.moon.rain.fill",
        //Light Rain
        "1183_0": "cloud.drizzle.fill",
        "1183_1": "cloud.drizzle.fill",
        //Heavy Rain
        "1195_0": "cloud.heavyrain.fill",
        "1195_1": "cloud.heavyrain.fill",
        //Ligth snow
        "1213_0": "snowflake.circle.fill",
        "1213_1": "snowflake.circle.fill",
        //Moderate snow
        "1219_0": "cloud.sleet.fill",
        "1219_1": "cloud.sleet.fill",
        //Heavy snow
        "1225_0": "cloud.snow.fill",
        "1225_1": "cloud.snow.fill"
    ]
    
    private let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        weatherConditionLabel.isHidden = true
        displayWeatherImage(weatherImageName: "sun.max")
       
        searchTextField.delegate = self
        locationManager.delegate = self
        //Display current location weather if permission already granted
        locationManager.requestLocation()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.endEditing(true)
        loadWeather(search: textField.text)
        return true
    }
    
    private func displayWeatherImage(weatherImageName: String) {
        let config = UIImage.SymbolConfiguration(paletteColors: [
            .systemMint, .systemTeal, .systemIndigo
        ])
        weatherConditionImage.preferredSymbolConfiguration = config
        weatherConditionImage.image = UIImage(systemName: weatherImageName)
    }
    
    @IBAction func onLocationLapped(_ sender: UIButton) {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        searchTextField.text = ""
    }
    
    @IBAction func omSearchTapped(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
    }
    
    private func loadWeather(search: String?) {
        guard let search = search else {
            return
        }
        
        guard let url = getURL(query: search) else {
            print("Could not get URL")
            return
        }
        
        let session = URLSession.shared
        
        let dataTask = session.dataTask(with: url) { data, response, error in
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                print("No data receiced")
                return
            }
            if let weatherResponse = self.parseWeatherResponse(data: data) {
                DispatchQueue.main.async {
                    self.locationLabel.text = "\(weatherResponse.location.name), \(weatherResponse.location.country)"
                    self.tempratureLabel.text = "\(weatherResponse.current.temp_c)C"
                    let weatherCode = "\(weatherResponse.current.condition.code)_\(weatherResponse.current.is_day)"
                    
                    guard let weatherImageName = self.weatherImages[weatherCode] else {
                        //For now if no mapping for weather image is found,hide the image
                        self.weatherConditionImage.isHidden = true
                        self.weatherConditionLabel.isHidden = false
                        self.weatherConditionLabel.text = weatherResponse.current.condition.text
                        return
                    }
                    self.weatherConditionImage.isHidden = false
                    self.weatherConditionLabel.isHidden = true
                    self.displayWeatherImage(weatherImageName: weatherImageName)
                }
            }
        }
        
        dataTask.resume()
    }
    
    private func getURL(query: String) ->URL? {
        let baseUrl = "https://api.weatherapi.com/v1/"
        let currentEndpoint = "current.json"
        let apiKey = "16c9b0cb99514c2398f123014222307"
        guard let url = "\(baseUrl)\(currentEndpoint)?key=\(apiKey)&q=\(query)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        return URL(string: url)
    }
    
    private func parseWeatherResponse(data: Data) -> WeatherReponse? {
        let decoder = JSONDecoder()
        var weather: WeatherReponse?
        
        do {
            weather = try decoder.decode(WeatherReponse.self, from: data)
        } catch {
            print("Error Decoding")
        }
        
        return weather
    }
    
    struct WeatherReponse: Decodable {
        let location: Location
        let current: CurrentWeather
    }
    
    struct Location: Decodable {
        let name: String
        let region: String
        let country: String
    }
    
    struct CurrentWeather: Decodable {
        let temp_c: Float
        let is_day: Int
        let condition: WeatherCondition
    }
    
    struct WeatherCondition: Decodable {
        let text: String
        let code: Int
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            loadWeather(search: "\(latitude),\(longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
}
