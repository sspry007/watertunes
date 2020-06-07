//
//  HealthManager.swift
//  watertunes
//
//  Created by Steven Spry on 6/3/20.
//  Copyright © 2020 Steven Spry. All rights reserved.
//

import Foundation
import HealthKit

enum HealthkitSetupError: Error {
  case notAvailableOnDevice
  case dataTypeNotAvailable
}

let healthUpdateDidComplete = "healthUpdateDidComplete"

class HealthManager {

    private let healthStore = HKHealthStore()
    var bodyWeight:Double = 0.0
    var water:Double = 0.0
    var dailyGoal:Int = 0

    static let shared: HealthManager = {
        let instance = HealthManager()

        instance.setup()
        return instance
    }()
    
    var goalPerPound:Double {
        get {
            if let _ = UserDefaults.standard.object(forKey: "goalPerPound") {
                let goalPerPound = UserDefaults.standard.double(forKey: "goalPerPound")
                return Double(goalPerPound)
            } else {
                let goalPerPound = 0.75
                UserDefaults.standard.set(goalPerPound, forKey: "goalPerPound")
                return goalPerPound
            }
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "goalPerPound")
            self.dailyGoal = Int(self.bodyWeight * newValue)

            NotificationCenter.default.post(name: NSNotification.Name(rawValue: healthUpdateDidComplete),object: nil,userInfo: nil)
        }
        
    }
    
    
    func authorizeHealthKit(completion: @escaping (Bool, Error?) -> ()) {
        
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, HealthkitSetupError.notAvailableOnDevice)
            return
        }

        guard   let dietaryWater = HKObjectType.quantityType(forIdentifier: .dietaryWater),
                let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass)
            else {
                completion(false, HealthkitSetupError.dataTypeNotAvailable)
                return
        }
        
        let healthKitTypesToWrite: Set<HKSampleType> = [dietaryWater]
        let healthKitTypesToRead: Set<HKObjectType> = [dietaryWater,bodyMass]
        
        healthStore.requestAuthorization(toShare: healthKitTypesToWrite, read: healthKitTypesToRead) { (success, error) in

            completion(success, error)
        }
    }
    
    
    func getHealthData() {
        
        let group = DispatchGroup()

        guard let weightSampleType = HKSampleType.quantityType(forIdentifier: .bodyMass) else {
            print("Body Mass Sample is no longer available")
            return
        }
        
        group.enter()
        HealthManager.shared.getMostRecentSample(for: weightSampleType) { [weak self] (sample, error) in
            guard let sample = sample else { return }
            
            guard let strongSelf = self else { return }

            strongSelf.bodyWeight = sample.quantity.doubleValue(for: HKUnit.pound())
            strongSelf.dailyGoal = Int(strongSelf.bodyWeight * strongSelf.goalPerPound)
            group.leave()
        }
        
        group.enter()
        guard let waterData = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        HealthManager.shared.getTodaySamples(for: waterData) { [weak self] (samples, error) in
         
            guard let samples = samples else {
                group.leave()
                return
            }
            
            guard let strongSelf = self else {
                group.leave()
                return
            }
            
            let qty = samples.map({$0.quantity.doubleValue(for: HKUnit.fluidOunceUS())}).reduce(0, +)

            strongSelf.water = qty
            group.leave()
        }
        
        group.notify(queue: .main) {
            DispatchQueue.main.async(execute: {
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: healthUpdateDidComplete),object: nil,userInfo: nil)
            })
        }
    }
    
    func saveWater(value: Double) {
        guard let waterData = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else { return }
        
        HealthManager.shared.saveSample(sampleType: waterData, unit: .fluidOunceUS(), value: value, date: Date())
        
        getHealthData()
    }
    
    private func saveSample(sampleType: HKQuantityType, unit:HKUnit , value: Double, date: Date) {
        
        let sampleQuantity = HKQuantity(unit: unit, doubleValue: value)
      
        let sample = HKQuantitySample(type: sampleType,
                                      quantity: sampleQuantity,
                                      start: date,
                                      end: date)
        healthStore.save(sample) { (success, error) in
            if let error = error {
              print("Error Saving Sample: \(error.localizedDescription)")
            } else {
              print("Successfully saved Sample")
            }
      }
    }
    
    private func getMostRecentSample(for sampleType: HKSampleType, completion: @escaping (HKQuantitySample?, Error?) -> ()) {
      
      let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                            end: Date(),
                                                            options: .strictEndDate)
      let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                            ascending: false)
      let limit = 50
      
      let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                      predicate: mostRecentPredicate,
                                      limit: limit,
                                      sortDescriptors: [sortDescriptor]) { (query, samples, error) in
      
        DispatchQueue.main.async {
            guard let samples = samples,
                let mostRecentSample = samples.first as? HKQuantitySample else {
                  
                completion(nil, error)
                return
            }
            completion(mostRecentSample, nil)
        }
      }
      healthStore.execute(sampleQuery)
    }
    
    private func getTodaySamples(for sampleType: HKQuantityType, completion: @escaping ([HKQuantitySample]?, Error?) -> ()) {
      
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: startOfDay(),
                                                            end: Date(),
                                                            options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                            ascending: false)
        let limit = 100
      
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                      predicate: mostRecentPredicate,
                                      limit: limit,
                                      sortDescriptors: [sortDescriptor]) { (query, samples, error) in
      
            DispatchQueue.main.async {
                guard let samples = samples else {
                    completion(nil, error)
                    return
                }
                completion(samples as? [HKQuantitySample], nil)
            }
      }
      healthStore.execute(sampleQuery)
    }
}

// MARK: - Private Instance methods
extension HealthManager {
    
    private func setup () {
        
    }
    
    private func startOfDay() -> Date {
        var calendar = NSCalendar.current
        calendar.timeZone = NSTimeZone.local as TimeZone
        let startDate = calendar.startOfDay(for: Date())
        return startDate
    }

    private func endOfDay() -> Date {
        var calendar = NSCalendar.current
        calendar.timeZone = NSTimeZone.local as TimeZone
        let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(60*60*24)
        return endDate
    }
}
