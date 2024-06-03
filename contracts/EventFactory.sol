// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./EventContract.sol";
import "./Registry.sol";
import "./ILogAutomation.sol";
import "./Errors.sol";

/**
 * @title EventFactory
 * @author David <daveproxy80@gmail.com>
 * @author Manoah <manoahluka@gmail.com>
 * @author Olorunsogo <sogobanwo@gmail.com>
 * @notice This contract is a factory for creating and managing events
 * @dev This contract uses AccessControl and ReentrancyGuard from OpenZeppelin
 * @dev This contract uses ILogAutomation from Chainlink
 */
contract EventFactory is
    AccessControl,
    ReentrancyGuard,
    Registry,
    ILogAutomation
{
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

    event CountedBy(address indexed msgSender);

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
        if (!ensByAddr[_organizer].isRegistered) {
            revert Errors.UNREGISTERED_USER();
        }

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

        eventMapping[eventId] = newEvent;
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
        if (!ensByAddr[_organizer].isRegistered) {
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
        uint256 _eventId,
        address _organizer
    )
        external
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        if (!ensByAddr[_organizer].isRegistered) {
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
        address _organizer,
        uint256[] calldata _ticketId,
        uint256[] calldata _quantity,
        uint256[] calldata _price
    )
        external
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        if (!ensByAddr[_organizer].isRegistered) {
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
     * @dev Buys tickets for an event
     * @param _eventId The ID of the event
     * @param _ticketId The ID of the ticket
     * @param _quantity The quantity of tickets to buy
     */
    function buyTicket(
        uint256 _eventId,
        uint256[] calldata _ticketId,
        uint256[] calldata _quantity,
        address _buyer
    ) external payable nonReentrant {
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

    /*//////////////////////////////////////////////////////////////
                            CHAINLINK FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice method that is simulated by the keepers to see if any work actually
     * needs to be performed. This method does does not actually need to be
     * executable, and since it is only ever simulated it can consume lots of gas.
     * @dev To ensure that it is never called, you may want to add the
     * cannotExecute modifier from KeeperBase to your implementation of this
     * method.
     * @param log the raw log data matching the filter that this contract has
     * registered as a trigger
     * @param checkData user-specified extra data to provide context to this upkeep
     * @return upkeepNeeded boolean to indicate whether the keeper should call
     * performUpkeep or not.
     * @return performData bytes that the keeper should call performUpkeep with, if
     * upkeep is needed. If you would like to encode data to decode later, try
     * `abi.encode`.
     */
    function checkLog(
        Log calldata log,
        bytes memory checkData
    ) external pure returns (bool upkeepNeeded, bytes memory performData) {
        upkeepNeeded = true;
        address logSender = bytes32ToAddress(log.topics[1]);
        performData = abi.encode(logSender);
    }

    /**
     * @notice method that is actually executed by the keepers, via the registry.
     * The data returned by the checkUpkeep simulation will be passed into
     * this method to actually be executed.
     * @dev The input to this method should not be trusted, and the caller of the
     * method should not even be restricted to any single registry. Anyone should
     * be able call it, and the input should be validated, there is no guarantee
     * that the data passed in is the performData returned from checkUpkeep. This
     * could happen due to malicious keepers, racing keepers, or simply a state
     * change while the performUpkeep transaction is waiting for confirmation.
     * Always validate the data passed in.
     * @param performData is the data which was passed back from the checkData
     * simulation. If it is encoded, it can easily be decoded into other types by
     * calling `abi.decode`. This data should not be trusted, and should be
     * validated against the contract's current state.
     */
    function performUpkeep(bytes calldata performData) external override {
        // counted += 1;
        address logSender = abi.decode(performData, (address));
        emit CountedBy(logSender);
    }

    function bytes32ToAddress(bytes32 _address) public pure returns (address) {
        return address(uint160(uint256(_address)));
    }

    /*//////////////////////////////////////////////////////////////
                             READ FUNCTIONS
    //////////////////////////////////////////////////////////////*/

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

    /*//////////////////////////////////////////////////////////////
                         RECIEVE ETHER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    receive() external payable {}

    fallback() external payable {}
}
