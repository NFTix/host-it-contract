// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./EventContract.sol";
import "./Registry.sol";

error EVENT_DOES_NOT_EXIST();
error INVALID_START_TIME();

/**
 * @title EventFactory
 * @author
 * @notice This contract is a factory for creating and managing events
 * @dev This contract uses AccessControl and ReentrancyGuard from OpenZeppelin
 * @dev This contract uses AccessControl and ReentrancyGuard from OpenZeppelin
 */
contract EventFactory is AccessControl, ReentrancyGuard, Registry {
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
    mapping(address => EventContract[]) eventsCreatedByOrganizer;
    mapping(address => EventContract[]) boughtTicketsByUser;
    mapping(address => mapping(uint256 => EventContract[])) boughtTicketsByUserPerId;

    /*//////////////////////////////////////////////////////////////
                            EVENT FACTORY LOGIC
    //////////////////////////////////////////////////////////////*/

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
        address _organizer,
        string memory _eventName,
        string memory _description,
        string memory _eventAddress,
        uint256 _date,
        uint256 _startTime,
        uint256 _endTime,
        bool _virtualEvent,
        bool _privateEvent
    ) external {
        if (!ensByAddr[_organizer].isRegistered) revert UNREGISTERED_USER();

        EventContract newEvent = new EventContract(
            eventId,
            _organizer,
            _eventName,
            _description,
            _eventAddress,
            _date,
            _startTime,
            _endTime,
            _virtualEvent,
            _privateEvent
        );

        events.push(newEvent);
        eventsCreatedByOrganizer[_organizer].push(newEvent);

        // grant the organizer a specific role for this event
        bytes32 defaultEventIdRole = keccak256(
            abi.encodePacked("DEFAULT_EVENT_ORGANIZER", eventId)
        );
        bytes32 eventIdRole = keccak256(
            abi.encodePacked("EVENT_ORGANIZER", eventId)
        );
        require(_grantRole(defaultEventIdRole, _organizer));
        require(_grantRole(eventIdRole, _organizer));

        // emit event creation
        emit EventCreated(eventId, _eventName, _organizer);

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
        address _organizer,
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
        if (!ensByAddr[_organizer].isRegistered) revert UNREGISTERED_USER();

        EventContract eventContract = events[_eventId];

        // Ensure event exists
        if (address(eventContract) == address(0)) revert EVENT_DOES_NOT_EXIST();

        // Check if the event has not started yet
        if (_startTime > block.timestamp) revert INVALID_START_TIME();

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
        uint256 _eventId,
        address _organizer
    )
        external
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        if (!ensByAddr[_organizer].isRegistered) revert UNREGISTERED_USER();

        EventContract eventContract = events[_eventId];

        // Ensure event exists
        if (address(eventContract) == address(0)) revert EVENT_DOES_NOT_EXIST();

        eventContract.cancelEvent();

        emit EventCancelled(_eventId);
    }

    /**
     * @dev Creates a new ticket for an event
     * @param _eventId The ID of the event
     * @param _ticketIds The ID of the ticket
     * @param _quantity The amount of tickets to create
     * @param _prices The amount of tickets to create
     */
    function createEventTicket(
        uint256 _eventId,
        address _organizer,
        uint256[] calldata _ticketIds,
        uint256[] calldata _quantity,
        uint256[] calldata _prices
    )
        external
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        if (!ensByAddr[_organizer].isRegistered) revert UNREGISTERED_USER();

        EventContract eventContract = events[_eventId];

        // Ensure event exists
        if (address(eventContract) == address(0)) revert EVENT_DOES_NOT_EXIST();

        uint256 idsLength = _ticketIds.length;

        if (idsLength < 1) revert INVALID_INPUT();

        if (
            idsLength != _quantity.length &&
            idsLength != _prices.length
        ) revert INPUT_MISMATCH();

        eventContract.createEventTicket(_ticketIds, _quantity, _prices);
    }

    /**
     * @dev Returns created tickets
     * @param _eventId The ID of the event
     * @return Array of created ticket IDs
     */
    function getCreatedTickets(
        uint256 _eventId
    ) external view returns (uint256[] memory) {
        return events[_eventId].getCreatedTickets();
    }

    /**
     * @dev Buys tickets for an event
     * @param _eventId The ID of the event
     * @param _ticketIds The IDs of the tickets
     * @param _quantity The quantity of each tickets to buy
     * @param _buyer The address of the buyer
     */
    function buyTicket(
        uint256 _eventId,
        uint256[] calldata _ticketIds,
        uint256[] calldata _quantity,
        address _buyer
    ) external payable nonReentrant {
        if (!ensByAddr[_buyer].isRegistered) revert UNREGISTERED_USER();

        EventContract eventContract = events[_eventId];

        // Ensure event exists
        if (address(eventContract) == address(0)) revert EVENT_DOES_NOT_EXIST();

        uint256 idsLength = _ticketIds.length;

        if (idsLength < 1) revert INVALID_INPUT();

        if (idsLength != _quantity.length) revert INPUT_MISMATCH();

        uint256 totalTicketPrice;

        for (uint i; i < idsLength; ) {
            totalTicketPrice +=
                eventContract.getTicketIdPrice(_ticketIds[i]) *
                _quantity[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        if (msg.value < totalTicketPrice) {
            revert INSUFFICIENT_AMOUNT();
        }

        eventContract.buyTicket(_ticketIds, _quantity, _buyer);

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
        return events[_eventId].balanceOf(_account, _ticketId);
    }

    /**
     * @dev Returns the details of an event
     * @param _eventId The ID of the event
     * @return The details of the event
     */
    function getEventDetails(
        uint256 _eventId
    ) external view returns (EventContract.EventDetails memory) {
        return events[_eventId].getEventDetails();
    }

    /**
     * @dev Returns all events created by an organizer
     * @return Array of organizers' events
     */
    function getAllEventsByOrganizer(
        address _organizer
    ) external view returns (EventContract[] memory) {
        return eventsCreatedByOrganizer[_organizer];
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
        return events[_eventId].totalSupply(_ticketId);
    }

    /**
     * @dev Returns the total supply of a ticket type for an event
     * @param _eventId The ID of the event
     * @return The balance of all tickets for an event
     */
    function totalSupplyAllTickets(
        uint256 _eventId
    ) external view returns (uint256) {
        return events[_eventId].totalSupply();
    }

    receive() external payable {}

    fallback() external payable {}
}
