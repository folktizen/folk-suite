// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.24;

//////////////////////////////////////////////////////////////////////////////////////
// @title   Folktizen
// @notice  Folktizen is a vibrant marketplace on Polygon where creators can mint
//          their collections and assign customizable agents to manage and promote
//          them. These agents can be tailored with specific activation frequencies,
//          custom instructions, and other essential criteria.​
//          more at: https://folktizen.xyz
// @version 0.5.0
// @author  Folktizen Labs
//////////////////////////////////////////////////////////////////////////////////////

import "./SkypodAccessControls.sol";
import "./SkypodErrors.sol";
import "./SkypodLibrary.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract SkypodUserManager {
    SkypodAccessControls public accessControls;
    string public symbol;
    string public name;
    mapping(address => mapping(address => uint256)) private _userDeposited;
    mapping(address => mapping(address => bool)) private _allowDeposit;
    mapping(address => mapping(address => uint256)) private _allowedDeposit;

    event TokensReceived(address token, address user, uint256 amount);
    event UserWithdraw(address token, address user, uint256 amount);
    event DepositEnabled(address user, address token, bool allow);
    event DepositAllowance(address user, address token, uint256 allowance);
    event DepositUsed(
        address user,
        address token,
        address verifiedContract,
        uint256 amount
    );

    modifier onlyAdmin() {
        if (!accessControls.isAdmin(msg.sender)) {
            revert SkypodErrors.NotAdmin();
        }
        _;
    }

    modifier onlyVerifiedContract() {
        if (!accessControls.isVerifiedContract(msg.sender)) {
            revert SkypodErrors.NotVerifiedContract();
        }
        _;
    }

    constructor(address payable _accessControls) payable {
        accessControls = SkypodAccessControls(_accessControls);
        name = "SkypodUserManager";
        symbol = "SUM";
    }

    function receiveTokensUser(address token, uint256 amount) public {
        if (!accessControls.isAcceptedToken(token)) {
            revert SkypodErrors.TokenNotAccepted();
        }

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        _userDeposited[msg.sender][token] += amount;

        emit TokensReceived(token, msg.sender, amount);
    }

    function withdrawDeposited(address token, uint256 amount, bool max) public {
        if (amount > _userDeposited[msg.sender][token]) {
            revert SkypodErrors.InvalidFunds();
        }

        if (max) {
            if (
                IERC20(token).transfer(
                    msg.sender,
                    _userDeposited[msg.sender][token]
                )
            ) {
                _userDeposited[msg.sender][token] = 0;
            }
        } else {
            if (IERC20(token).transfer(msg.sender, amount)) {
                _userDeposited[msg.sender][token] -= amount;
            }
        }

        emit UserWithdraw(token, msg.sender, amount);
    }

    function enableDepositUse(address token, bool allow) public {
        _allowDeposit[msg.sender][token] = allow;

        emit DepositEnabled(msg.sender, token, allow);
    }

    function setDepositAllowance(address token, uint256 allowance) public {
        _allowedDeposit[msg.sender][token] = allowance;

        emit DepositAllowance(msg.sender, token, allowance);
    }

    function useDeposited(
        address token,
        address user,
        uint256 amount
    ) external onlyVerifiedContract {
        if (!_allowDeposit[user][token]) {
            revert SkypodErrors.UseNotAllowed();
        }

        if (amount > _allowedDeposit[user][token]) {
            revert SkypodErrors.InvalidUseAmount();
        }

        IERC20(token).transfer(msg.sender, amount);

        _userDeposited[user][token] -= amount;

        emit DepositUsed(user, token, msg.sender, amount);
    }

    function setAccessControls(
        address payable _accessControls
    ) public onlyAdmin {
        accessControls = SkypodAccessControls(_accessControls);
    }

    function getUserTokenBalance(
        address user,
        address token
    ) public view returns (uint256) {
        return _userDeposited[user][token];
    }

    function getUserDepositAllowed(
        address user,
        address token
    ) public view returns (bool) {
        return _allowDeposit[user][token];
    }

    function getUserDepositAllowance(
        address user,
        address token
    ) public view returns (uint256) {
        return _allowedDeposit[user][token];
    }

    function emergencyWithdraw(
        uint256 amount,
        uint256 gasAmount
    ) external onlyAdmin {
        (bool success, ) = payable(msg.sender).call{
            value: amount,
            gas: gasAmount
        }("");
        if (!success) {
            revert SkypodErrors.TransferFailed();
        }
    }

    receive() external payable {}

    fallback() external payable {}
}
