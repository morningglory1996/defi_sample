// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";

contract TokenFarm {
    string public name = "Dapp Token Farm";
    address public owner;

    IERC20 public dappToken;
    IERC20 public daiToken;

    address[] public stakers;
    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;

    constructor(IERC20 _dappTokenAddress, IERC20 _daiTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
        daiToken = IERC20(_daiTokenAddress);
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
                dappToken.transfer(recipient, getCalculatedAmount(balance));
            }
        }
    }

    function getCalculatedAmount(uint256 _balance)
        public
        view
        returns (uint256)
    {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x777A68032a88E5A84678A77Af2CD65A7b3c0775a
        );
        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();

        require(timeStamp > 0, "Round not complete");
        uint256 calculatedAmount = (_balance * uint256(price * (10**10))) /
            (10**18);
        return calculatedAmount;
    }
}
