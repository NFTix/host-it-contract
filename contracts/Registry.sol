// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @notice this is an ens contract that registers an ens by mapping a byte to a struct of ens
contract Registry {
    error ALREADY_EXIST();
    error ADDRESS_ZERO();

    event EnsRegistered(string name, address addr);

    struct Ens {
        string name;
        address walletAddress;
        string avatar;
        bool isRegistered;
    }

    Ens[] users;
    mapping(bytes32 => Ens) ens;
    mapping(address => Ens) ensByAddr;

    /// @notice this function registers an ens it maps a byte32 to a struct of ens
    /// @param _name is the name user want to use for. ens
    /// @param _avatar a url string that points to the location of the avatar on a decentralized storage
    function registerEns(string memory _name, string memory _avatar) external {
        bytes32 _nameHash = keccak256(abi.encodePacked(_name));

        if (ens[_nameHash].isRegistered) revert ALREADY_EXIST();

        Ens memory _ens = Ens(_name, msg.sender, _avatar, true);

        ens[_nameHash] = _ens;

        users.push(_ens);

        emit EnsRegistered(_name, msg.sender);
    }

    /// @notice this is a read function that accepts an ens and returns a struct of Ens for a user
    /// @param _name is the name user want to use for. ens
    function getEns(string memory _name) external view returns (Ens memory) {
        bytes32 _nameHash = keccak256(abi.encodePacked(_name));
        return ens[_nameHash];
    }

    /// @notice this function returns all the ens saved in the system
    function getAllEns() external view returns (Ens[] memory) {
        return users;
    }

    // @notice this function returns an ens using address
    function getEnsByAddress() external view returns (Ens memory) {
        return ensByAddr[msg.sender];
    }

    // @notice this function returns an ens struct using _ens string
    function getEnsByBytes() external view returns (Ens memory) {}
}
