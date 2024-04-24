// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

// imports
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

// errors
error NotAdmin();

contract EventContract is ERC1155, IERC1155Receiver {
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

    event TicketPurchased(
        address indexed buyer,
        string eventName,
        uint256 indexed eventId,
        uint256 indexed ticketId
    );

    event TicketCreated(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes data
    );

    event TicketBurned(
        address indexed from,
        uint256 indexed ticketId,
        uint256 indexed amount
    );

    event TicketTransferred(
        address indexed from,
        address indexed to,
        uint256 indexed ticketId
    );

    // admin role
    address admin;

    // Event variables
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
    EventDetails eventDetails;

    // event...innit
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
    }

    // access to only admin: factory contract
    function onlyAdmin() private view {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
    }

    // mint event tickets to contract
    function createEventTicket(
        uint256[] calldata _ticketId,
        uint256[] calldata _amount
    ) external {
        onlyAdmin();
        if (_ticketId.length > 1) {
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

    // return event details
    function getEventDetails() external view returns (EventDetails memory) {
        return eventDetails;
    }

    // reschedule event
    function rescheduleEvent(
        uint256 _date,
        uint256 _startTime,
        uint256 _endTime,
        bool _virtualEvent,
        bool _privateEvent
    ) external {
        onlyAdmin();
        eventDetails.date = _date;
        eventDetails.startTime = _startTime;
        eventDetails.endTime = _endTime;
        eventDetails.virtualEvent = _virtualEvent;
        eventDetails.privateEvent = _privateEvent;
    }

    // cancel event
    function cancelEvent() external {
        onlyAdmin();
        eventDetails.isCancelled = true;

        emit EventCancelled(eventDetails.eventId);
    }

    // handle receiving of ERC1155 token
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        // Handle the received tokens
        // Emit an event to notify the receipt of tokens
        emit TicketCreated(operator, from, id, value, data);

        // Return the ERC1155Received magic value
        return IERC1155Receiver.onERC1155Received.selector;
    }

    // handle batch receiving of ERC1155 token
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        // Handle the received tokens
        // Emit an event to notify the receipt of tokens
        for (uint256 i = 0; i < ids.length; i++) {
            emit TicketCreated(operator, from, ids[i], values[i], data);
        }

        // Return the ERC1155BatchReceived magic value
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    // set event URI
    function setEventURI(string memory newUri_) external {
        onlyAdmin();
        _setURI(newUri_);
    }

    // ERC-165: Standard Interface Detection
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
