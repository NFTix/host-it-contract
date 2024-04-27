// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

// imports
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

// errors
error NotAdmin();

contract EventContract is ERC1155Supply, ERC1155Holder {
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

    EventDetails public eventDetails;

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

        _setApprovalForAll(address(this), admin, true);
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

    // buy event ticket
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

    // set event URI
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
