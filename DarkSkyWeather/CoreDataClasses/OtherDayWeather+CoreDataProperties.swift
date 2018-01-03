//
//  OtherDayWeather+CoreDataProperties.swift
//  DarkSkyWeather
//
//  Created by Ghouse Basha Shaik on 08/12/17.
//  Copyright © 2017 Ghouse. All rights reserved.
//
//

import Foundation
import CoreData


extension OtherDayWeather {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<OtherDayWeather> {
        return NSFetchRequest<OtherDayWeather>(entityName: "OtherDayWeather")
    }

    @NSManaged public var datetime: Double
    @NSManaged public var maxtemp: Float
    @NSManaged public var mintemp: Float
    @NSManaged public var summary: String?

}
