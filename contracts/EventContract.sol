// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

// imports
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

// errors
error NotAdmin();

contract EventContract is ERC1155 {
    // contract events
    event EventCreated(
        uint256 indexed eventId,
        string indexed eventName,
        address indexed organizer
    );

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
        uint64 totalTickets;
        uint64 soldTickets;
        bool hasEnded;
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
            hasEnded: false
        });

        emit EventCreated(
            eventDetails.eventId,
            eventDetails.eventName,
            eventDetails.organizer
        );
    }

    // access to only factory contract
    function onlyAdmin() private view {
        if (msg.sender != admin) {
            revert NotAdmin();
        }
    }

    // return event details
    function getEventDetails() public view returns (EventDetails memory) {
        return eventDetails;
    }

    // create ticket
    function createTicket(
        uint256[] calldata _ticketVariety,
        uint256[] calldata _amount
    ) external payable {
        onlyAdmin();
        if (_ticketVariety.length > 1) {
            _mintBatch(admin, _ticketVariety, _amount, "");
        } else {
            uint256 _ticket = _ticketVariety[0];
            uint256 _price = _amount[0];
            _mint(admin, _ticket, _price, "");
        }
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
    ) public view override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
