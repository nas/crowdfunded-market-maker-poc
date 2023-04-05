// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// Uncomment this line to use console.log
import "hardhat/console.sol";

import {ERC20Interface} from "./interface/ERC20Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MarketMakingStrategy is Ownable {
    enum StateName {
        PENDING,
        RUNNING,
        EXPIRED
    }
    StateName state;

    // This represents a single participant in a strategy
    struct Participant {
        uint amount; // number of tokens, e.g. 100
        string token; // token symbol, e.g. USDC
    }

    // This declares a state variable that
    // stores a `Participant` struct for each possible address.
    mapping(address => Participant) public participants;

    mapping(string => uint) public depositPool;
    // {
    //  usdc: 1200,
    //  usdt: 700
    // }

    event Claim(uint amount, uint when, address from);
    event Deposit(uint amount, uint when, address from);

    modifier onlyPending() {
        require(
            state == StateName.PENDING,
            "Operation can only be performed when Strategy is in Pending State"
        );
        _;
    }

    // If on deploying on mainnet then ETH, if on Polygon MATIC, etc.
    modifier ifNativeTokenAccepted() {
        require(
            keccak256(bytes(token1)) == keccak256(bytes(nativeToken)) ||
                keccak256(bytes(token2)) == keccak256(bytes(nativeToken)),
            "None of the pairs accept a native token"
        );
        _;
    }

    /// Passes when the strategy state is RUNNING
    modifier onlyRunning() {
        require(
            state == StateName.RUNNING,
            "Operation can only be performed when Strategy is Running"
        );
        _;
    }

    /// Passes when the strategy state is EXPIRED
    modifier onlyExpired() {
        require(
            state == StateName.EXPIRED,
            "Strategy must expire before running this operation."
        );
        _;
    }

    string token1;
    string token2;
    string nativeToken;
    address erc20ContractAddress1;
    address erc20ContractAddress2;
    bool locked = false;

    /// @notice Constructor function
    /// @param _nativeToken we are passing native token symbol so we can deploy contract instances on different EVM chains and accept them as deposits
    /// @param _erc20ContractAddress1 contract address of the first token of the pair used in Strategy
    /// @param _erc20ContractAddress2 contract address of the second token of the pair used in Strategy
    constructor(
        string memory _nativeToken,
        address _erc20ContractAddress1,
        address _erc20ContractAddress2
    ) {
        state = StateName.PENDING;
        nativeToken = _nativeToken;

        erc20ContractAddress1 = address(_erc20ContractAddress1);
        erc20ContractAddress2 = address(_erc20ContractAddress2);

        ERC20Interface erc20Contract;

        // This is only used to check if the token is native or ERC20
        // Either pair can be native
        address noErc = 0x0000000000000000000000000000000000000000;
        if (_erc20ContractAddress1 == noErc) {
            token1 = nativeToken;
        } else {
            erc20Contract = ERC20Interface(erc20ContractAddress1);
            token1 = erc20Contract.symbol();
        }

        if (_erc20ContractAddress2 == noErc) {
            token2 = nativeToken;
        } else {
            erc20Contract = ERC20Interface(erc20ContractAddress2);
            token2 = erc20Contract.symbol();
        }

        depositPool[token1] = 0;
        depositPool[token2] = 0;
    }

    function claim() external onlyExpired returns (bool) {
        require(!locked, "Reentrant call detected!");
        locked = true;
        Participant storage claimant = participants[msg.sender];
        uint amount = claimant.amount;

        // for ETH
        // address payable participant = payable(address(msg.sender));
        // bool success = true;
        (bool success, ) = msg.sender.call{value: amount}("");

        // some logic to convert their tokens and send them
        locked = false;
        emit Claim(amount, block.timestamp, msg.sender);
        return (success);
    }

    // can only be deposited if strategy hasn't started yet
    function deposit(
        uint amount,
        string calldata tokenSymbol
    ) external payable onlyPending returns (bool) {
        require(
            keccak256(bytes(tokenSymbol)) == keccak256(bytes(token1)) ||
                keccak256(bytes(tokenSymbol)) == keccak256(bytes(token2)),
            "Wrong token sent."
        );

        ERC20Interface erc20Contract = ERC20Interface(
            address(erc20ContractAddress2)
        );

        if (keccak256(bytes(tokenSymbol)) != keccak256(bytes(nativeToken))) {
            bool success = erc20Contract.transferFrom(
                msg.sender,
                address(this),
                amount
            );

            updateParticipantAndPool(tokenSymbol, amount);

            return (success);
        } else {
            return (false);
        }
    }

    // only accept eth if it's part of the pair
    receive() external payable ifNativeTokenAccepted {
        if (keccak256(bytes(token1)) == keccak256(bytes(nativeToken))) {
            depositPool[token1] += msg.value;
        } else if (keccak256(bytes(token2)) == keccak256(bytes(nativeToken))) {
            depositPool[token2] += msg.value;
        }

        updateParticipantAndPool(nativeToken, msg.value);
    }

    function updateParticipantAndPool(
        string memory tokenSymbol,
        uint amount
    ) internal {
        Participant memory participant = participants[msg.sender];
        require(
            keccak256(bytes(participant.token)) !=
                keccak256(bytes(tokenSymbol)),
            "Participant already has a token locked"
        );

        participant.amount += amount;
        participant.token = tokenSymbol;

        depositPool[tokenSymbol] += amount;

        emit Deposit(amount, block.timestamp, msg.sender);
    }

    function balance() public view returns (uint) {
        return address(this).balance;
    }

    // can only be started if the strategy is in pending state
    // can only be kicked off by the owner of the Strategy
    function start() external onlyOwner onlyPending returns (string memory) {
        state = StateName.RUNNING;
        // start using GRIDEX now
        return "strategy started";
    }

    // can only be stopped if the strategy is in running state
    // can only be stopped by the owner of the strategy unless the owner transfers the ownership
    function stop() external onlyOwner onlyRunning returns (string memory) {
        state = StateName.EXPIRED;
        // get the money out of gridex now
        // now money can be taken out by all depositors
        return "strategy stopped";
    }

    // Owner can transfer the ownership using transferOwnership method from Ownable
}
