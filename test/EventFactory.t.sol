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
    uint256[] testQuantity = [100, 20];
    uint256[] testPrice = [10, 100];
    uint256[] testBuyQuantity = [5, 5];
    uint256[] testBuyPrice = [50, 500];

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

    function testUpdateEvent() public {
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

        // Update the event
        eventFactory.updateEvent(
            1,
            "New Event Name",
            "New Event Description",
            "New Event Address",
            2000000,
            3000000,
            4000000,
            false,
            true
        );

        // Verify event updated event emitted
        assertEq(eventFactory.getEventDetails(1).eventName, "New Event Name");
        assertEq(
            eventFactory.getEventDetails(1).description,
            "New Event Description"
        );
        assertEq(
            eventFactory.getEventDetails(1).eventAddress,
            "New Event Address"
        );
        assertEq(eventFactory.getEventDetails(1).date, 2000000);
        assertEq(eventFactory.getEventDetails(1).startTime, 3000000);
        assertEq(eventFactory.getEventDetails(1).endTime, 4000000);
        assertEq(eventFactory.getEventDetails(1).virtualEvent, false);
        assertEq(eventFactory.getEventDetails(1).privateEvent, true);
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
        eventFactory.createEventTicket(
            1,
            testEventIds,
            testQuantity,
            testPrice
        );

        // Verify event tickets created
        assertEq(eventFactory.totalSupplyAllTickets(1), 120);
    }

    function testBuyTicket() public {
        // Create a new event
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

        // Create event tickets
        eventFactory.createEventTicket(
            1,
            testEventIds,
            testQuantity,
            testPrice
        );
        eventFactory.createEventTicket(
            2,
            testEventIds,
            testQuantity,
            testPrice
        );

        // deal
        deal(address(1), 1000);
        deal(address(2), 1000);

        // Buy event tickets
        // (bool ok, bytes memory data) = address(this).call{value: 550}(eventFactory.buyTicket(1, testEventIds, testBuyQuantity, address(1)));
        (bool ok, bytes memory data) = address(eventFactory).call{value: 550}(
            abi.encodeWithSignature(
                "buyTicket(uint256,uint256[],uint256[],address)",
                1,
                testEventIds,
                testBuyQuantity,
                address(1)
            )
        );
        // (bool ok, bytes memory data) = address(eventFactory).call{value: 550}(
        //     abi.encodeWithSignature(
        //         "buyTicket(uint256,uint256[],uint256[],address)",
        //         1,
        //         testEventIds,
        //         testBuyQuantity,
        //         address(2)
        //     )
        // );
        // (bool ok, bytes memory data) = address(eventFactory).call{value: 550}(
        //     abi.encodeWithSignature(
        //         "buyTicket(uint256,uint256[],uint256[],address)",
        //         2,
        //         testEventIds,
        //         testBuyQuantity,
        //         address(1)
        //     )
        // );
        // eventFactory.buyTicket(1, testEventIds, testBuyQuantity, address(2));
        // eventFactory.buyTicket(2, testEventIds, testBuyQuantity, address(1));

        // Verify event tickets purchased
        assertEq(eventFactory.getEventDetails(1).soldTickets, 10);
        // assertEq(eventFactory.getEventDetails(2).soldTickets, 10);

        // Verify event ticket in buyer account
        assertEq(eventFactory.balanceOfTickets(1, address(1), 1), 5);
        // assertEq(eventFactory.balanceOfTickets(1, address(1), 2), 5);
        // assertEq(eventFactory.balanceOfTickets(1, address(2), 1), 5);
        // assertEq(eventFactory.balanceOfTickets(1, address(2), 2), 5);
        // assertEq(eventFactory.balanceOfTickets(2, address(1), 1), 5);
    }
}
