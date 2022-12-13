// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

interface IVRFv2Consumer {
    // This function request RandomWords
    function requestRandomWords() external returns (uint256 requestId);
    
    // This function get result
    function getRequestStatus(uint256 _requestId) external view returns (bool fulfilled, uint256[] memory randomWords);

    // This function request RandomWords
    function requestRandomWordsMock() external returns (uint256 requestId);
    
    // This function get result
    function getRequestStatusMock(uint256 _requestId) external view returns (bool fulfilled, uint256[1] memory randomWords);
}
