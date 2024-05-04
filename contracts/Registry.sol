// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

/// @notice this is an ens contract that registers an ens by mapping a byte to a struct of ens
contract Registry {
    error ALREADY_EXIST();
    error ADDRESS_ZERO();

    event ENSRegistered(bytes32 email, address addr);

    struct ENS {
        bytes32 email;
        address walletAddress;
        string avatar;
        bool isRegistered;
    }

    ENS[] users;
    mapping(address => ENS) ensByAddr;
    mapping(address => mapping(bytes32 => ENS)) ens;

    /// @notice this function registers an ens it maps a byte32 to a struct of ens
    /// @param _email is the name user want to use for. ens
    /// @param _avatar a url string that points to the location of the avatar on a decentralized storage
    function registerENS(string memory _email, string memory _avatar) external {
        bytes32 _emailHash = keccak256(abi.encodePacked(_email));

        if (ens[msg.sender][_emailHash].isRegistered) revert ALREADY_EXIST();

        ENS memory _ens = ENS(_emailHash, msg.sender, _avatar, true);

        ens[msg.sender][_emailHash] = _ens;

        ensByAddr[msg.sender] = _ens;

        users.push(_ens);

        emit ENSRegistered(_emailHash, msg.sender);
    }

    /// @notice this function registers an ens it maps a byte32 to a struct of ens
    /// @param _oldEmail is the name user want to use for. ens
    /// @param _newEmail is the name user want to use for. ens
    /// @param _avatar a url string that points to the location of the avatar on a decentralized storage
    function updateENS(string memory _oldEmail, string memory _newEmail, string memory _avatar) external {
        bytes32 _oldEmailHash = keccak256(abi.encodePacked(_oldEmail));
        bytes32 _newEmailHash = keccak256(abi.encodePacked(_newEmail));

        if (ens[msg.sender][_newEmailHash].isRegistered) revert ALREADY_EXIST();

        delete ens[msg.sender][_oldEmailHash];

        ENS memory _ens = ENS(_newEmailHash, msg.sender, _avatar, true);

        ens[msg.sender][_newEmailHash] = _ens;

        ensByAddr[msg.sender] = _ens;

        emit ENSRegistered(_newEmailHash, msg.sender);
    }

    /// @notice this is a read function that accepts an ens and returns a struct of ENS for a user
    /// @param _email is the name user want to use for. ens
    function getENS(string memory _email) external view returns (ENS memory) {
        bytes32 _emailHash = keccak256(abi.encodePacked(_email));
        return ens[msg.sender][_emailHash];
    }

    /// @notice this function returns all the ens saved in the system
    function getAllENS() external view returns (ENS[] memory) {
        return users;
    }

    /// @notice this function returns an ens using address
    function getENSByAddress() external view returns (ENS memory) {
        return ensByAddr[msg.sender];
    }
}
