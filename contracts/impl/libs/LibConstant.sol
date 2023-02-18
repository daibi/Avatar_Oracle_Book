// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

library LibConstant {

    uint16 constant MAX_AVATAR_ID = 999;
    uint8 constant NORMAL_AVATAR_START_ID = 100;
    uint16 constant AVATAR_TYPE_NUM = 12;

    /*********************************/
    /******** Avatar Status **********/
    /*********************************/
    uint8 constant STATUS_RUNNING = 1;
    uint8 constant STATUS_VRF_PENDING = 2;
    uint8 constant STATUS_INVALID = 3;

    /*********************************/
    /********* Avatar Rank ***********/
    /*********************************/
    uint8 constant AVATAR_RANK_EGG = 1;
    uint8 constant AVATAR_RANK_SEED = 2;
    uint8 constant AVATAR_RANK_SPIRIT = 3;
    uint8 constant AVATAR_RANK_DOPPELGANGER = 4;

    /*********************************/
    /******* VRF Render Scene ********/
    /*********************************/
    uint8 constant REQUEST_SCENE_AVATAR_RENDER = 1;


    /********************************************/
    /******* Chainlink Request Constants ********/
    /********************************************/
    address constant SENDER_OVERRIDE = address(0);
    uint256 constant AMOUNT_OVERRIDE = 0;
    uint256 constant ORACLE_ARGS_VERSION = 1;


    /****************************/
    /******* Boost Slots ********/
    /****************************/
    uint8 constant WEATHER_BOOST_SLOT = 1;
}