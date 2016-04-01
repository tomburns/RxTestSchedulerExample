//
//  Tests.swift
//  Tests
//
//  Created by Tom Burns on 3/31/16.
//
//

import XCTest

@testable import RxSwiftPlayground

import RxTests
import RxSwift
import RxCocoa
import RxBlocking
let resolution: NSTimeInterval = 0.2 // seconds

class Tests: XCTestCase {
    let disposeBag = DisposeBag()
    func testTest() {

        let scheduler = TestScheduler(initialClock: 0)

        let subject = ThingViewModel(scheduler: scheduler)

        subject.maybeString.value = "firstString"


        // expected behaviors:
        // 1. should send false whenever a new maybeString is set (analogous to setting sitter)
        // 2. setting active to true (if it was false) should trigger "refresh"
        //    (analogous to fetching schedule data), which will return true if the resulting
        //    array isn't empty (will never be empty in this simplified example)

        driveOnScheduler(scheduler) {

            let observer = scheduler.createObserver(Bool)

            scheduler.scheduleAt(50) {
                subject.isBookable
                    .asObservable()
                    .debug("isBookable asObservable")
                    .subscribe(observer)
                    .addDisposableTo(self.disposeBag)
            }

            scheduler.scheduleAt(100) {
                //simulate refresh avail
                subject.active.value = true
            }

            scheduler.scheduleAt(200) {
                // simulate deactivating and changing sitter
                subject.active.value = false
                subject.maybeString.value = "secondString"
            }

            scheduler.scheduleAt(250) {
                // activate & refresh avail
                subject.active.value = true
            }

            scheduler.start()

            XCTAssert(observer.events[0].value == .Next(false)) // the driver immediately sends false on subscribe.
            XCTAssert(observer.events[1].value == .Next(true)) // when active causes a "refresh", driver sends true
            XCTAssert(observer.events[2].value == .Next(false)) // the third event is emitted when the sitter is switched, immediately resulting in false
            XCTAssert(observer.events[3].value == .Next(true)) // active again causes a "refresh", landing us back at true
        }
    }
}