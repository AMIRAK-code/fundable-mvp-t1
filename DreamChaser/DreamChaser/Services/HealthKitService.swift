import Foundation
import HealthKit
import Observation

/// Read-only Apple Health bridge for the Wellbeing tab: today's steps,
/// active energy, exercise minutes, and last night's sleep.
@MainActor
@Observable
final class HealthKitService {
    var steps: Double = 0
    var activeEnergy: Double = 0
    var exerciseMinutes: Double = 0
    var sleepHours: Double = 0
    var hasRequestedAccess = false

    private let store = HKHealthStore()

    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func requestAuthorization() async {
        guard isAvailable else { return }
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.appleExerciseTime),
            HKCategoryType(.sleepAnalysis),
        ]
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            hasRequestedAccess = true
            await refresh()
        } catch {
            hasRequestedAccess = false
        }
    }

    func refresh() async {
        guard isAvailable else { return }
        steps = await todaySum(.stepCount, unit: .count())
        activeEnergy = await todaySum(.activeEnergyBurned, unit: .kilocalorie())
        exerciseMinutes = await todaySum(.appleExerciseTime, unit: .minute())
        sleepHours = await lastNightSleepHours()
        if sleepHours > 0 {
            // Widgets and the momentum score read this cache.
            MomentumEngine.cacheSleep(hours: sleepHours)
        }
    }

    /// Rough average nightly sleep over the past `days` days, for the weekly
    /// review. Sums asleep time in the window and divides by the night count.
    func sleepAverageHours(days: Int) async -> Double? {
        guard isAvailable, days > 0 else { return nil }
        let type = HKCategoryType(.sleepAnalysis)
        let start = Calendar.current.date(byAdding: .day, value: -days, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        let total: Double = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let asleepSeconds = (samples as? [HKCategorySample] ?? [])
                    .filter { sample in
                        guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return false }
                        return HKCategoryValueSleepAnalysis.allAsleepValues.contains(value)
                    }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: asleepSeconds / 3600)
            }
            store.execute(query)
        }
        return total > 0 ? total / Double(days) : nil
    }

    private func todaySum(_ identifier: HKQuantityTypeIdentifier, unit: HKUnit) async -> Double {
        let type = HKQuantityType(identifier)
        let start = Calendar.current.startOfDay(for: .now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, statistics, _ in
                continuation.resume(returning: statistics?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    private func lastNightSleepHours() async -> Double {
        let type = HKCategoryType(.sleepAnalysis)
        let start = Calendar.current.date(byAdding: .hour, value: -18, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let asleepSeconds = (samples as? [HKCategorySample] ?? [])
                    .filter { sample in
                        guard let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) else { return false }
                        return HKCategoryValueSleepAnalysis.allAsleepValues.contains(value)
                    }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: asleepSeconds / 3600)
            }
            store.execute(query)
        }
    }
}
