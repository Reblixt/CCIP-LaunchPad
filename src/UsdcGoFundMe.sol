// SPDX-License-Identifier: MIT

/*
 * This contract is a goFundMe contract that allows user to donate to a cause.
 * The cotract has an owner, a goal, a deadline, a balance and a mapping of contributions.
 * This contract will be initialized from a user on another contract and the user will be the owner of this contract/project.
 * The owner will be able to set the goal and deadline of the campaign.
 * The owner will be able to withdraw the funds after the deadline has passed and the goal has been reached.
 * The contributors will be able to contribute to the campaign. and will have the ability to fund from a
 * different blockchain thrue CCIP (Cross-Chain Interoperability Protocol) from chainlink.
 
 */

pragma solidity ^0.8.25;

import {Constants} from "./constants/Constants.c.sol";
import {SafeERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC20} from "@chainlink/contracts-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.3/contracts/token/ERC20/ERC20.sol";

contract GoFundMe {
    using SafeERC20 for ERC20;

    error NotOwner();
    error NotEnoughFunds();
    error InvalidUsdcsToken();
    error increaseAllowance();

    ERC20 public usdc;
    string public projectName;
    uint256 public goalInUsd;
    uint256 public totalBalance; // The total amount of funds that have been raised.
    address[] public funders; // Creates a list of funderns that the frontend can use together with m_donations to display the funders and the amount they donated.
    address public immutable i_owner;
    address public usdcTokenAddress;
    bool private hasBeenSet = false;
    bool private ProjectIsComplete = false;

    mapping(address => uint256) public m_donations; // A mapping of the donations that have been made by the funders.

    modifier onlyOwner() {
        if (msg.sender != i_owner) revert NotOwner();
        _;
    }

    constructor(address _usdcTokenAddress, address _owner) {
        i_owner = _owner;
        if (_usdcTokenAddress == address(0)) revert InvalidUsdcsToken();
        usdc = ERC20(_usdcTokenAddress);
        usdcTokenAddress = _usdcTokenAddress;
    }

    event FundReceived(address indexed funder, uint256 amount);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    function SetNameAndGoal(
        string memory _projectName,
        uint256 _goalInUsd
    ) external onlyOwner {
        require(!hasBeenSet, "Name and goal has already been set");
        projectName = _projectName;
        goalInUsd = _goalInUsd * Constants.USD_DECIMALS;
        hasBeenSet = true;
    }

    function approveFunding(uint256 _amount) external {
        require(!ProjectIsComplete, "Project is already complete");
        uint256 amountInDecimals = _amount * Constants.USD_DECIMALS;

        usdc.safeApprove(address(this), amountInDecimals);
    }

    function fund(uint256 _amount) external {
        require(!ProjectIsComplete, "Project is already complete");
        uint256 amountInDecimals = _amount * Constants.USD_DECIMALS;
        if (!boolAllowence(amountInDecimals)) revert increaseAllowance();
        require(
            usdc.transferFrom(msg.sender, address(this), amountInDecimals),
            "Transfer failed"
        );

        m_donations[msg.sender] += amountInDecimals;
        totalBalance += amountInDecimals;
        funders.push(msg.sender);

        emit FundReceived(msg.sender, amountInDecimals);
    }

    function withdraw() external onlyOwner {
        require(totalBalance >= goalInUsd, "Goal not reached");

        uint256 amount = usdc.balanceOf(address(this));
        usdc.safeTransfer(i_owner, amount);
        totalBalance = 0;
        ProjectIsComplete = true;
        emit FundsWithdrawn(i_owner, amount);
    }

    function withdrawIftotalBalanceIsZero() external onlyOwner {
        require(totalBalance < 1, "Total balance is not zero");
        uint256 amount = usdc.balanceOf(address(this));
        usdc.safeTransfer(i_owner, amount);
        emit FundsWithdrawn(i_owner, amount);
    }

    function boolAllowence(uint256 _amount) internal view returns (bool) {
        return usdc.allowance(msg.sender, address(this)) >= _amount;
    }

    function getContractUSDCBalance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    function getSignerUSDCBalance() external view returns (uint256) {
        return usdc.balanceOf(msg.sender);
    }

    function getSignerUSDCAllowance() external view returns (uint256) {
        return usdc.allowance(msg.sender, address(this));
    }

    function getUsdAddress() external view returns (address) {
        return usdcTokenAddress;
    }

    function getFunder(uint256 i) external view returns (address) {
        return funders[i];
    }

    function getTotalBalance() external view returns (uint256) {
        return totalBalance;
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }

    receive() external payable {
        revert("This contract does not accept ether");
    }
}
