// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "./Errors.sol";

/**
 * @title Registry
 * @author David, Manoah, Olorunsogo, Olamide, Ayooluwa, and Jubril
 * @notice This is an ens contract that registers an ens by mapping a byte to a struct of ens
 */
contract Registry {
    event ENSRegistered(bytes32 email, address addr);

    struct ENS {
        bytes32 email;
        address walletAddress;
        string avatar;
        bool isRegistered;
    }

    ENS[] users;
    mapping(address => ENS) ensByAddr;
    mapping(bytes32 => ENS) ensByEmail;
    mapping(address => mapping(bytes32 => ENS)) ens;

    /**
     * @dev This function registers an ens it maps a byte32 to a struct of ens
     * @param _user is the address of ENS user
     * @param _email is the email a user want to use for ens
     * @param _avatar a url string that points to the location of the avatar on a decentralized storage
     */
    function registerENS(address _user, string memory _email, string memory _avatar) external {
        bytes32 _emailHash = keccak256(abi.encodePacked(_email));

        if (ens[_user][_emailHash].isRegistered) revert Errors.ALREADY_EXIST();

        ENS memory _ens = ENS(_emailHash, _user, _avatar, true);

        ens[_user][_emailHash] = _ens;

        ensByAddr[_user] = _ens;

        ensByEmail[_emailHash] = _ens;

        users.push(_ens);

        emit ENSRegistered(_emailHash, _user);
    }

    /**
     * @dev This function registers an ens it maps a byte32 to a struct of ens
     * @param _user is the address of ENS user
     * @param _oldEmail is the old email a user used for ens
     * @param _newEmail is the new email a user want to use for ens
     * @param _avatar a url string that points to the location of the avatar on a decentralized storage
     */
    function updateENS(address _user, string memory _oldEmail, string memory _newEmail, string memory _avatar) external {
        bytes32 _oldEmailHash = keccak256(abi.encodePacked(_oldEmail));
        bytes32 _newEmailHash = keccak256(abi.encodePacked(_newEmail));

        if (ens[_user][_newEmailHash].isRegistered) revert Errors.ALREADY_EXIST();

        if (ens[_user][_oldEmailHash].email != _oldEmailHash) revert Errors.EMAIL_MISMATCH();

        delete ens[_user][_oldEmailHash];

        ENS memory _ens = ENS(_newEmailHash, _user, _avatar, true);

        ens[_user][_newEmailHash] = _ens;

        ensByAddr[_user] = _ens;

        ensByEmail[_newEmailHash] = _ens;

        emit ENSRegistered(_newEmailHash, _user);
    }

    /**
     * @dev This is a read function that accepts a user and email then returns a struct of ENS for a user
     * @param _user is the address of ENS user
     * @param _email is the email a user want to use for ens
     */
    function getENS(address _user, string memory _email) external view returns (ENS memory) {
        bytes32 _emailHash = keccak256(abi.encodePacked(_email));
        return ens[_user][_emailHash];
    }

    /**
     * @dev This is a read function that accepts an email and returns a struct of ENS for a user
     * @param _email is the email a user want to use for ens
     */
    function getENSbyEmail(string memory _email) external view returns (ENS memory) {
        bytes32 _emailHash = keccak256(abi.encodePacked(_email));
        return ensByEmail[_emailHash];
    }

    /**
     * @dev This read function returns all the ens saved in the system
     */
    function getAllENS() external view returns (ENS[] memory) {
        return users;
    }

    /**
     * @dev This function returns an ens using address
     * @param _user is the email a user want to use for ens
     */
    function getENSByAddress(address _user) external view returns (ENS memory) {
        return ensByAddr[_user];
    }
}