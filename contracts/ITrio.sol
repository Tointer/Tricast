// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;  

interface ITrio{
    function forBuyMarket(uint denominatorAmount) external;

    function forBuyLimit(uint synthAmount, uint8 priceForEach) external;

    function forSellMarket(uint synthAmount) external;

    function forSellLimit(uint synthAmount, uint8 priceForEach) external;

    function againstBuyMarket(uint denominatorAmount) external;

    function againstBuyLimit(uint synthAmount, uint8 priceForEach) external;

    function againstSellMarket(uint synthAmount) external;

    function againstSellLimit(uint synthAmount, uint8 priceForEach) external;
}