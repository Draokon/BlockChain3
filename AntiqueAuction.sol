// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract AntiqueAuction is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct AuctionItem {
        address payable seller;
        uint256 tokenId;
        uint256 minBid;
        uint256 highestBid;
        address highestBidder;
        uint256 auctionEnd;
        bool finalized;
    }

    mapping(uint256 => AuctionItem) public auctions; // tokenId => auction
    mapping(address => uint256) public refunds;

    uint256 private unlocked = 1;
    modifier nonReentrant() {
        require(unlocked == 1, "Reentrant call");
        unlocked = 0;
        _;
        unlocked = 1;
    }

    // Events
    event NFTMinted(uint256 indexed tokenId, address indexed owner, string tokenURI);
    event AuctionStarted(uint256 indexed tokenId, uint256 minBid, uint256 auctionEnd);
    event BidPlaced(uint256 indexed tokenId, address indexed bidder, uint256 amount);
    event RefundWithdrawn(address indexed bidder, uint256 amount);
    event AuctionFinalized(uint256 indexed tokenId, address indexed winner, uint256 amount);
    event SellerWithdrawn(uint256 indexed tokenId, address indexed seller, uint256 amount);

    constructor() ERC721("AntiqueNFT", "ANTQ") {}

    /// Mint NFT for antique item
    function mintNFT(string memory tokenURI) external returns (uint256) {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        emit NFTMinted(newTokenId, msg.sender, tokenURI);
        return newTokenId;
    }

    /// Start auction for NFT
    function startAuction(uint256 tokenId, uint256 minBid, uint256 durationSeconds) external {
        require(ownerOf(tokenId) == msg.sender, "Only owner can start auction");
        require(minBid > 0, "Minimum bid must be > 0");
        require(durationSeconds > 0, "Duration must be > 0");

        auctions[tokenId] = AuctionItem({
            seller: payable(msg.sender),
            tokenId: tokenId,
            minBid: minBid,
            highestBid: 0,
            highestBidder: address(0),
            auctionEnd: block.timestamp + durationSeconds,
            finalized: false
        });

        // Transfer NFT to contract (escrow)
        _transfer(msg.sender, address(this), tokenId);

        emit AuctionStarted(tokenId, minBid, block.timestamp + durationSeconds);
    }

    /// Place bid
    function bid(uint256 tokenId) external payable {
        AuctionItem storage auction = auctions[tokenId];
        require(block.timestamp < auction.auctionEnd, "Auction ended");
        require(msg.value >= auction.minBid, "Bid lower than minimum");
        require(msg.value > auction.highestBid, "Bid not higher than current");

        // Refund previous highest bidder
        if (auction.highestBidder != address(0)) {
            refunds[auction.highestBidder] += auction.highestBid;
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit BidPlaced(tokenId, msg.sender, msg.value);
    }

    /// Withdraw refunds
    function withdrawRefund() external nonReentrant {
        uint256 refund = refunds[msg.sender];
        require(refund > 0, "No refund");
        refunds[msg.sender] = 0;

        (bool ok, ) = payable(msg.sender).call{value: refund}("");
        require(ok, "Refund transfer failed");

        emit RefundWithdrawn(msg.sender, refund);
    }

    /// Finalize auction
    function finalize(uint256 tokenId) external nonReentrant {
        AuctionItem storage auction = auctions[tokenId];
        require(block.timestamp >= auction.auctionEnd, "Auction not ended");
        require(!auction.finalized, "Already finalized");
        require(msg.sender == auction.seller, "Only seller can finalize");

        auction.finalized = true;

        if (auction.highestBidder != address(0)) {
            _transfer(address(this), auction.highestBidder, tokenId);
        } else {
            // No bids, return NFT to seller
            _transfer(address(this), auction.seller, tokenId);
        }

        emit AuctionFinalized(tokenId, auction.highestBidder, auction.highestBid);
    }

    /// Seller withdraw ETH
    function withdrawSeller(uint256 tokenId) external nonReentrant {
        AuctionItem storage auction = auctions[tokenId];
        require(auction.finalized, "Auction not finalized");
        require(msg.sender == auction.seller, "Only seller");
        require(auction.highestBid > 0, "No funds");

        uint256 amount = auction.highestBid;
        auction.highestBid = 0;

        (bool ok, ) = auction.seller.call{value: amount}("");
        require(ok, "Seller withdraw failed");

        emit SellerWithdrawn(tokenId, auction.seller, amount);
    }

    /// Reject direct ETH transfers
    receive() external payable {
        revert("Direct ETH transfer not allowed");
    }
}
