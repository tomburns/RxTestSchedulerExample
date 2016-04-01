//
//  DriverStuff.swift
//  RxSwift
//
//  Created by Tom Burns on 3/31/16.
//
//

import Foundation
import RxSwift
import RxCocoa


class ThingViewModel {

    let ints: Driver<[Int]>
    let active = Variable(false)

    let maybeString = Variable<String?>(.None)

    private let scheduler: SchedulerType

    init(scheduler: SchedulerType = SerialDispatchQueueScheduler(globalConcurrentQueueQOS: DispatchQueueSchedulerQOS.UserInitiated)) {

        self.scheduler = scheduler

        let refreshTrigger: Observable<Void> = active.asObservable()
            .distinctUntilChanged()
            .filter { $0 }
            .map { _ in return }.debug("refreshTrigger")

        ints = refreshTrigger
            .flatMapLatest { _ -> Observable<[Int]> in
                let random = Int(arc4random_uniform(30))
                return Observable.just([0,random,-2])
            }.debug("before ints")
            .observeOn(scheduler)
            .map { ints in
                return ints.map { $0 * -1 }
            }
            .asDriver(onErrorJustReturn: []).debug("after ints")
    }

    lazy private(set) var isBookable: Driver<Bool> = {

        let hasInts = self.ints
            .map { $0.count > 0 }.debug("has ints")

        // isBookable should always emit false right after we set a new sitter,
        // until we receive availability data from the Observable above.
        let justSwappedStrings = self.maybeString.asDriver().debug("new string")
            .map { _ in false }

        return Driver.of(hasInts, justSwappedStrings).merge()
    }()
}