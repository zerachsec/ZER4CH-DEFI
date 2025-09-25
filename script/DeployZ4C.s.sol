// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Zer4chStableCoin} from "../src/Zer4chStableCoin.sol";
import {Z4CEngine} from "../src/Z4CEngine.sol";
import {Script} from "lib/forge-std/src/Script.sol";

contract DeployZ4C is Script {
    function run() external returns (Z4CEngine, Zer4chStableCoin) {
        vm.startBroadcast();
        Zer4chStableCoin z4c = new Zer4chStableCoin();
        vm.stopBroadcast();
    }
}
