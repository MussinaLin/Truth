pragma solidity ^0.8.0;

import {ERC721} from 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

contract Truth is ERC721 {
    constructor() ERC721('Truth', 'Truth') {}
}
