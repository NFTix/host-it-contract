// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import {
    ERC2771Context
} from "@gelatonetwork/relay-context/contracts/vendor/ERC2771Context.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./EventContract.sol";
import "./Registry.sol";
import "./Errors.sol";

/**
 * @title EventFactory
 * @author David <daveproxy80@gmail.com>
 * @author Manoah <manoahluka@gmail.com>
 * @author Olorunsogo <sogobanwo@gmail.com>
 * @notice This contract is a factory for creating and managing events
 * @dev This contract uses AccessControl and ReentrancyGuard from OpenZeppelin
 * @dev This contract uses AccessControl and ReentrancyGuard from OpenZeppelin
 */
contract EventFactory is AccessControl, ReentrancyGuard, Registry, ERC2771Context {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    /**
     * @dev Emitted when a new event is created
     * @param eventId The ID of the new event
     * @param eventNameE The name of the new event
     * @param organizer The address of the event organizer
     */
    event EventCreated(
        uint256 indexed eventId,
        string indexed eventNameE,
        address indexed organizer
    );

    /**
     * @dev Emitted when an event is rescheduled
     * @param eventId The ID of the rescheduled event
     * @param date The new date of the event
     * @param startTime The new start time of the event
     * @param endTime The new end time of the event
     * @param virtualEvent Whether the event is virtual
     * @param privateEvent Whether the event is private
     */
    event EventUpdated(
        uint256 indexed eventId,
        uint256 date,
        uint256 startTime,
        uint256 endTime,
        bool virtualEvent,
        bool privateEvent
    );

    /**
     * @dev Emitted when a ticket is purchased
     * @param buyer The address of the buyer
     * @param eventNameE The name of the event
     * @param eventId The ID of the event
     * @param ticketId The ID of the ticket
     */
    event TicketPurchased(
        address indexed buyer,
        string eventNameE,
        uint256 indexed eventId,
        uint256 indexed ticketId
    );

    /**
     * @dev Emitted when an event is cancelled
     * @param eventId The ID of the cancelled event
     */
    event EventCancelled(uint256 indexed eventId);

    /**
     * @dev Emitted when a new organizer is added to an event
     * @param eventId The ID of the event
     * @param newOrganizer The address of the new organizer
     */
    event AddOrganizer(uint256 indexed eventId, address indexed newOrganizer);

    /**
     * @dev Emitted when an organizer is removed from an event
     * @param eventId The ID of the event
     * @param newOrganizer The address of the removed organizer
     */
    event RemoveOrganizer(
        uint256 indexed eventId,
        address indexed newOrganizer
    );

    /*//////////////////////////////////////////////////////////////
                            EVENT FACTORY STORAGE
    //////////////////////////////////////////////////////////////*/
    uint256 eventId;
    EventContract[] events;
    mapping(uint256 => EventContract) eventMapping;
    mapping(address => EventContract[]) eventsCreatedByOrganizer;
    mapping(address => EventContract[]) boughtTicketsByUser;
    mapping(address => mapping(uint256 => EventContract[])) boughtTicketsByUserPerId;

    /*//////////////////////////////////////////////////////////////
                            EVENT FACTORY LOGIC
    //////////////////////////////////////////////////////////////*/
    constructor() ERC2771Context(0xd8253782c45a12053594b9deB72d8e8aB2Fca54c) {}
    /**
     * @dev Creates a new event
     * @param _eventName The name of the new event
     * @param _description The description of the new event
     * @param _eventAddress The address of the new event
     * @param _date The date of the new event
     * @param _startTime The start time of the new event
     * @param _endTime The end time of the new event
     * @param _virtualEvent Whether the new event is virtual
     * @param _privateEvent Whether the new event is private
     */
    function createNewEvent(
        string memory _eventName,
        string memory _description,
        string memory _eventAddress,
        uint256 _date,
        uint256 _startTime,
        uint256 _endTime,
        bool _virtualEvent,
        bool _privateEvent
    ) external {
        if (!ensByAddr[_msgSender()].isRegistered) {
            revert Errors.UNREGISTERED_USER();
        }

        EventContract newEvent = new EventContract(
            eventId,
            _msgSender(),
            _eventName,
            _description,
            _eventAddress,
            _date,
            _startTime,
            _endTime,
            _virtualEvent,
            _privateEvent
        );

        eventMapping[eventId] = newEvent;
        events.push(newEvent);
        eventsCreatedByOrganizer[_msgSender()].push(newEvent);

        // grant the organizer a specific role for this event
        bytes32 defaultEventIdRole = keccak256(
            abi.encodePacked("DEFAULT_EVENT_ORGANIZER", eventId)
        );
        bytes32 eventIdRole = keccak256(
            abi.encodePacked("EVENT_ORGANIZER", eventId)
        );
        require(_grantRole(defaultEventIdRole, _msgSender()));
        require(_grantRole(eventIdRole, _msgSender()));

        // emit event creation
        emit EventCreated(eventId, _eventName, _msgSender());

        // increment eventId
        eventId++;
    }

    /**
     * @dev Adds a new organizer to an event
     * @param _eventId The ID of the event
     * @param _newOrganizer The address of the new organizer
     */
    function addEventOrganizer(
        uint256 _eventId,
        address _newOrganizer
    )
        external
        onlyRole(
            keccak256(abi.encodePacked("DEFAULT_EVENT_ORGANIZER", _eventId))
        )
    {
        require(
            _grantRole(
                keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)),
                _newOrganizer
            )
        );

        emit AddOrganizer(_eventId, _newOrganizer);
    }

    /**
     * @dev Removes an organizer from an event
     * @param _eventId The ID of the event
     * @param _removedOrganizer The address of the removed organizer
     */
    function removeOrganizer(
        uint256 _eventId,
        address _removedOrganizer
    )
        external
        onlyRole(
            keccak256(abi.encodePacked("DEFAULT_EVENT_ORGANIZER", _eventId))
        )
    {
        require(
            _revokeRole(
                keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)),
                _removedOrganizer
            )
        );

        emit RemoveOrganizer(_eventId, _removedOrganizer);
    }

    /**
     * @dev Updates event detail
     * @param _eventId The ID of the event
     * @param _date The new date of the event
     * @param _startTime The new start time of the event
     * @param _endTime The new end time of the event
     * @param _virtualEvent Whether the event is virtual
     * @param _privateEvent Whether the event is private
     */
    function updateEvent(
        uint256 _eventId,
        string memory _eventName,
        string memory _description,
        string memory _eventAddress,
        uint256 _date,
        uint256 _startTime,
        uint256 _endTime,
        bool _virtualEvent,
        bool _privateEvent
    )
        external
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        if (!ensByAddr[_msgSender()].isRegistered) {
            revert Errors.UNREGISTERED_USER();
        }

        EventContract eventContract = eventMapping[_eventId];

        // Ensure event exists
        require(address(eventContract) != address(0), "Event does not exist");

        // Check if the event is in the future
        require(block.timestamp < _startTime, "Event must be in the future");

        // Update event details
        eventContract.updateEventDetails(
            _eventName,
            _description,
            _eventAddress,
            _date,
            _startTime,
            _endTime,
            _virtualEvent,
            _privateEvent
        );

        // Emit event updated
        emit EventUpdated(
            _eventId,
            _date,
            _startTime,
            _endTime,
            _virtualEvent,
            _privateEvent
        );
    }

    /**
     * @dev Cancels an event
     * @param _eventId The ID of the event
     */
    function cancelEvent(
        uint256 _eventId
    )
        external
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        if (!ensByAddr[_msgSender()].isRegistered) {
            revert Errors.UNREGISTERED_USER();
        }

        EventContract eventContract = eventMapping[_eventId];

        // Ensure event exists
        require(address(eventContract) != address(0), "Event does not exist");

        eventContract.cancelEvent();

        emit EventCancelled(_eventId);
    }

    /**
     * @dev Creates a new ticket for an event
     * @param _eventId The ID of the event
     * @param _ticketId The ID of the ticket
     * @param _quantity The amount of tickets to create
     */
    function createEventTicket(
        uint256 _eventId,
        uint256[] calldata _ticketId,
        uint256[] calldata _quantity,
        uint256[] calldata _price
    )
        external
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        if (!ensByAddr[_msgSender()].isRegistered) {
            revert Errors.UNREGISTERED_USER();
        }

        EventContract eventContract = eventMapping[_eventId];

        // Ensure event exists
        require(address(eventContract) != address(0), "Event does not exist");

        if (_ticketId.length < 1) {
            revert Errors.INVALID_INPUT();
        }

        if (
            _ticketId.length != _quantity.length &&
            _ticketId.length != _price.length
        ) {
            revert Errors.INPUT_MISMATCH();
        }

        eventContract.createEventTicket(_ticketId, _quantity, _price);
    }

    /**
     * @dev Returns created tickets
     * @return Array of created ticket IDs
     */
    function getCreatedTickets(
        uint256 _eventId
    ) external view returns (uint256[] memory) {
        return eventMapping[_eventId].getCreatedTickets();
    }

    /**
     * @dev Buys tickets for an event
     * @param _eventId The ID of the event
     * @param _ticketId The ID of the ticket
     * @param _quantity The quantity of tickets to buy
     */
    function buyTicket(
        uint256 _eventId,
        uint256[] calldata _ticketId,
        uint256[] calldata _quantity
    ) external payable nonReentrant {
        address _buyer = _msgSender();

        if (!ensByAddr[_buyer].isRegistered) {
            revert Errors.UNREGISTERED_USER();
        }

        EventContract eventContract = eventMapping[_eventId];

        // Ensure event exists
        require(address(eventContract) != address(0), "Event does not exist");

        if (_ticketId.length < 1) {
            revert Errors.INVALID_INPUT();
        }

        if (_ticketId.length != _quantity.length) {
            revert Errors.INPUT_MISMATCH();
        }

        uint256 totalTicketPrice;

        for (uint i; i < _ticketId.length; i++) {
            totalTicketPrice +=
                eventContract.getTicketIdPrice(_ticketId[i]) *
                _quantity[i];
        }

        if (msg.value < totalTicketPrice) {
            revert Errors.INSUFFICIENT_AMOUNT();
        }

        eventContract.buyTicket(_ticketId, _quantity, _buyer);

        boughtTicketsByUserPerId[_buyer][_eventId].push(eventContract);

        boughtTicketsByUser[_buyer].push(eventContract);
    }

    /**
     * @dev Returns the balance of tickets for an event
     * @param _eventId The ID of the event
     * @param _account The address of the account
     * @param _ticketId The ID of the ticket
     * @return The balance of tickets
     */
    function balanceOfTickets(
        uint256 _eventId,
        address _account,
        uint256 _ticketId
    ) external view returns (uint256) {
        return eventMapping[_eventId].balanceOf(_account, _ticketId);
    }

    /**
     * @dev Returns the details of an event
     * @param _eventId The ID of the event
     * @return The details of the event
     */
    function getEventDetails(
        uint256 _eventId
    ) external view returns (EventContract.EventDetails memory) {
        return eventMapping[_eventId].getEventDetails();
    }

     /**
     * @dev Returns all events created by an organizer
     * @return Array of organizers' events
     */
    function getAllEventsByOrganizer() external view returns (EventContract[] memory) {
        return eventsCreatedByOrganizer[_msgSender()];
    }

    /**
     * @dev Returns all events
     * @return Array of events
     */
    function getAllEvents() external view returns (EventContract[] memory) {
        return events;
    }

    /**
     * @dev Returns the total supply of a ticket type for an event
     * @param _eventId The ID of the event
     * @param _ticketId The ID of the ticket
     * @return The balance of a ticket type for an event
     */
    function totalSupplyTicketId(
        uint256 _eventId,
        uint256 _ticketId
    ) external view returns (uint256) {
        return eventMapping[_eventId].totalSupply(_ticketId);
    }

    /**
     * @dev Returns the total supply of a ticket type for an event
     * @param _eventId The ID of the event
     * @return The balance of all tickets for an event
     */
    function totalSupplyAllTickets(
        uint256 _eventId
    ) external view returns (uint256) {
        return eventMapping[_eventId].totalSupply();
    }

    function _msgSender() internal view virtual override(Context, ERC2771Context) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view virtual override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }

    receive() external payable {}

    fallback() external payable {}
}