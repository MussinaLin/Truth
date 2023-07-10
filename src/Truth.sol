pragma solidity ^0.8.0;

import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {ERC721} from 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

contract Truth is ERC721, Ownable {
    event RevealTruth();
    event UpdateToken(address indexed user, uint256 newFee, string description);

    uint256 public constant BPS = 10000;
    uint256 public constant RATE = 100;
    uint256 public constant END_PERIOD = 3 * 24 * 60 * 60;

    uint256 public totalSupply;
    uint256 public fee; // denominate in ETH
    uint256 public lastUpdateTime;
    string public baseTokenURI;

    mapping(uint256 => string) nftDesc;
    mapping(address => uint256) userSpent;

    receive() external payable {}

    constructor(string memory baseURI, uint256 initFee) ERC721('Truth', 'Truth') {
        setBaseTokenURI(baseURI);
        fee = initFee;
    }

    function getNextUpdateFee() public view returns (uint256) {
        return (fee * (BPS + RATE)) / BPS;
    }

    function mint() public onlyOwner {
        uint256 id = totalSupply;
        totalSupply++;
        _safeMint(owner(), id);
        emit RevealTruth();
    }

    function updateToken(uint256 tokenId, address to, string memory description) external payable {
        uint256 newFee = getNextUpdateFee();
        require(msg.value >= newFee, 'Insufficient fee');

        if (bytes(description).length > 0) {
            // Update description
            nftDesc[tokenId] = description;
        }

        address tokenOwner = _ownerOf(tokenId);
        if (to != tokenOwner) {
            // Transfer token
            _safeTransfer(tokenOwner, to, tokenId, '');
        }

        fee = newFee;
        lastUpdateTime = block.timestamp;

        emit UpdateToken(msg.sender, fee, description);
    }

    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual override returns (bool) {
        spender;
        tokenId;
        return true;
    }
}
