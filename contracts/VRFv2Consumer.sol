// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.7;

// import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
// import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
// import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
// import "./Arena.sol";

// contract VRFv2Consumer is VRFConsumerBaseV2, ConfirmedOwner {
//     event RequestSent(uint256 requestId, uint32 numWords);
//     event RequestFulfilled(uint256 requestId, uint256[] randomWords, uint16 id);
//     event RequestFailed(uint256 requestId, uint256[] randomWords, uint16 id);

//     struct RequestStatus {
//         bool fulfilled; // whether the request has been successfully fulfilled
//         bool exists; // whether a requestId exists
//         uint256[] randomWords;
//     }
//     mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
//     VRFCoordinatorV2Interface COORDINATOR;

//     // Your subscription ID.
//     uint64 s_subscriptionId;

//     // past requests Id.
//     uint256[] public requestIds;
//     uint256 public lastRequestId;
//     Arena arena;
//     bytes32 keyHash = 0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;

//     uint32 callbackGasLimit = 100000;

//     // The default is 3, but you can set this higher.
//     uint16 requestConfirmations = 3;

//     // For this example, retrieve 2 random values in one request.
//     // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
//     uint32 numWords = 1;

//     /**
//      * HARDCODED FOR GOERLI
//      * COORDINATOR: 0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D
//      */

//     modifier onlyArena() {
//         require(msg.sender == address(arena));
//         _;
//     }

//     constructor(uint64 subscriptionId)
//         VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D)
//         ConfirmedOwner(msg.sender)
//     {
//         COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
//         s_subscriptionId = subscriptionId;
//     }


//     function setArenaAddress(address _address) public onlyOwner {
//         arena = Arena(_address);
//     }

//     // Assumes the subscription is funded sufficiently.
//     function requestRandomWords() external onlyArena returns (uint256 requestId) {
//         // Will revert if subscription is not set and funded.
//         requestId = COORDINATOR.requestRandomWords(
//             keyHash,
//             s_subscriptionId,
//             requestConfirmations,
//             callbackGasLimit,
//             numWords
//         );
//         s_requests[requestId] = RequestStatus({randomWords: new uint256[](0), exists: true, fulfilled: false});
//         requestIds.push(requestId);
//         lastRequestId = requestId;
//         emit RequestSent(requestId, numWords);
//         return requestId;
//     }

//     function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
//         require(s_requests[_requestId].exists, 'request not found');
//         s_requests[_requestId].fulfilled = true;
//         s_requests[_requestId].randomWords = _randomWords;

//         uint16 id = arena.getRequestId(_requestId);
//         if (id == 0) {
//             arena._fight(_requestId, _randomWords[0]);
//         }
//         else {
//             bool res = arena.setStats(_randomWords[0], id);  // ADD ID SOMEHOW || MAYBE REQUEST ID?
//             if (res) {
//                 emit RequestFulfilled(_requestId, _randomWords, id);
//             }
//             else {
//                 emit RequestFailed(_requestId, _randomWords, id);
//             }
//         }
//     }

//     function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords) {
//         require(s_requests[_requestId].exists, 'request not found');
//         RequestStatus memory request = s_requests[_requestId];
//         return (request.fulfilled, request.randomWords);
//     }
// }
