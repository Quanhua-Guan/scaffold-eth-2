// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

// call happyBet: guess a random number between [1,2,3] with less than or equal to 0.0008 ether value.
// call angryBet: guess a random number between [1,2,..,100] with less than or equal to 8 ether value.
// call claimBet: check if guess the right number, if so, win double ether value. if not the money is lost.
contract FutureRandom is Ownable {
    struct Bet {
        uint256 blockNumber;
        bool claimed;
        bool isAngry;
        uint256 guess;
        uint256 value;
    }

    mapping(address => Bet) public bets;
    uint256 public blocksToWait;

    uint256 public happyBetCount;
    uint256 public angryBetCount;

    event HappyBet(address indexed from, uint256 value, uint256 guess);
    event AngryBet(address indexed from, uint256 value, uint256 guess);
    event ClaimBet(address indexed from, uint256 guess, uint256 blockNumber, bool win);

    constructor(uint256 _blocksToWait) {
        blocksToWait = _blocksToWait;
    }

    function happyBet(uint256 _guess) public payable {
        require(bets[msg.sender].blockNumber == 0, "Already placed a bet");
        require(msg.value <= 0.0008 ether, "Invalid ETH value");
        require(_guess >= 1 && _guess <= 3, "Invalid Guess");

        // send 1% to the owner
	uint256 fee = msg.value / 100;
        (bool success, ) = payable(owner()).call{ value: fee }("");
        require(success, "Fail to support owner");

        happyBetCount += 1;

        bets[msg.sender] = Bet(
            block.number,
            false,
            false,
            _guess,
            msg.value - fee
        );

	emit HappyBet(msg.sender, msg.value, _guess);
    }

    function angryBet(uint256 _guess) public payable {
        require(bets[msg.sender].blockNumber == 0, "Already placed a bet");
        require(msg.value <= 8 ether, "Invalid ETH value");
        require(
            msg.value * 2 <= address(this).balance,
            "Can't claim even if you win"
        );
        require(_guess >= 1 && _guess <= 100, "Invalid Guess");

        // send 1% to the owner
        uint256 fee = msg.value / 100;
        (bool success, ) = payable(owner()).call{ value: fee }("");
        require(success, "Fail to support owner");

        angryBetCount += 1;

        bets[msg.sender] = Bet(
            block.number,
            false,
            true,
            _guess,
            msg.value - fee
        );

	emit AngryBet(msg.sender, msg.value, _guess);
    }

    function getRandomNumber() internal view returns (uint256) {
        Bet memory bet = bets[msg.sender];
        require(bet.blockNumber != 0, "No bet placed");
        require(
            block.number > bet.blockNumber + blocksToWait,
            "Blocks to wait not passed"
        );

        bytes32 combinedHash = keccak256(
            abi.encodePacked(blockhash(bet.blockNumber + 1))
        );
        for (uint256 i = 2; i <= blocksToWait; i++) {
            combinedHash = keccak256(
                abi.encodePacked(combinedHash, blockhash(bet.blockNumber + i))
            );
        }

        return uint256(combinedHash);
    }

    function claimBet() public returns (bool) {
        Bet storage bet = bets[msg.sender];
        require(bet.blockNumber != 0, "No bet placed");
        require(!bet.claimed, "Already claimed");
        require(
            block.number > bet.blockNumber + blocksToWait,
            "Blocks to wait not passed"
        );

        uint256 randomValue = (getRandomNumber() % (bet.isAngry ? 100 : 3)) + 1;
        bet.claimed = true;

        bool win = false;
        if (bet.guess == randomValue) {
            (bool success, ) = payable(msg.sender).call{ value: bet.value * 2 }(
                ""
            );
            require(success, "Balance invalid!");
            win = true;
        }

        // Clear bet to prevent reuse
        delete bets[msg.sender];

	emit ClaimBet(msg.sender, bet.guess, bet.blockNumber, win);

        return win;
    }

    receive() external payable {}
}
