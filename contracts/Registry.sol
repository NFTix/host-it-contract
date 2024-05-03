// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @notice this is an ens contract that registers an ens by mapping a byte to a struct of ens
contract Registry {
    error ALREADY_EXIST();
    error ADDRESS_ZERO();

    event EnsRegistered(string email, address addr);

    struct Ens {
        bytes32 email;
        address walletAddress;
        string avatar;
        bool isRegistered;
    }

    Ens[] users;
    mapping(bytes32 => Ens) ens;
    mapping(address => Ens) ensByAddr;

    /// @notice this function registers an ens it maps a byte32 to a struct of ens
    /// @param _email is the name user want to use for. ens
    /// @param _avatar a url string that points to the location of the avatar on a decentralized storage
    function registerEns(string memory _email, string memory _avatar) external {
        bytes32 _emailHash = keccak256(abi.encodePacked(_email));

        if (ens[_emailHash].isRegistered) revert ALREADY_EXIST();

        Ens memory _ens = Ens(_emailHash, msg.sender, _avatar, true);

        ens[_emailHash] = _ens;

        ensByAddr[msg.sender] = _ens;

        users.push(_ens);

        emit EnsRegistered(_email, msg.sender);
    }

    /// @notice this is a read function that accepts an ens and returns a struct of Ens for a user
    /// @param _email is the name user want to use for. ens
    function getEns(string memory _email) external view returns (Ens memory) {
        bytes32 _emailHash = keccak256(abi.encodePacked(_email));
        return ens[_emailHash];
    }

    /// @notice this function returns all the ens saved in the system
    function getAllEns() external view returns (Ens[] memory) {
        return users;
    }

    /// @notice this function returns an ens using address
    function getEnsByAddress() external view returns (Ens memory) {
        return ensByAddr[msg.sender];
    }

    /// @notice this function returns an ens struct using _ens string
    function getEnsByBytes() external view returns (Ens memory) {
        return ens[keccak256(abi.encodePacked("ens"))];
    }
}
