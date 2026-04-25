/*
 DashpadAppIntentsTests.swift
 
 ⚠️ IMPORTANT: This file should be added to your TEST TARGET, not the main app target.
 
 To use these tests:
 1. In Xcode, right-click this file in the Project Navigator
 2. Select "Delete" → "Remove Reference" (don't move to trash)
 3. Create a new Test Target if you don't have one:
    - File → New → Target → Unit Testing Bundle
 4. Add this file to the test target
 
 Alternatively, you can use XCTest instead of Swift Testing if you prefer.
 See below for XCTest versions of these tests.
*/

// MARK: - Swift Testing Version (iOS 16+, requires test target)

#if false // Remove this #if to enable when in test target

import Testing
import AppIntents
@testable import Dashpad

// MARK: - App Intents Tests

@Suite("App Intents Tests")
struct DashpadAppIntentsTests {
    
    @Test("Quick Add Intent creates item")
    func testQuickAddIntent() async throws {
        let store = DashStore.shared
        let initialCount = store.items.count
        
        let intent = QuickAddDashItemIntent()
        intent.text = "Test reminder"
        
        let result = try await intent.perform()
        
        #expect(store.items.count == initialCount + 1)
        let addedItem = store.items.last
        #expect(addedItem?.title == "Test reminder")
    }
    
    @Test("Quick Add Intent parses dates")
    func testQuickAddIntentWithDate() async throws {
        let store = DashStore.shared
        
        let intent = QuickAddDashItemIntent()
        intent.text = "Call mom tomorrow at 3pm"
        
        let result = try await intent.perform()
        
        let addedItem = store.items.last
        #expect(addedItem?.title == "Call mom")
        #expect(addedItem?.dueDate != nil)
    }
    
    @Test("Add Item Intent with tags")
    func testAddItemWithTags() async throws {
        let store = DashStore.shared
        let initialCount = store.items.count
        
        let intent = AddDashItemIntent()
        intent.title = "Buy groceries"
        intent.tags = ["shopping", "urgent"]
        intent.dueDate = nil
        
        let result = try await intent.perform()
        
        #expect(store.items.count == initialCount + 1)
        let addedItem = store.items.last
        #expect(addedItem?.title == "Buy groceries")
        #expect(addedItem?.tags == ["shopping", "urgent"])
    }
    
    @Test("Add Item Intent with due date")
    func testAddItemWithDueDate() async throws {
        let store = DashStore.shared
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let intent = AddDashItemIntent()
        intent.title = "Dentist appointment"
        intent.tags = []
        intent.dueDate = tomorrow
        
        let result = try await intent.perform()
        
        let addedItem = store.items.last
        #expect(addedItem?.title == "Dentist appointment")
        #expect(addedItem?.dueDate != nil)
    }
    
    @Test("View Recent Items Intent")
    func testViewRecentItems() async throws {
        let store = DashStore.shared
        
        // Add some test items
        for i in 1...3 {
            let item = DashItem(title: "Test item \(i)")
            store.add(item)
        }
        
        let intent = ViewRecentDashItemsIntent()
        intent.limit = 2
        
        let result = try await intent.perform()
        let entities = try result.wrappedValue()
        
        #expect(entities.count <= 2)
    }
    
    @Test("Complete Item Intent")
    func testCompleteItem() async throws {
        let store = DashStore.shared
        
        // Add a test item
        let item = DashItem(title: "Test completion")
        store.add(item)
        
        // Create entity from the item
        let entity = DashItemEntity(item: item)
        
        let intent = CompleteDashItemIntent()
        intent.item = entity
        
        let result = try await intent.perform()
        
        // Verify item is completed
        let completedItem = store.items.first(where: { $0.id == item.id })
        #expect(completedItem?.isComplete == true)
    }
    
    @Test("Entity Query returns correct items")
    func testEntityQuery() async throws {
        let store = DashStore.shared
        
        // Add test items
        let item1 = DashItem(title: "Item 1")
        let item2 = DashItem(title: "Item 2")
        store.add(item1)
        store.add(item2)
        
        let query = DashItemQuery()
        let entities = try await query.entities(for: [item1.id.uuidString, item2.id.uuidString])
        
        #expect(entities.count == 2)
        #expect(entities.contains(where: { $0.title == "Item 1" }))
        #expect(entities.contains(where: { $0.title == "Item 2" }))
    }
    
