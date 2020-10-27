// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "./DappToken.sol";
import "./DaiToken.sol";

contract TokenFarm {
    string public name = "Dapp Token Farm";
    address public owner;

    DappToken public dappToken;
    DaiToken public daiToken;

    address[] public stakers;
    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(DappToken _dappToken, DaiToken _daiToken) public {
        dappToken = _dappToken;
        daiToken = _daiToken;
        owner = msg.sender;
    }

    function stakeTokens(uint256 _amount) public {
        require(_amount > 0);
        daiToken.transferFrom(msg.sender, address(this), _amount);
        stakingBalance[msg.sender] += _amount;
        // stakeしたことないaccountのみpush
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender);
        }
        isStaking[msg.sender] = true;
        hasStaked[msg.sender] = true;
    }

    function unstakeTokens() public {
        uint256 balance = stakingBalance[msg.sender];
        require(balance > 0);
        require(isStaking[msg.sender]);
        daiToken.transfer(msg.sender, balance);
        stakingBalance[msg.sender] = 0;
        isStaking[msg.sender] = false;
    }

    function issueTokens() public {
        require(msg.sender == owner);
        // すべてのstakersにDAppを配布
        for (uint256 i = 0; i < stakers.length; i++) {
            address recipient = stakers[i];
            uint256 balance = stakingBalance[recipient];
            if (balance > 0 && isStaking[recipient]) {
                dappToken.transfer(recipient, balance);
            }
        }
    }
}
