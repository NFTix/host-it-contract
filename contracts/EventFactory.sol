// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import "./EventContract.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title EventFactory
 * @author ...
 * @notice This contract is a factory for creating and managing events
 * @dev This contract uses AccessControl and ReentrancyGuard from OpenZeppelin
 */

contract EventFactory is AccessControl, ReentrancyGuard {
    /**
     * @dev Emitted when a new event is created
     * @param eventId The ID of the new event
     * @param eventName The name of the new event
     * @param organizer The address of the event organizer
     */
    event EventCreated(
        uint256 indexed eventId,
        string indexed eventName,
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
    event EventRescheduled(
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

    // state variables
    uint256 eventId;
    mapping(uint256 => EventContract) public eventMapping;
    mapping(address => uint) name;

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
        EventContract newEvent = new EventContract(
            ++eventId,
            msg.sender,
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

        // grant the organizer a specific role for this event
        bytes32 defaultEventIdRole = keccak256(
            abi.encodePacked("DEFAULT_EVENT_ORGANIZER", eventId)
        );
        bytes32 eventIdRole = keccak256(
            abi.encodePacked("EVENT_ORGANIZER", eventId)
        );
        require(_grantRole(defaultEventIdRole, msg.sender));
        require(_grantRole(eventIdRole, msg.sender));

        // emit event creation
        emit EventCreated(eventId, _eventName, msg.sender);
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
            keccak256(abi.encodePacked("DEFAULT_EVENT_ORGANIZER", eventId))
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
            keccak256(abi.encodePacked("DEFAULT_EVENT_ORGANIZER", eventId))
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
        // Ensure event exists
        require(
            address(eventMapping[_eventId]) != address(0),
            "Event does not exist"
        );

        // Check if the event is in the future
        require(block.timestamp < _startTime, "Event must be in the future");

        // Update event details
        EventContract eventContract = eventMapping[_eventId];
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
        emit EventRescheduled(
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
        eventMapping[_eventId].cancelEvent();

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
        eventMapping[_eventId].createEventTicket(_ticketId, _quantity, _price);
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
     * @param _buyer The address of the buyer
     */
    function buyTicket(
        uint256 _eventId,
        uint256[] calldata _ticketId,
        uint256[] calldata _quantity,
        address _buyer
    ) external payable nonReentrant {
        eventMapping[_eventId].buyTicket(_ticketId, _quantity, _buyer);
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
        return (eventMapping[_eventId].getEventDetails());
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

    receive() external payable {}

    fallback() external payable {}
}
