// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Auction {
    enum AuctionStatus { Active, Finalized, Cancelled }

    address public immutable seller;
    uint256 public minBid;
    uint256 public highestBid;
    address public highestBidder;
    uint256 public endTime;
    AuctionStatus public status;

    mapping(address => uint256) public pendingReturns;

    // Rankinis apsaugos kintamasis nuo pakartotinio įėjimo (re-entrancy) 
    bool private locked;

    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    // Events
    event BidPlaced(address indexed bidder, uint256 amount);
    event AuctionFinalized(address winner, uint256 amount);
    event AuctionCancelled();
    event Withdrawal(address indexed receiver, uint256 amount);

    constructor(uint256 _minBid, uint256 _duration) {
        seller = msg.sender;
        minBid = _minBid;
        endTime = block.timestamp + _duration;
        status = AuctionStatus.Active;
    }

    /// Place bid
    function bid() external payable nonReentrant {
        require(status == AuctionStatus.Active, "Aukcionas neaktyvus");
        require(block.timestamp < endTime, "Aukcionas pasibaiges");
        require(msg.value >= minBid, "Per mazas pradinis statymas");
        require(msg.value > highestBid, "Jau yra didesnis statymas");

        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBidder = msg.sender;
        highestBid = msg.value;
        emit BidPlaced(msg.sender, msg.value);
    }

    /// Withdraw refunds
    function withdrawRefund() external nonReentrant {
        uint256 amount = pendingReturns[msg.sender];
        require(amount > 0, "Neturite lesu atsiemimui");

        pendingReturns[msg.sender] = 0;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Pervedimas nepavyko");

        emit Withdrawal(msg.sender, amount);
    }

    /// Finalize auction
    function finalize() external nonReentrant {

        require(block.timestamp >= endTime, "Aukcionas dar nesibaige");
        require(!auction.finalized, "Already finalized");
        require(status == AuctionStatus.Active, "Aukcionas jau uzbaigtas");

        status = AuctionStatus.Finalized;

        if (highestBidder != address(0)) {
            pendingReturns[seller] += highestBid;
        }

        emit AuctionFinalized(highestBidder, highestBid);
    }

    function cancel() external {
        require(msg.sender == seller, "Tik pardavejas gali atsaukti");
        require(status == AuctionStatus.Active, "Negalima atsaukti");
        
        status = AuctionStatus.Cancelled;
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }
        emit AuctionCancelled();
    }
}