    @Test("Suggested entities returns recent items")
    func testSuggestedEntities() async throws {
        let store = DashStore.shared
        
        // Clear and add test items
        for i in 1...10 {
            let item = DashItem(title: "Item \(i)")
            store.add(item)
        }
        
        let query = DashItemQuery()
        let suggested = try await query.suggestedEntities()
        
        #expect(suggested.count <= 5) // Should limit to 5
        #expect(suggested.allSatisfy { !$0.isComplete }) // All incomplete
    }
}

// MARK: - Integration Tests

@Suite("App Intents Integration Tests")
struct DashpadIntentsIntegrationTests {
    
    @Test("Action Button workflow simulation")
    func testActionButtonWorkflow() async throws {
        // Simulate the Action Button → Quick Add workflow
        
        // User presses Action Button
        // iOS prompts: "What do you need to remember?"
        // User says: "Buy milk tomorrow"
        
        let userInput = "Buy milk tomorrow"
        
        let intent = QuickAddDashItemIntent()
        intent.text = userInput
        
        let result = try await intent.perform()
        
        let store = DashStore.shared
        let addedItem = store.items.last
        
        #expect(addedItem?.title == "Buy milk")
        #expect(addedItem?.dueDate != nil)
        
        // Cleanup
        if let item = addedItem {
            store.delete(item)
        }
    }
    
    @Test("Siri workflow with tags")
    func testSiriWorkflowWithTags() async throws {
        // Simulate: "Add 'Review code' to Dashpad"
        
        let intent = AddDashItemIntent()
        intent.title = "Review code"
        intent.tags = ["work", "urgent"]
        intent.dueDate = nil
        
        let result = try await intent.perform()
        
        let store = DashStore.shared
        let addedItem = store.items.last
        
        #expect(addedItem?.title == "Review code")
        #expect(addedItem?.tags.contains("work") == true)
        #expect(addedItem?.tags.contains("urgent") == true)
        
        // Cleanup
        if let item = addedItem {
            store.delete(item)
        }
    }
    
    @Test("Multiple rapid additions")
    func testRapidAdditions() async throws {
        let store = DashStore.shared
        let initialCount = store.items.count
        
        // Simulate rapid Action Button usage
        for i in 1...5 {
            let intent = QuickAddDashItemIntent()
            intent.text = "Quick item \(i)"
            _ = try await intent.perform()
        }
        
        #expect(store.items.count == initialCount + 5)
    }
}

// MARK: - Performance Tests

@Suite("App Intents Performance Tests")
struct DashpadIntentsPerformanceTests {
    
    @Test("Quick Add performance")
    func testQuickAddPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let intent = QuickAddDashItemIntent()
        intent.text = "Performance test item"
        _ = try await intent.perform()
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete in less than 100ms
        #expect(timeElapsed < 0.1)
    }
    
    @Test("Entity query performance with many items")
    func testEntityQueryPerformance() async throws {
        let store = DashStore.shared
        
        // Add 100 items
        for i in 1...100 {
            store.add(DashItem(title: "Item \(i)"))
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let query = DashItemQuery()
        _ = try await query.suggestedEntities()
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        // Should complete in less than 50ms even with 100 items
        #expect(timeElapsed < 0.05)
    }
}
#endif // End Swift Testing version

// MARK: - XCTest Version (Alternative - works in test target without Swift Testing)

/*
 If you prefer to use XCTest instead of Swift Testing, copy this version into your test target.
 XCTest is more widely supported and doesn't require iOS 16+.
*/

#if false // Remove this #if to enable when in test target

import XCTest
import AppIntents
@testable import Dashpad

final class DashpadAppIntentsTests: XCTestCase {
    
