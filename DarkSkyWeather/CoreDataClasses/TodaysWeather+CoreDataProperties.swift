//
//  TodaysWeather+CoreDataProperties.swift
//  DarkSkyWeather
//
//  Created by Ghouse Basha Shaik on 08/12/17.
//  Copyright © 2017 Ghouse. All rights reserved.
//
//

import Foundation
import CoreData


extension TodaysWeather {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TodaysWeather> {
        return NSFetchRequest<TodaysWeather>(entityName: "TodaysWeather")
    }

    @NSManaged public var datetime: Double
    @NSManaged public var location: String?
    @NSManaged public var summary: String?
    @NSManaged public var temperature: Float

}
