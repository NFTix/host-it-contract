// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.25;

import "./EventContract.sol";

contract EventFactory {
    uint256 eventId;

    mapping(uint256 => EventContract) eventMapping;
    EventContract[] eventArray;

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
        EventContract newEvent = new EventContract(
            ++eventId,
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
        eventArray.push(newEvent);
    }

    function getEvent(
        uint256 _eventId
    ) external view returns (EventContract.EventDetails memory) {
        return (eventMapping[_eventId].getEventDetails());
    }
}
