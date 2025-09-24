// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Zer4chStableCoin} from "./Zer4chStableCoin.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/**
 * @title Z4CEngine
 * @author Zer4ch
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our Z4C system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Zer4ch Stablecoin system. It handles all the logic
 * for minting and redeeming Z4C, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */
contract Z4CEngine is ReentrancyGuard {
    error Zer4chStableCoin__mustbemorethanzero();
    error Zer4chStableCoin__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error Zer4chStableCoin__NotZeroAddress();
    error Zer4chStableCoin__NotAllowedToken();
    error Zer4chStablecoin_TransferFailed();

    mapping(address token => address priceFeed) private s_priceFeeds; // token address -> price feed address
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited; // user address -> (token address -> amount deposited)

    Zer4chStableCoin private immutable i_z4c;

    event collateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert Zer4chStableCoin__mustbemorethanzero();
        }
        _;
    }

    modifier isAllowedToken(address _token) {
        if (s_priceFeeds[_token] == address(0)) {
            revert Zer4chStableCoin__NotAllowedToken();
        }
        _;
    }

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address Z4CAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert Zer4chStableCoin__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }
        if (Z4CAddress == address(0)) {
            revert Zer4chStableCoin__NotZeroAddress();
        }
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_priceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
        }
        i_z4c = Zer4chStableCoin(Z4CAddress);
    }

    function depositCollateralAndMintZ4C() external {}

    /**
     * @notice following CEI pattern
     * @notice Users can deposit collateral (ETH or WBTC) and mint Z4C in one transaction
     * @param _tokenCollateral The address of the collateral token to deposit
     */
    function depositCollateral(address _tokenCollateraladdress, uint256 _amountCollateraladdress)
        external
        moreThanZero(_amountCollateraladdress)
        isAllowedToken(_tokenCollateraladdress)
        nonReentrant
    {
        s_collateralDeposited[msg.sender][_tokenCollateraladdress] += _amountCollateraladdress;
        emit collateralDeposited(msg.sender, _tokenCollateraladdress, _amountCollateraladdress);
        bool success = IERC20(_tokenCollateraladdress).transferFrom(msg.sender, address(this), _amountCollateraladdress);
        if (!success) {
            revert Zer4chStablecoin_TransferFailed();
        }
    }

    function redeemCollateralforZ4C() external {}

    function redeemCollateral() external {}

    function mintZ4C() external {}

    function burnZ4C() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}
}
