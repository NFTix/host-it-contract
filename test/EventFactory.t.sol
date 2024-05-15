// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.25;

import "forge-std/Test.sol";
import "../contracts/EventFactory.sol";

contract EventFactoryTest is Test {
    EventFactory eventFactory;
    uint256 testEventId = 0;
    uint256[] testEventIds = [1, 2];
    uint256[] testQuantity = [100, 20];
    uint256[] testPrice = [10, 100];
    uint256[] testBuyQuantity = [5, 5];
    uint256[] testBuyPrice = [50, 500];

    function setUp() public {
        eventFactory = new EventFactory();
        eventFactory.registerENS(address(this), "", "");
        eventFactory.createNewEvent(
            "Event 1",
            "Event 1 Description",
            "Event 1 Address",
            1000000,
            2000000,
            3000000,
            true,
            false
        );

        eventFactory.createNewEvent(
            "Event 2",
            "Event 2 Description",
            "Event 2 Address",
            1000000,
            2000000,
            3000000,
            false,
            true
        );
    }

    function testCreateNewEvent() public view {
        // Verify event creation 1
        assertEq(eventFactory.getEventDetails(0).eventId, 0);
        assertEq(eventFactory.getEventDetails(0).eventName, "Event 1");
        assertEq(eventFactory.getEventDetails(0).organizer, address(this));

        // Verify event creation 2
        assertEq(eventFactory.getEventDetails(1).eventId, 1);
        assertEq(eventFactory.getEventDetails(1).eventName, "Event 2");
        assertEq(eventFactory.getEventDetails(1).organizer, address(this));
    }

    function testAddEventOrganizer() public {
        // Add a new organizer
        eventFactory.addEventOrganizer(0, address(2));

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
        // Add a new organizer
        eventFactory.addEventOrganizer(0, address(2));

        // Remove the organizer
        eventFactory.removeOrganizer(0, address(2));

        // Verify organizer removed event emitted
        assertEq(
            eventFactory.hasRole(
                keccak256(abi.encodePacked("EVENT_ORGANIZER", testEventId)),
                address(2)
            ),
            false
        );
    }

    function testUpdateEvent() public {
        // Update the event
        eventFactory.updateEvent(
            0,
            "New Event Name",
            "New Event Description",
            "New Event Address",
            2000000,
            5000000,
            6000000,
            false,
            true
        );

        // Verify event updated event emitted
        assertEq(eventFactory.getEventDetails(0).eventName, "New Event Name");
        assertEq(
            eventFactory.getEventDetails(0).description,
            "New Event Description"
        );
        assertEq(
            eventFactory.getEventDetails(0).eventAddress,
            "New Event Address"
        );
        assertEq(eventFactory.getEventDetails(0).date, 2000000);
        assertEq(eventFactory.getEventDetails(0).startTime, 5000000);
        assertEq(eventFactory.getEventDetails(0).endTime, 6000000);
        assertEq(eventFactory.getEventDetails(0).virtualEvent, false);
        assertEq(eventFactory.getEventDetails(0).privateEvent, true);
    }

    function testCancelEvent() public {
        // Cancel the event
        eventFactory.cancelEvent(0);

        // Verify event cancelled event emitted
        assertEq(eventFactory.getEventDetails(0).isCancelled, true);
    }

    function testCreateEventTicket() public {
        // Create event tickets
        eventFactory.createEventTicket(
            0,
            testEventIds,
            testQuantity,
            testPrice
        );

        // Verify event tickets created
        assertEq(eventFactory.totalSupplyAllTickets(0), 120);
    }

    function testBuyTicket() public {
        testCreateEventTicket();

        vm.startPrank(address(1));
        // deal
        deal(address(1), 1000);

        eventFactory.registerENS(address(1), "", "");

        // Buy event tickets
        (bool ok, ) = address(eventFactory).call{value: 550}(
            abi.encodeWithSignature(
                "buyTicket(uint256,uint256[],uint256[])",
                0,
                testEventIds,
                testBuyQuantity
            )
        );
        assert(ok);

        vm.stopPrank();

        // Verify event tickets purchased
        assertEq(eventFactory.getEventDetails(0).soldTickets, 10);
        // assertEq(eventFactory.getEventDetails(2).soldTickets, 10);

        // Verify event ticket in buyer account
        assertEq(eventFactory.balanceOfTickets(0, address(1), 1), 5);
        assertEq(eventFactory.balanceOfTickets(0, address(1), 2), 5);
        // assertEq(eventFactory.balanceOfTickets(1, address(2), 1), 5);
        // assertEq(eventFactory.balanceOfTickets(1, address(2), 2), 5);
        // assertEq(eventFactory.balanceOfTickets(2, address(1), 1), 5);
    }
}