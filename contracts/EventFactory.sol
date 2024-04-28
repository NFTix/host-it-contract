// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import "./EventContract.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract EventFactory is AccessControl, ReentrancyGuard {
    // contract events
    event EventCreated(
        uint256 indexed eventId,
        string indexed eventName,
        address indexed organizer
    );

    event EventRescheduled(
        uint256 indexed eventId,
        uint256 date,
        uint256 startTime,
        uint256 endTime,
        bool virtualEvent,
        bool privateEvent
    );

    event EventCancelled(uint256 indexed eventId);

    event AddOrganizer(uint256 indexed eventId, address indexed newOrganizer);

    event RemoveOrganizer(
        uint256 indexed eventId,
        address indexed newOrganizer
    );

    // state variables
    uint256 eventId;
    mapping(uint256 => EventContract) public eventMapping;

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

    // add organizer
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

    // remove organizer
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

    // Update event details
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

    // cancel event
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

    // create ticket
    function createEventTicket(
        uint256 _eventId,
        uint256[] calldata _ticketId,
        uint256[] calldata _amount
    )
        external
        payable
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        eventMapping[_eventId].createEventTicket(_ticketId, _amount);
    }

    // buy ticket
    function buyTicket(
        uint256 _eventId,
        uint256[] calldata _ticketId,
        uint256[] calldata _amount,
        address _buyer
    ) external payable nonReentrant {
        eventMapping[_eventId].buyTicket(_ticketId, _amount, _buyer);
    }

    // balance of tickets
    function balanceOfTickets(
        uint256 _eventId,
        address _account,
        uint256 _ticketId
    ) external view returns (uint256) {
        return eventMapping[_eventId].balanceOf(_account, _ticketId);
    }

    // return event details
    function getEventDetails(
        uint256 _eventId
    ) external view returns (EventContract.EventDetails memory) {
        return (eventMapping[_eventId].getEventDetails());
    }

    // get total supply of tickets by ID
    function totalSupplyTicketId(
        uint256 _eventId,
        uint256 _ticketId
    ) external view returns (uint256) {
        return eventMapping[_eventId].totalSupply(_ticketId);
    }

    // get total supply of all tickets
    function totalSupplyAllTickets(
        uint256 _eventId
    ) external view returns (uint256) {
        return eventMapping[_eventId].totalSupply();
    }

    receive() external payable {}

    fallback() external payable {}
}
