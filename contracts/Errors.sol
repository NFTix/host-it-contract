// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

library Errors {
    // errors
    error NOT_ADMIN();
    error INVALID_INPUT();
    error INPUT_MISMATCH();
    error INSUFFICIENT_AMOUNT();
    error UNREGISTERED_USER();

    // Registry errors
    error ALREADY_EXIST();
    error ADDRESS_ZERO();
    error EMAIL_MISMATCH();
}
