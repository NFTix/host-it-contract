// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./EventContract.sol";
import "./Registry.sol";

error EVENT_DOES_NOT_EXIST();
error EVENT_CANCELLED();
error EVENT_NOT_CANCELLED();
error EVENT_HAS_ALREADY_STARTED();
error INVALID_START_TIME(uint256 startTime);

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

    /**
     * @dev Emitted when a user claims the refund from a cancelled event
     * @param buyer Address of ticket buyer
     * @param quantity Number of tickets bought
     * @param price Price of the ticket
     */
    event RefundClaimed(address indexed buyer, uint256 quantity, uint256 price);

    /*//////////////////////////////////////////////////////////////
                            EVENT FACTORY STORAGE
    //////////////////////////////////////////////////////////////*/

    address admin;
    uint256 eventId;
    EventContract[] events;
    mapping(uint256 => EventContract) eventMapping;
    mapping(address => EventContract[]) eventsCreatedByOrganizer;
    mapping(address => EventContract[]) ticketsOwned;
    // address -> eventId -> ticketId -> price
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) ticketBoughtBalance;

    // TODO: store organizer's balance
    mapping(uint256 => uint256) eventBalance;

    /*//////////////////////////////////////////////////////////////
                            EVENT FACTORY LOGIC
    //////////////////////////////////////////////////////////////*/

    constructor() {
        admin = msg.sender;
    }

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
        // check if user is registered
        if (!ensByAddr[_organizer].isRegistered) revert UNREGISTERED_USER();

        // check if start time is past
        if (block.timestamp > _startTime) revert INVALID_START_TIME(_startTime);

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
        eventMapping[eventId] = newEvent;
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
        //ensure organizer is registered
        if (!ensByAddr[_organizer].isRegistered) revert UNREGISTERED_USER();

        EventContract eventContract = eventMapping[_eventId];

        // ensure event exists
        if (address(eventContract) == address(0)) revert EVENT_DOES_NOT_EXIST();

        // ensure event has not been cancelled already
        if (eventContract.getEventDetails().isCancelled)
            revert EVENT_CANCELLED();

        // check if the event has not started yet
        if (block.timestamp > _startTime) revert EVENT_HAS_ALREADY_STARTED();

        // update event details
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

        // emit event updated
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
        uint256 _eventId,
        address _organizer
    )
        external
        onlyRole(keccak256(abi.encodePacked("EVENT_ORGANIZER", _eventId)))
        nonReentrant
    {
        if (!ensByAddr[_organizer].isRegistered) revert UNREGISTERED_USER();

        EventContract eventContract = eventMapping[_eventId];

        // Ensure event exists
        if (address(eventContract) == address(0)) revert EVENT_DOES_NOT_EXIST();

        // Ensure event has not been cancelled already
        if (eventContract.getEventDetails().isCancelled)
            revert EVENT_CANCELLED();

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
        // ensure organizer is  registered
        if (!ensByAddr[_organizer].isRegistered) revert UNREGISTERED_USER();

        EventContract eventContract = eventMapping[_eventId];

        // Ensure event exists
        if (address(eventContract) == address(0)) revert EVENT_DOES_NOT_EXIST();

        // Ensure event has not been cancelled already
        if (eventContract.getEventDetails().isCancelled)
            revert EVENT_CANCELLED();

        uint256 idsLength = _ticketIds.length;

        if (idsLength < 1) revert INVALID_INPUT();

        if (idsLength != _quantity.length && idsLength != _prices.length)
            revert INPUT_MISMATCH();

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
        return eventMapping[_eventId].getCreatedTickets();
    }

    /**
     * @dev Buys tickets for an event
     * @param _eventId The ID of the event
     * @param _ticketIds The IDs of the tickets
     * @param _quantity The quantity of each ticket to buy
     * @param _buyer The address of the buyer
     */
    function buyTicket(
        uint256 _eventId,
        uint256[] calldata _ticketIds,
        uint256[] calldata _quantity,
        address _buyer
    ) external payable nonReentrant {
        if (!ensByAddr[_buyer].isRegistered) revert UNREGISTERED_USER();

        if (_eventId > eventId) revert EVENT_DOES_NOT_EXIST();

        EventContract eventContract = eventMapping[_eventId];

        // Ensure event exists
        if (address(eventContract) == address(0)) revert EVENT_DOES_NOT_EXIST();

        // Ensure event has not been cancelled already
        if (eventContract.getEventDetails().isCancelled)
            revert EVENT_CANCELLED();

        uint256 idsLength = _ticketIds.length;

        if (idsLength < 1) revert INVALID_INPUT();

        if (idsLength != _quantity.length) revert INPUT_MISMATCH();

        uint256 totalTicketPrice;

        for (uint i; i < idsLength; ) {
            totalTicketPrice +=
                eventContract.getTicketIdPrice(_ticketIds[i]) *
                _quantity[i];

            ticketBoughtBalance[_buyer][_eventId][_ticketIds[i]] = eventContract
                .getTicketIdPrice(_ticketIds[i]);

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        if (msg.value < totalTicketPrice) revert INSUFFICIENT_AMOUNT();

        eventContract.buyTicket(_ticketIds, _quantity, _buyer);

        eventBalance[_eventId] += totalTicketPrice * 97 / 100;

        // ticketsOwnedPerId[_buyer][_eventId].push(eventContract);

        // store events of tickets owned by buyer
        uint256 ticketsOwnedLength = ticketsOwned[_buyer].length;
        if (ticketsOwnedLength == 0) {
            ticketsOwned[_buyer].push(eventContract);
        } else {
            bool isEventBought;

            for (uint i; i < ticketsOwnedLength; ) {
                if (ticketsOwned[_buyer][i] == eventContract) {
                    isEventBought = true;
                    break;
                }

                // An array can't have a total length
                // larger than the max uint256 value.
                unchecked {
                    ++i;
                }
            }

            if (!isEventBought) {
                ticketsOwned[_buyer].push(eventContract);
            }
        }
    }

    function payout(
        address _organizer,
        uint256 _eventId
    )
        external
        onlyRole(
            keccak256(abi.encodePacked("DEFAULT_EVENT_ORGANIZER", _eventId))
        )
    {
        EventContract eventContract = eventMapping[_eventId];
        EventContract.EventDetails memory eventDetails = eventContract.getEventDetails();

        if (eventDetails.isCancelled) revert EVENT_CANCELLED();
        if (eventDetails.endTime > block.timestamp) revert EVENT_HAS_ALREADY_STARTED();

        // TODO: access organizer's stored balance
        uint256 balance = eventBalance[_eventId];
        eventBalance[_eventId] = 0;
        payable(_organizer).transfer(balance);
    }

    function refund(
        uint256 _eventId,
        uint256[] calldata _ticketIds,
        uint256[] calldata _quantity,
        address _buyer
    ) external nonReentrant {
        EventContract eventContract = eventMapping[_eventId];
        EventContract.EventDetails memory eventDetails = eventContract.getEventDetails();

        // check if event exists
        if (address(eventContract) == address(0)) revert EVENT_DOES_NOT_EXIST();

        //  check if event has been cancelled
        if (!eventDetails.isCancelled) revert EVENT_NOT_CANCELLED();

        uint256 idsLength = _ticketIds.length;

        if (idsLength < 1) revert INVALID_INPUT();

        if (idsLength != _quantity.length) revert INPUT_MISMATCH();

        uint256 totalTicketPrice;

        for (uint i; i < idsLength; ) {
            uint256 ticketIdPrice = eventContract.getTicketIdPrice(
                _ticketIds[i]
            );
            totalTicketPrice += ticketIdPrice * _quantity[i];
            // soldTicketsPerId[_ticketId[i]] -= _quantity[i];

            eventDetails.soldTickets -= _quantity[i];

            emit RefundClaimed(_buyer, _quantity[i], ticketIdPrice);

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        eventBalance[_eventId] = 0;

        eventContract.refund(_ticketIds, _quantity, _buyer);

        payable(_buyer).transfer(totalTicketPrice * 97 / 100);
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
     * @dev Returns all tickets for an event
     * @return Array of ticket ids
     */
    function getEventTickets(
        uint256 _eventId
    ) external view returns (uint256[] memory) {
        return eventMapping[_eventId].getCreatedTickets();
    }

    /**
     * @dev Returns ticket prices for an event
     * @return Array of ticket prices
     */
    function getTicketPrices(
        uint256 _eventId
    ) external view returns (uint256[] memory) {
        EventContract eventContract = eventMapping[_eventId];
        uint256[] memory tickets = eventContract.getCreatedTickets();
        uint256[] memory ticketPrices;
        for (uint i; i < tickets.length; ) {
            ticketPrices[i] = eventContract.getTicketIdPrice(i);

            unchecked {
                ++i;
            }
        }
        return ticketPrices;
    }

    /**
     * @dev Returns all tickets owned by an account
     * @param _account The address of the account
     * @return Array of tickets owned
     */
    function getTicketsOwned(
        address _account
    ) external view returns (EventContract[] memory) {
        return ticketsOwned[_account];
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

    function withdraw() external {
        require(msg.sender == admin);
        payable(admin).transfer(address(this).balance);
    }

    receive() external payable {}

    fallback() external payable {}
}