    func testQuickAddIntent() async throws {
        let store = DashStore.shared
        let initialCount = store.items.count
        
        let intent = QuickAddDashItemIntent()
        intent.text = "Test reminder"
        
        _ = try await intent.perform()
        
        XCTAssertEqual(store.items.count, initialCount + 1)
        let addedItem = store.items.last
        XCTAssertEqual(addedItem?.title, "Test reminder")
    }
    
    func testQuickAddIntentWithDate() async throws {
        let store = DashStore.shared
        
        let intent = QuickAddDashItemIntent()
        intent.text = "Call mom tomorrow at 3pm"
        
        _ = try await intent.perform()
        
        let addedItem = store.items.last
        XCTAssertEqual(addedItem?.title, "Call mom")
        XCTAssertNotNil(addedItem?.dueDate)
    }
    
    func testAddItemWithTags() async throws {
        let store = DashStore.shared
        let initialCount = store.items.count
        
        let intent = AddDashItemIntent()
        intent.title = "Buy groceries"
        intent.tags = ["shopping", "urgent"]
        intent.dueDate = nil
        
        _ = try await intent.perform()
        
        XCTAssertEqual(store.items.count, initialCount + 1)
        let addedItem = store.items.last
        XCTAssertEqual(addedItem?.title, "Buy groceries")
        XCTAssertEqual(addedItem?.tags, ["shopping", "urgent"])
    }
    
    func testAddItemWithDueDate() async throws {
        let store = DashStore.shared
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        
        let intent = AddDashItemIntent()
        intent.title = "Dentist appointment"
        intent.tags = []
        intent.dueDate = tomorrow
        
        _ = try await intent.perform()
        
        let addedItem = store.items.last
        XCTAssertEqual(addedItem?.title, "Dentist appointment")
        XCTAssertNotNil(addedItem?.dueDate)
    }
    
    func testViewRecentItems() async throws {
        let store = DashStore.shared
        
        // Add some test items
        for i in 1...3 {
            let item = DashItem(title: "Test item \(i)")
            store.add(item)
        }
        
        let intent = ViewRecentDashItemsIntent()
        intent.limit = 2
        
        let result = try await intent.perform()
        let entities = result.value as! [DashItemEntity]
        
        XCTAssertLessThanOrEqual(entities.count, 2)
    }
    
    func testCompleteItem() async throws {
        let store = DashStore.shared
        
        // Add a test item
        let item = DashItem(title: "Test completion")
        store.add(item)
        
        // Create entity from the item
        let entity = DashItemEntity(item: item)
        
        let intent = CompleteDashItemIntent()
        intent.item = entity
        
        _ = try await intent.perform()
        
        // Verify item is completed
        let completedItem = store.items.first(where: { $0.id == item.id })
        XCTAssertTrue(completedItem?.isComplete == true)
    }
    
    func testEntityQuery() async throws {
        let store = DashStore.shared
        
        // Add test items
        let item1 = DashItem(title: "Item 1")
        let item2 = DashItem(title: "Item 2")
        store.add(item1)
        store.add(item2)
        
        let query = DashItemQuery()
        let entities = try await query.entities(for: [item1.id.uuidString, item2.id.uuidString])
        
        XCTAssertEqual(entities.count, 2)
        XCTAssertTrue(entities.contains(where: { $0.title == "Item 1" }))
        XCTAssertTrue(entities.contains(where: { $0.title == "Item 2" }))
    }
    
    func testSuggestedEntities() async throws {
        let store = DashStore.shared
        
        // Clear and add test items
        for i in 1...10 {
            let item = DashItem(title: "Item \(i)")
            store.add(item)
        }
        
        let query = DashItemQuery()
        let suggested = try await query.suggestedEntities()
        
        XCTAssertLessThanOrEqual(suggested.count, 5)
        XCTAssertTrue(suggested.allSatisfy { !$0.isComplete })
    }
}

final class DashpadIntentsIntegrationTests: XCTestCase {
    
    func testActionButtonWorkflow() async throws {
        let userInput = "Buy milk tomorrow"
        
        let intent = QuickAddDashItemIntent()
        intent.text = userInput
        
        _ = try await intent.perform()
        
        let store = DashStore.shared
        let addedItem = store.items.last
        
        XCTAssertEqual(addedItem?.title, "Buy milk")
        XCTAssertNotNil(addedItem?.dueDate)
        
        // Cleanup
        if let item = addedItem {
            store.delete(item)
        }
    }
    
