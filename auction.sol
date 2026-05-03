// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Auction{
    address payable public auctioneer;
    uint public stblock; // start time
    uint public etblock;// end time


    enum Auc_state {Started, Running, Ended, Cancelled}
    Auc_state public auctionState;


    uint public highestBid;
    uint public highestPayableBid;
    uint public bidInc;

    address payable public highestBidder;

    mapping(address => uint) public bids;

    constructor(){
        auctioneer = payable(msg.sender);
        auctionState = Auc_state.Running;
        stblock = block.number;
        etblock = stblock+ 240;
    }

    // modifiers

    modifier notOwner(){
        require(msg.sender != auctioneer,"Onwer cannot bid");
         _;
    }
    modifier Owner(){
        require(msg.sender == auctioneer,"Onwer cannot bid");
         _;
    }
    modifier Started(){
        require(block.number >= stblock);
         _;
    }
    modifier beforeEnding(){
        require(block.number<etblock);
         _;
    }

    function cancelAuc() public Owner{
        auctionState  = Auc_state.Cancelled;
    }
     function EndedAuc() public Owner{
        auctionState  = Auc_state.Ended;
    }

    function min(uint a, uint b) pure private returns(uint){
        if(a<=b)
        return a;
        else return b;


    }

    //Bidding fun
    function bid() payable public notOwner Started beforeEnding{
        require(auctionState == Auc_state.Running);
        require(msg.value>= 1 ether);

        uint currentBid = bids[msg.sender] + msg.value;

         require(currentBid>highestPayableBid);

         bids[msg.sender] = currentBid;

         if(currentBid<bids[highestBidder]){
            highestPayableBid = min(currentBid+bidInc,bids[highestBidder]);
         }
         else{
            highestPayableBid = min(currentBid,bids[highestBidder]+bidInc);
            highestBidder = payable(msg.sender);

         }
    }

    function finalizeAuc() public{ 
            require(auctionState == Auc_state.Cancelled|| auctionState == Auc_state.Ended|| block.number>etblock);
            require(msg.sender == auctioneer||bids[msg.sender]>0);


            address payable person;
            uint value;
            
            if(auctionState == Auc_state.Cancelled){
                person = payable(msg.sender);
                value  = bids[msg.sender];

            }

            else {
                if(msg.sender == auctioneer){
                    person = auctioneer;
                    value = highestPayableBid;
                }
                else{
                    if(msg.sender == highestBidder){
                        person  = highestBidder;
                        value = bids[highestBidder]-highestPayableBid;
                    }
                    else{
                        person = payable (msg.sender);
                        value = bids[msg.sender];

                    }
                }
            }
            bids[msg.sender]=0;
            (bool success, ) = person.call{value: value}("");
              require(success, "Transfer failed");

         }
         
    }



