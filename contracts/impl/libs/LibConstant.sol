// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library LibConstant {

    uint16 constant MAX_AVATAR_ID = 999;

    /*********************************/
    /******* Faithful Status *********/
    /*********************************/
    uint8 constant STATUS_RUNNING = 1;
    uint8 constant STATUS_VRF_PENDING = 2;
    uint8 constant STATUS_INVALID = 3;
}