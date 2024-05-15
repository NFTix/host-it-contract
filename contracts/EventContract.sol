// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

// imports
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./Errors.sol";

/**
 * @dev EventContract is a contract that represents an event
 */
contract EventContract is ERC1155Supply, ERC1155Holder {
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
     * @dev Emitted when a ticket is created
     * @param to The address of the receiver
     * @param id The ID of the ticket
     * @param quantity The quantity of tickets
     * @param price The price of the ticket
     */
    event TicketCreated(
        address indexed to,
        uint256 indexed id,
        uint256 quantity,
        uint256 indexed price
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

    // factoryContract address
    address factoryContract;

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
    mapping(uint256 => uint256) ticketPricePerId;
    mapping(uint256 => uint256) soldTicketsPerId;
    mapping(uint256 => bool) ticketExists;
    uint256[] public createdTicketIds;

    // Mapping to store the amount of each ticket bought by each user
    mapping(address => TicketPurchase[]) public userTickets;
    mapping(address => uint256) public userTicketAmount;

    struct TicketPurchase {
        uint256 ticketId;
        uint256 amount;
    }

    event RefundClaimed(address indexed user, uint256 amount);

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
     factoryContract = msg.sender;

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

        _setApprovalForAll(address(this), factoryContract, true);
    }

    /**
     * @dev Restricts access to only the factoryContract
     */
    function onlyFactoryContract() private view {
        if (msg.sender != factoryContract) {
            revert Errors.NOT_ADMIN();
        }
    }

    /**
     * @dev Mints event tickets to the contract
     * @param _ticketId The ID of the ticket
     * @param _quantity The quantity of tickets to mint
     * @param _price The price of the ticket
     */
    function createEventTicket(
        uint256[] calldata _ticketId,
        uint256[] calldata _quantity,
        uint256[] calldata _price
    ) external {
        onlyFactoryContract();

        // mint tickets to the contract
        _mintBatch(address(this), _ticketId, _quantity, "");

        for (uint256 i; i < _ticketId.length; i++) {
            // stores the price of each ticket
            ticketPricePerId[_ticketId[i]] = _price[i];

            // track created tickets
            if (!ticketExists[_ticketId[i]]) {
                ticketExists[_ticketId[i]] = true;
                createdTicketIds.push(_ticketId[i]);
            }

            emit TicketCreated(
                address(this),
                _ticketId[i],
                _quantity[i],
                _price[i]
            );
        }
    }

    /**
     * @dev Returns created tickets
     * @return Array of created ticket IDs
     */
    function getCreatedTickets() external view returns (uint256[] memory) {
        return createdTicketIds;
    }

    /**
     * @dev Returns ticket price per ID
     * @return Ticket ID price
     */
    function getTicketIdPrice(
        uint256 _ticketId
    ) external view returns (uint256) {
        return ticketPricePerId[_ticketId];
    }

    /**
     * @dev Buy event tickets from the contract
     * @param _ticketId The ID of the ticket
     * @param _quantity The quantity of tickets to buy
     * @param _buyer The address of the buyer
     */
    function buyTicket(
        uint256[] calldata _ticketId,
        uint256[] calldata _quantity,
        address _buyer
    ) external {
        onlyFactoryContract();

        // sends event tickets to the buyer
        safeBatchTransferFrom(address(this), _buyer, _ticketId, _quantity, "");

        for (uint256 i = 0; i < _ticketId.length; i++) {
            soldTicketsPerId[_ticketId[i]] += _quantity[i];

            eventDetails.soldTickets += _quantity[i];

            emit TicketPurchased(
                _buyer,
                eventDetails.eventName,
                eventDetails.eventId,
                _ticketId[i]
            );
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
        onlyFactoryContract();
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
        onlyFactoryContract();
        eventDetails.isCancelled = true;

        emit EventCancelled(eventDetails.eventId);
    }

    /**
     * @dev Sets the event URI
     * @param newUri_ The new URI of the event
     */
    function setEventURI(string memory newUri_) external {
        onlyFactoryContract();
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