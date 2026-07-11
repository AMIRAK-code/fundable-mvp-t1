import Foundation
import HealthKit

/// Bridges to Apple Health (the data layer behind Apple Fitness):
/// - reads today's active energy and exercise minutes for the dashboard
/// - writes completed craving breathing exercises as mindful sessions
final class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()

    private let store = HKHealthStore()

    @Published var isAuthorized = false
    @Published var todayActiveEnergy: Double?
    @Published var todayExerciseMinutes: Double?

    private init() {}

    func requestAccess() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard
            let energy = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned),
            let exercise = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime),
            let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession)
        else { return }

        let readTypes: Set<HKObjectType> = [energy, exercise]
        let shareTypes: Set<HKSampleType> = [mindful]

        store.requestAuthorization(toShare: shareTypes, read: readTypes) { [weak self] success, _ in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.refresh()
                }
            }
        }
    }

    func refresh() {
        fetchTodaySum(.activeEnergyBurned, unit: .kilocalorie()) { [weak self] value in
            self?.todayActiveEnergy = value
        }
        fetchTodaySum(.appleExerciseTime, unit: .minute()) { [weak self] value in
            self?.todayExerciseMinutes = value
        }
    }

    /// Saves a completed breathing exercise as a mindful session.
    func logMindfulSession(start: Date, end: Date) {
        guard HKHealthStore.isHealthDataAvailable(),
              let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession),
              end > start
        else { return }
        let sample = HKCategorySample(
            type: mindful,
            value: HKCategoryValue.notApplicable.rawValue,
            start: start,
            end: end
        )
        store.save(sample) { _, _ in }
    }

    private func fetchTodaySum(
        _ identifier: HKQuantityTypeIdentifier,
        unit: HKUnit,
        completion: @escaping (Double?) -> Void
    ) {
        guard let type = HKQuantityType.quantityType(forIdentifier: identifier) else { return }
        let start = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date(), options: .strictStartDate)
        let query = HKStatisticsQuery(
            quantityType: type,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, statistics, _ in
            let value = statistics?.sumQuantity()?.doubleValue(for: unit)
            DispatchQueue.main.async {
                completion(value)
            }
        }
        store.execute(query)
    }
}
