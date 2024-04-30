// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

// imports
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// errors
error NotAdmin();

/**
 * @dev EventContract is a contract that represents an event
 */
contract EventContract is ERC1155Supply, ERC1155Holder {
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
     * @dev Emitted when a ticket is purchased
     * @param buyer The address of the buyer
     * @param eventName The name of the event
     * @param eventId The ID of the event
     * @param ticketId The ID of the ticket
     */
    event TicketPurchased(
        address indexed buyer,
        string eventName,
        uint256 indexed eventId,
        uint256 indexed ticketId
    );

    /**
     * @dev Emitted when a ticket is created
     * @param operator The address of the operator
     * @param from The address of the sender
     * @param id The ID of the ticket
     * @param value The amount of tickets
     * @param data The data of the ticket
     */
    event TicketCreated(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes data
    );

    /**
     * @dev Emitted when a ticket is burned
     * @param from The address of the sender
     * @param ticketId The ID of the ticket
     * @param amount The amount of tickets burned
     */
    event TicketBurned(
        address indexed from,
        uint256 indexed ticketId,
        uint256 indexed amount
    );

    /**
     * @dev Emitted when a ticket is transferred
     * @param from The address of the sender
     * @param to The address of the receiver
     * @param ticketId The ID of the ticket
     */
    event TicketTransferred(
        address indexed from,
        address indexed to,
        uint256 indexed ticketId
    );

    // admin role
    address admin;

    // Event variables
    /**
     * @dev Struct representing the details of an event
     */
    struct EventDetails {
        uint256 eventId;
        address organizer;
        string eventName;
        string description;
        string eventAddress;
        uint256 date;
        uint256 startTime;
        uint256 endTime;
        bool virtualEvent;
        bool privateEvent;
        uint256 totalTickets;
        uint256 soldTickets;
        bool isCancelled;
    }

    EventDetails public eventDetails;

    /**
     * @dev Initializes the contract with the event details
     * @param _eventId The ID of the event
     * @param _organizer The address of the event organizer
     * @param _eventName The name of the event
     * @param _description The description of the event
     * @param _eventAddress The address of the event
     * @param _date The date of the event
     * @param _startTime The start time of the event
     * @param _endTime The end time of the event
     * @param _virtualEvent Whether the event is virtual
     * @param _privateEvent Whether the event is private
     */
    constructor(
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
    ) ERC1155("") {
        admin = msg.sender;

        eventDetails = EventDetails({
            eventId: _eventId,
            organizer: _organizer,
            eventName: _eventName,
            description: _description,
            eventAddress: _eventAddress,
            date: _date,
            startTime: _startTime,
            endTime: _endTime,
            virtualEvent: _virtualEvent,
            privateEvent: _privateEvent,
            totalTickets: 0,
            soldTickets: 0,
            isCancelled: false
        });

        emit EventCreated(
            eventDetails.eventId,
            eventDetails.eventName,
            eventDetails.organizer
        );

        _setApprovalForAll(address(this), admin, true);
    }

    /**
     * @dev Restricts access to only the admin
     */
    function onlyAdmin() private view {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
    }

    /**
     * @dev Mints event tickets to the contract
     * @param _ticketId The ID of the ticket
     * @param _amount The amount of tickets to mint
     */
    function createEventTicket(
        uint256[] calldata _ticketId,
        uint256[] calldata _amount
    ) external {
        onlyAdmin();
        if (_ticketId.length > 1 && _amount.length > 1) {
            _mintBatch(address(this), _ticketId, _amount, "");
            for (uint256 i; i < _amount.length; i++) {
                eventDetails.totalTickets += _amount[i];
            }
        } else {
            uint256 _ticket = _ticketId[0];
            uint256 amount = _amount[0];
            _mint(address(this), _ticket, amount, "");
            eventDetails.totalTickets += amount;
        }
    }

    /**
     * @dev Buy event tickets from the contract
     * @param _ticketId The ID of the ticket
     * @param _amount The amount of tickets to buy
     * @param _buyer The address of the buyer
     */
    function buyTicket(
        uint256[] calldata _ticketId,
        uint256[] calldata _amount,
        address _buyer
    ) external payable {
        onlyAdmin();

        if (_ticketId.length > 1 && _amount.length > 1) {
            safeBatchTransferFrom(
                address(this),
                _buyer,
                _ticketId,
                _amount,
                ""
            );
            for (uint256 i = 0; i < _ticketId.length; i++) {
                eventDetails.soldTickets += _amount[i];
                emit TicketPurchased(
                    _buyer,
                    eventDetails.eventName,
                    eventDetails.eventId,
                    _ticketId[i]
                );
            }
        } else {
            safeTransferFrom(
                address(this),
                _buyer,
                _ticketId[0],
                _amount[0],
                ""
            );

            emit TicketPurchased(
                _buyer,
                eventDetails.eventName,
                eventDetails.eventId,
                _ticketId[0]
            );

            // update ampunt of sold tickets
            eventDetails.soldTickets += _amount[0];
        }
    }

    /**
     * @dev Returns the event details
     * @return The event details
     */
    function getEventDetails() external view returns (EventDetails memory) {
        return eventDetails;
    }

    /**
     * @dev Updates the event details
     * @param _eventName The new name of the event
     * @param _description The new description of the event
     * @param _eventAddress The new address of the event
     * @param _date The new date of the event
     * @param _startTime The new start time of the event
     * @param _endTime The new end time of the event
     * @param _virtualEvent Whether the event is virtual
     * @param _privateEvent Whether the event is private
     */
    function updateEventDetails(
        string memory _eventName,
        string memory _description,
        string memory _eventAddress,
        uint256 _date,
        uint256 _startTime,
        uint256 _endTime,
        bool _virtualEvent,
        bool _privateEvent
    ) external {
        onlyAdmin();
        eventDetails.eventName = _eventName;
        eventDetails.description = _description;
        eventDetails.eventAddress = _eventAddress;
        eventDetails.date = _date;
        eventDetails.startTime = _startTime;
        eventDetails.endTime = _endTime;
        eventDetails.virtualEvent = _virtualEvent;
        eventDetails.privateEvent = _privateEvent;
    }

    /**
     * @dev Cancels the event
     */
    function cancelEvent() external {
        onlyAdmin();
        eventDetails.isCancelled = true;

        emit EventCancelled(eventDetails.eventId);
    }

    /**
     * @dev Sets the event URI
     * @param newUri_ The new URI of the event
     */
    function setEventURI(string memory newUri_) external {
        onlyAdmin();
        _setURI(newUri_);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155, ERC1155Holder) returns (bool) {
        return
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}
