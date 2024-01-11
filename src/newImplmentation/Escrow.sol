// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract Escrow {
    address private immutable owner;
    bool private paused;
    address private questContract;
    address private immutable ecosystemContract;
    mapping(address => mapping(uint256 => uint256)) private balances;

    event ContractPaused(bool status);
    event FundsDeposited(address indexed token, uint256 indexed brandId, uint256 amount);
    event FundsTransferred(address indexed token, address recipient, uint256 amount);

    constructor(address _questContract, address _ecosystemContract) {
        owner = msg.sender;
        questContract = _questContract;
        ecosystemContract = _ecosystemContract;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier onlyAuthorizedContracts() {
        require(msg.sender == ecosystemContract || msg.sender == questContract, "Caller is not authorized");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function deposit(address tokenAddress, uint256 brandId, uint256 amount) external whenNotPaused onlyAuthorizedContracts {
        IERC20 token = IERC20(tokenAddress);
        require(token.transferFrom(msg.sender, address(this), amount), "Transfer failed");
        balances[tokenAddress][brandId] += amount;
        emit FundsDeposited(tokenAddress, brandId, amount);
    }

    function transferFunds(address tokenAddress, uint256 brandId, uint256 amount, address recipient) external onlyAuthorizedContracts {
        require(balances[tokenAddress][brandId] >= amount, "Insufficient balance in escrow");
        IERC20 token = IERC20(tokenAddress);
        balances[tokenAddress][brandId] -= amount;
        require(token.transfer(recipient, amount), "Transfer failed");
        emit FundsTransferred(tokenAddress, recipient, amount);
    }

    function getBalance(address tokenAddress, uint256 brandId) external view returns (uint256) {
        return balances[tokenAddress][brandId];
    }

    function pauseUnpause() external onlyOwner {
        paused = !paused;
        emit ContractPaused(paused);
    }
}
