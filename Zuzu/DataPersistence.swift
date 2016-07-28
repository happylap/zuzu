//
//  DataPersistence.swift
//  Zuzu
//
//  Created by Jung-Shuo Pai on 2015/10/2.
//  Copyright © 2015年 Jung-Shuo Pai. All rights reserved.
//

import Foundation

// Data persistence errors
public let DataPersistenceErrorDomain = "com.lap.datapersistence.error"

class DataPersistence {

    // MARK: Saving Data

    /**
    * Save data to disk using NSKeyedArchiver.
    *
    * :param: AnyObject
    * :param: NSSearchPathDirectory
    * :param: String
    * :return: A tuple containing the error that occurred, if any and a success and a boolen value to indicate success or failure.
    */
    class func saveData(data: AnyObject, directory: NSSearchPathDirectory, filename: String) -> (error: NSError?, success: Bool) {
        let dataFilepath = DataPersistence.dataFilepath(directory, filename: filename)

        if dataFilepath.success {
            if let filepath = dataFilepath.filepath {
                return (nil, NSKeyedArchiver.archiveRootObject(data, toFile: filepath))
            }
        }

        return (dataFilepath.error, false)
    }

    // MARK: Loading Data

    /**
    * Load data from disk using NSKeyedUnarchiver.
    *
    * :param: NSSearchPathDirectory The directory the data is located.
    * :param: String The filename of the data.
    * :return: A tuple containing the data that has been loaded, the error that occurred, if any and a boolen value to indicate success or failure.
    */
    class func loadDataFromDirectory(directory: NSSearchPathDirectory, filename: String) -> (data: AnyObject?, error: NSError?, success: Bool) {
        let dataFilepath = DataPersistence.dataFilepath(directory, filename: filename)
        if let filepath = dataFilepath.filepath {
            let data: AnyObject? = NSKeyedUnarchiver.unarchiveObjectWithFile(filepath)

            return (data, nil, true)
        }

        return (nil, dataFilepath.error, false)
    }


    class func deleteDataFromDirectory(directory: NSSearchPathDirectory, filename: String) -> (error: NSError?, success: Bool) {
        let dataFilepath = DataPersistence.dataFilepath(directory, filename: filename)
        if let filepath = dataFilepath.filepath {

            do {

                try NSFileManager.defaultManager().removeItemAtPath(filepath)

                return (nil, true)

            } catch {

                return (error as NSError, false)

            }


        }

        return (dataFilepath.error, false)
    }

    // MARK: Helper Methods

    private class func directoryURL(directory: NSSearchPathDirectory) -> (url: NSURL?, error: NSError?, success: Bool) {

        do {
            let fileDirectory = try NSFileManager.defaultManager().URLForDirectory(directory, inDomain: .UserDomainMask, appropriateForURL: nil, create: false)

            return (fileDirectory, nil, true)

        } catch {
            return (nil, error as NSError, false)
        }

    }

    private class func dataFilepath(directory: NSSearchPathDirectory, filename: String) -> (filepath: String?, error: NSError?, success: Bool) {
        let directoryURL = DataPersistence.directoryURL(directory)
        let filepath = (directoryURL.url?.URLByAppendingPathComponent(filename).path)!

        //if NSFileManager.defaultManager().fileExistsAtPath(filepath) {
            return (filepath, nil, true)
        //}

        //let error = NSError(domain: DataPersistenceErrorDomain, code: -1, userInfo: nil)
        //return (nil, error, false)
    }

}
