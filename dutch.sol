
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IERC721 {
    function transferFrom(
        address _from,
        address _to,
        uint _nftId
    ) external;
}
contract AuctionsDutch{
    mapping(address => mapping(uint => Auction)) public auctionsByContract;
    Auction[] public auctions;
    struct Auction{
        address seller;
        uint duration;
        uint startAt;
        uint expiresAt;
        IERC721 nft;
        uint nftId;
        uint discountRate;
        uint startingPrice;
    }
    modifier auctionExist(address _nft, uint _nftId) {
      if (auctionsByContract[_nft][_nftId].seller != address(0x0)) {
         _;
      }
    }
    function _createAuction(uint _duration, address _nft, uint _discountRate, uint _nftId, uint _startingPrice) private {
        Auction memory newAuction = Auction(msg.sender, _duration, block.timestamp, block.timestamp + _duration, IERC721(_nft), _nftId, _discountRate, _startingPrice);
        auctionsByContract[_nft][_nftId] = newAuction;
        auctions.push(newAuction);
    }
    function createAuction(uint _duration, address _nft, uint _discountRate, uint _nftId, uint _startingPrice) public{
        require(auctionsByContract[_nft][_nftId].seller == address(0x0));
        require(_startingPrice >= _discountRate * _duration, "starting price < min");
        IERC721(_nft).transferFrom(msg.sender, address(this), _nftId);
        _createAuction(_duration, _nft, _discountRate, _nftId, _startingPrice);
    }

    function claimNftAfterAuctionEnd(address _nft, uint _nftId) public{
        Auction memory auction = auctionsByContract[_nft][_nftId];
        require(auction.seller == msg.sender, "Only seller can claim");
        require(auction.expiresAt > block.timestamp, "Auction is not ended");
        auction.nft.transferFrom(address(this), msg.sender, _nftId);
        delete(auctionsByContract[_nft][_nftId]);

    }
    function getPrice(address _nft, uint _nftId)  public view returns (uint)  {
        Auction memory auction = auctionsByContract[_nft][_nftId];
        uint timeElapsed = block.timestamp - auction.startAt;
        uint discount = auction.discountRate * timeElapsed;
        return auction.startingPrice - discount;
    }
    function buy(address _nft, uint _nftId) payable public auctionExist(_nft, _nftId){
      uint price = getPrice(_nft, _nftId);
      require(msg.value > price);
      Auction memory auction = auctionsByContract[_nft][_nftId];
      require(block.timestamp < auction.expiresAt, "auction expired");
      auction.nft.transferFrom(auction.seller, msg.sender, _nftId);
      uint refund = msg.value - price;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
      delete(auction);
    }
    function deleteAuction(address _nft, uint _nftId) public auctionExist(_nft, _nftId) {
         delete(auctionsByContract[_nft][_nftId]);
    }
  
}
