// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Script} from "lib/forge-std/src/Script.sol";

contract HelperConfig is Script {
    struct networkConfig {
        address wEthUsdPriceFeed;
        address wBtcUsdPriceFeed;
        address wETH;
        address wBTC;
        uint256 deployerKey;
    }

    networkConfig public activeNetworkConfig;

    constructor() {}

    function getSepoliaEthConfig() public view returns (networkConfig memory) {
        return networkConfig({
            wEthUsdPriceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306,
            wBtcUsdPriceFeed: 0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43,
            wETH: 0xdd13E55209Fd76AfE204dBda4007C227904f0a81,
            wBTC: 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063,
            deployerKey: vm.envUint("PRIVATE_KEY")
        });
    }
}
