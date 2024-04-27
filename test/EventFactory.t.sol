// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../contracts/EventFactory.sol";

contract EventFactoryTest is Test {
    EventFactory public eventFactory;
    address public organizer;
    address public buyer;
    uint256 testEventId = 1;
    uint256[] testEventIds = [1, 2];
    uint256[] testAmounts = [100, 20];
    uint256[] testBuyEventId = [1, 2];
    uint256[] testBuyAmount = [5, 5];

    function setUp() public {
        eventFactory = new EventFactory();
        organizer = address(1);
        buyer = address(2);
    }

    function testCreateNewEvent() public {
        // Test event creation
        eventFactory.createNewEvent(
            "Event Name",
            "Event Description",
            "Event Address",
            1000000,
            2000000,
            3000000,
            true,
            false
        );

        // Verify event creation event emitted
        assertEq(eventFactory.getEventDetails(1).eventId, 1);
        assertEq(eventFactory.getEventDetails(1).eventName, "Event Name");
        assertEq(eventFactory.getEventDetails(1).organizer, address(this));
    }

    function testAddEventOrganizer() public {
        // Create a new event
        eventFactory.createNewEvent(
            "Event Name",
            "Event Description",
            "Event Address",
            1000000,
            2000000,
            3000000,
            true,
            false
        );

        // Add a new organizer
        eventFactory.addEventOrganizer(1, address(2));

        // Verify organizer added event emitted
        assertEq(
            eventFactory.hasRole(
                keccak256(abi.encodePacked("EVENT_ORGANIZER", testEventId)),
                address(2)
            ),
            true
        );
    }

    function testRemoveOrganizer() public {
        // Create a new event
        eventFactory.createNewEvent(
            "Event Name",
            "Event Description",
            "Event Address",
            1000000,
            2000000,
            3000000,
            true,
            false
        );

        // Add a new organizer
        eventFactory.addEventOrganizer(1, address(2));

        // Remove the organizer
        eventFactory.removeOrganizer(1, address(2));

        // Verify organizer removed event emitted
        assertEq(
            eventFactory.hasRole(
                keccak256(abi.encodePacked("EVENT_ORGANIZER", testEventId)),
                address(2)
            ),
            false
        );
    }

    function testRescheduleEvent() public {
        // Create a new event
        eventFactory.createNewEvent(
            "Event Name",
            "Event Description",
            "Event Address",
            1000000,
            2000000,
            3000000,
            true,
            false
        );

        // Reschedule the event
        eventFactory.rescheduleEvent(1, 4000000, 5000000, 6000000, true, false);

        // Verify event rescheduled event emitted
        assertEq(eventFactory.getEventDetails(1).date, 4000000);
        assertEq(eventFactory.getEventDetails(1).startTime, 5000000);
        assertEq(eventFactory.getEventDetails(1).endTime, 6000000);
    }

    function testCancelEvent() public {
        // Create a new event
        eventFactory.createNewEvent(
            "Event Name",
            "Event Description",
            "Event Address",
            1000000,
            2000000,
            3000000,
            true,
            false
        );

        // Cancel the event
        eventFactory.cancelEvent(1);

        // Verify event cancelled event emitted
        assertEq(eventFactory.getEventDetails(1).isCancelled, true);
    }

    function testCreateEventTicket() public {
        // Create a new event
        eventFactory.createNewEvent(
            "Event Name",
            "Event Description",
            "Event Address",
            1000000,
            2000000,
            3000000,
            true,
            false
        );

        // Create event tickets
        eventFactory.createEventTicket(1, testEventIds, testAmounts);

        // Verify event tickets created
        assertEq(eventFactory.getEventDetails(1).totalTickets, 120);
    }

    function testBuyTicket() public {
        // Create a new event
        eventFactory.createNewEvent(
            "Event Name",
            "Event Description",
            "Event Address",
            1000000,
            2000000,
            3000000,
            true,
            false
        );

        // Create event tickets
        eventFactory.createEventTicket(1, testEventIds, testAmounts);

        // Buy event tickets
        eventFactory.buyTicket(1, testBuyEventId, testBuyAmount, address(56));

        // Verify event tickets purchased
        assertEq(eventFactory.getEventDetails(1).soldTickets, 10);

        // Verify event ticket in buyer account
        assertEq(eventFactory.balanceOfTickets(1, address(56), 1), 5);
    }
}
