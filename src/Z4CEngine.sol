// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Zer4chStableCoin} from "./Zer4chStableCoin.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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
    error Z4CEngine__mustbemorethanzero();
    error Z4CEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
    error Z4CEngine__NotAllowedToken();
    error Z4CEngine_TransferFailed();
    error Z4CEngine__HealthFactorIsBroken(uint256 healthFactor);
    error Z4CEngine_MintFailed();

    uint256 private constant ADDITIONAL_FEED_PRECISION = 1e10; // to bring the price feed to 18 decimals
    uint256 private constant PRECESION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50; // 200% overcollateralized
    uint256 private constant LIQUIDATION_PRECESION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1; // 1x minimum health factor

    mapping(address token => address priceFeed) private s_PriceFeeds; // token address -> price feed address
    mapping(address user => mapping(address token => uint256 amount)) private s_collateralDeposited; // user address -> (token address -> amount deposited)
    mapping(address user => uint256 Z4Cminted) private s_Z4Cminted; // user address -> Z4C minted
    address[] private s_collateralTokens;

    Zer4chStableCoin private immutable i_z4c;

    event collateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    modifier moreThanZero(uint256 _amount) {
        if (_amount <= 0) {
            revert Z4CEngine__mustbemorethanzero();
        }
        _;
    }

    modifier isAllowedToken(address _token) {
        if (s_PriceFeeds[_token] == address(0)) {
            revert Z4CEngine__NotAllowedToken();
        }
        _;
    }

    constructor(address[] memory tokenAddresses, address[] memory priceFeedAddresses, address Z4CAddress) {
        if (tokenAddresses.length != priceFeedAddresses.length) {
            revert Z4CEngine__TokenAddressesAndPriceFeedAddressesMustBeSameLength();
        }

        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            s_PriceFeeds[tokenAddresses[i]] = priceFeedAddresses[i];
            s_collateralTokens.push(tokenAddresses[i]);
        }
        i_z4c = Zer4chStableCoin(Z4CAddress);
    }

    function depositCollateralAndMintZ4C() external {}

    /**
     * @notice following CEI pattern
     * @notice Users can deposit collateral (ETH or WBTC) and mint Z4C in one transaction
     * @param _tokenCollateraladdress The address of the collateral token to deposit
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
            revert Z4CEngine_TransferFailed();
        }
    }

    function redeemCollateralforZ4C() external {}

    function redeemCollateral() external {}

    function mintZ4C(uint256 _amountZ4CTomint) external moreThanZero(_amountZ4CTomint) nonReentrant {
        s_Z4Cminted[msg.sender] += _amountZ4CTomint;
        _revertIfHealthFactorIsBroken(msg.sender);
        bool minted = i_z4c.mint(msg.sender, _amountZ4CTomint);
        if (!minted) {
            revert Z4CEngine_MintFailed();
        }
    }

    function burnZ4C() external {}

    function liquidate() external {}

    function getHealthFactor() external view {}

    // Private & Internal Functions //

    function _getAccountInformation(address _user)
        private
        view
        returns (uint256 totalCollateralValueInUSD, uint256 totalZ4CMinted)
    {
        totalZ4CMinted = s_Z4Cminted[_user];
        totalCollateralValueInUSD = _getAccountCollateralValue(_user);
    }

    function _healthFactor(address _user) private view returns (uint256) {
        (uint256 totalCollateralValueInUSD, uint256 totalZ4CMinted) = _getAccountInformation(_user);
        uint256 collateralAdjustedForThreshold =
            (totalCollateralValueInUSD * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECESION;
        return (collateralAdjustedForThreshold * PRECESION) / totalZ4CMinted;
    }

    function _revertIfHealthFactorIsBroken(address _user) internal view {
        //1.check health factor
        //2. revert if they dont
        uint256 userHealthFactor = _healthFactor(_user);
        if (userHealthFactor < MIN_HEALTH_FACTOR) {
            revert Z4CEngine__HealthFactorIsBroken(userHealthFactor);
        }
    }

    //public and Enternal View Functions//
    function _getAccountCollateralValue(address _user) public view returns (uint256 totatcollateralValueInUSD) {
        for (uint256 i = 0; i < s_collateralTokens.length; i++) {
            address token = s_collateralTokens[i];
            uint256 amount = s_collateralDeposited[_user][token];
            totatcollateralValueInUSD += getValueUSD(token, amount);
            return totatcollateralValueInUSD;
        }
    }

    function getValueUSD(address _token, uint256 _amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_PriceFeeds[_token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return (uint256(price) * ADDITIONAL_FEED_PRECISION * _amount) / PRECESION;
    }
}
