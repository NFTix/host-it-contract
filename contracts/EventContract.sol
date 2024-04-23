// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// imports
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// errors
error NotAdmin();

contract EventContract is ERC1155 {
    // contract events
    event EventCreated(uint256 indexed eventId, address indexed organizer);
    event TicketPurchased(
        address indexed buyer,
        uint256 indexed eventId,
        uint256 indexed ticketId
    );

    // admin role
    address admin;
     mapping(address => bool) public isCoOrganizer;

     mapping(uint256 => EventDetails) public events;

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
        emit EventCreated(eventDetails.eventId, eventDetails.organizer);
    }

    // access to only factory contract
    // function onlyAdmin() private view {
    //     if (msg.sender != admin) {
    //         revert NotAdmin();
    //     }
    // }


    
modifier onlyAdmin() {
    require(msg.sender == admin || isCoOrganizer[msg.sender], "Not authorized");
    _;
}


    // return event details
    function getEventDetails() public view returns (EventDetails memory) {
        return eventDetails;
    }

    // create ticket
    function createTicket(
        uint256[] calldata _ticketVariety,
        uint256[] calldata _amount
    ) external payable onlyAdmin {
          if (_ticketVariety.length > 1) {
            _mintBatch(admin, _ticketVariety, _amount, "");
        } else {
            uint256 _ticket = _ticketVariety[0];
            uint256 _price = _amount[0];
            _mint(admin, _ticket, _price, "");
        }
    }

    // set event URI
    function setEventURI(string memory newUri_) external onlyAdmin {
             _setURI(newUri_);
    }

    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC1155) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    
    function addCoOrganizer(address coOrganizer) external  onlyAdmin {
    // require(msg.sender == admin, "Only the organizer can add co-organizers");
    isCoOrganizer[coOrganizer] = true;
}


    function removeCoOrganizer(address coOrganizer) external  onlyAdmin {
    // require(msg.sender == admin, "Only the organizer can remove co-organizers");
    isCoOrganizer[coOrganizer] = false;
}


function rescheduleEvent(uint256 _eventId, uint256 _newStartTime, uint256 _newEndTime) external onlyAdmin {
    require(_newStartTime > events[_eventId].startTime, "Event has already started");
    // require(_newStartTime > block.timestamp, "New start time must be in the future");
    require(_newEndTime > _newStartTime, "End time must be after start time");


    // EventDetails memory eventDetails = events[_eventId];
    eventDetails.startTime = _newStartTime;
    eventDetails.endTime = _newEndTime;
}

}
