//
//  ViewController.swift
//  com.awareframework.ios.sensor.linearaccelerometer
//
//  Created by tetujin on 11/20/2018.
//  Copyright (c) 2018 tetujin. All rights reserved.
//

import UIKit
import com_awareframework_ios_sensor_linearaccelerometer

class ViewController: UIViewController {
    
    var sensor:LinearAccelerometerSensor?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
//        sensor = LinearAccelerometerSensor.init(LinearAccelerometerSensor.Config().apply{config in
//            config.debug = true
//            config.sensorObserver = Observer()
//        
//        });
//        sensor?.start()
    }
    
    class Observer:LinearAccelerometerObserver{
        func onDataChanged(data: LinearAccelerometerData) {
            print(data)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