    func testSiriWorkflowWithTags() async throws {
        let intent = AddDashItemIntent()
        intent.title = "Review code"
        intent.tags = ["work", "urgent"]
        intent.dueDate = nil
        
        _ = try await intent.perform()
        
        let store = DashStore.shared
        let addedItem = store.items.last
        
        XCTAssertEqual(addedItem?.title, "Review code")
        XCTAssertTrue(addedItem?.tags.contains("work") == true)
        XCTAssertTrue(addedItem?.tags.contains("urgent") == true)
        
        // Cleanup
        if let item = addedItem {
            store.delete(item)
        }
    }
    
    func testMultipleRapidAdditions() async throws {
        let store = DashStore.shared
        let initialCount = store.items.count
        
        for i in 1...5 {
            let intent = QuickAddDashItemIntent()
            intent.text = "Quick item \(i)"
            _ = try await intent.perform()
        }
        
        XCTAssertEqual(store.items.count, initialCount + 5)
    }
}

final class DashpadIntentsPerformanceTests: XCTestCase {
    
    func testQuickAddPerformance() async throws {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let intent = QuickAddDashItemIntent()
        intent.text = "Performance test item"
        _ = try await intent.perform()
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(timeElapsed, 0.1, "Should complete in less than 100ms")
    }
    
    func testEntityQueryPerformance() async throws {
        let store = DashStore.shared
        
        // Add 100 items
        for i in 1...100 {
            store.add(DashItem(title: "Item \(i)"))
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        let query = DashItemQuery()
        _ = try await query.suggestedEntities()
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(timeElapsed, 0.05, "Should complete in less than 50ms")
    }
}

#endif // End XCTest version

// MARK: - Manual Testing Guide

/*
 MANUAL TESTING CHECKLIST
 ========================
 
 Since App Intents work best when tested in the actual Shortcuts app and with Siri,
 here's a manual testing guide:
 
 □ Build and run the app at least once
 □ Open Shortcuts app
 □ Verify "Quick Add to Dashpad" appears
 □ Verify "Add to Dashpad" appears
 □ Verify "View Recent Dashpad Items" appears
 
 □ Test Quick Add:
   - Create a shortcut using "Quick Add to Dashpad"
   - Run it with text: "Test item"
   - Verify item appears in app
 
 □ Test with dates:
   - Run Quick Add with: "Meeting tomorrow at 3pm"
   - Verify date is parsed correctly in app
 
 □ Test with Siri:
   - Say "Add to Dashpad"
   - Siri should prompt for text
   - Provide text and verify it's added
 
 □ Test Action Button (iPhone 15 Pro+):
   - Settings → Action Button → Shortcut
   - Choose "Quick Add to Dashpad"
   - Press Action Button
   - Speak/type text
   - Verify item is added
 
 □ Test View Items:
   - Run "View Recent Dashpad Items"
   - Verify it returns your incomplete items
 
 □ Test Complete Item:
   - Create shortcut to complete an item
   - Run it and verify item is marked complete
 
 □ Test data persistence:
   - Add item via shortcut
   - Open app
   - Verify item appears
   - Close app
   - Add another item via shortcut
   - Reopen app
   - Verify both items exist
 
 □ Test tag suggestions:
   - Add item with text that should trigger tags
   - Verify appropriate tags are suggested/applied
 
 □ Test error handling:
   - Try to complete a non-existent item
   - Verify graceful error message
 
 PERFORMANCE TESTING
 ===================
 
 □ Time Action Button → Item Added:
   - Should be under 1 second
 
 □ Test with 100+ items:
   - Verify shortcuts still run quickly
   - Verify app doesn't slow down
 
 EDGE CASES
 ==========
 
 □ Empty text
 □ Very long text (1000+ characters)
 □ Special characters in text
 □ Multiple dates in one text
 □ Conflicting tags
 □ App in background vs foreground
 □ Low memory conditions
 □ Airplane mode (should still work - on-device)
 
*/

