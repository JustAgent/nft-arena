// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./Arena.t.sol";
contract VRFv2ConsumerT {
   ArenaT arena;
   uint num = 1;
    function requestRandomWords() public returns (uint256 requestId)
    {
        requestId = num;
        num++;    
        return requestId;
    }

    function fulfillRandomWords(uint256 _requestId) public  {
        uint16 id = arena.getRequestId(_requestId);
        uint _randomWords = 12345671234567123456712345671234567123456712345671234567123456712345671234567;
        if (id == 0) {
            arena._fight(_requestId, _randomWords);
        }
        else {
            arena.setStats(_randomWords, id); 
        }
    }

    function setArena(address ad) public {
        arena = ArenaT(ad);
    }

}
