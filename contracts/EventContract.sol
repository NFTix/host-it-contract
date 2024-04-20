// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EventContract is ERC1155 {
    // contract events
    event EventCreated(uint256 indexed eventId, address indexed organizer);
    event TicketPurchased();

    // Global admin
    address admin;

    // Event variables
    uint256 eventId;
    string eventName;
    address organizer;
    uint256 date;
    uint256 startTime;
    uint256 endTime;
    bool isPaid;
    string location;
    string description;
    bool hasEnded;
    bytes eventData;

    constructor(
        string memory _eventName,
        uint256 _date,
        uint256 _startTime,
        uint256 _endTime,
        bool _isPaid,
        string memory _description
    ) ERC1155("") {
        admin = msg.sender;
        eventId += 1;
        eventName = _eventName;
        organizer = msg.sender;
        date = _date;
        startTime = _startTime;
        endTime = _endTime;
        isPaid = _isPaid;
        description = _description;
        hasEnded = false;
        eventData = abi.encodePacked(eventId, eventName, organizer, date);
    }

    function CreateTicket(
        uint256[] calldata _ticketVariety,
        uint256[] calldata _prices
    ) external {
        bytes memory _data = eventData;
        if (_ticketVariety.length > 1) {
            _mintBatch(address(this), _ticketVariety, _prices, _data);
        } else {
            uint256 _ticket = _ticketVariety[0];
            uint256 _price = _prices[0];
            _mint(address(this), _ticket, _price, _data);
        }
    }
}
