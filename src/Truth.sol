pragma solidity ^0.8.0;

import {Ownable} from 'openzeppelin-contracts/contracts/access/Ownable.sol';
import {ERC721} from 'openzeppelin-contracts/contracts/token/ERC721/ERC721.sol';

contract Truth is ERC721, Ownable {
    event RevealTruth(uint256 id);
    event SpeakTruth(address indexed user, uint256 newFee, string description);

    string public TOKEN_NAME = 'Truth';
    uint256 public constant BPS = 10000;
    uint256 public constant RATE = 100;
    uint256 public constant TRUTH_V2_FUND_RATIO = 2000;
    uint256 public constant END_PERIOD = 3 days;

    string public baseTokenURI;
    uint256 public totalSupply;
    uint256 public fee; // denominate in ETH

    mapping(uint256 => string) nftDesc;
    mapping(uint256 => uint256) tokenLastUpdateTime;
    mapping(address => uint256) userSpent;

    modifier NotFreeze(uint256 tokenId) {
        require(tokenLastUpdateTime[tokenId] + END_PERIOD > block.timestamp, 'Freeze');
        _;
    }

    receive() external payable {}

    constructor(string memory baseURI, uint256 initFee) ERC721(TOKEN_NAME, TOKEN_NAME) {
        setBaseTokenURI(baseURI);
        fee = initFee;
    }

    function getNextUpdateFee() public view returns (uint256) {
        return (fee * (BPS + RATE)) / BPS;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        //https://www.fakejson.online/api/json?name=Truth&description=${text}&image=https://fakeimg.pl/500x500/?text=${text}
        return
            string.concat(
                'https://www.fakejson.online/api/json?name=Truth&description=',
                nftDesc[tokenId],
                '&image=https://fakeimg.pl/500x500/?text=',
                nftDesc[tokenId]
            );
    }

    function mint() external onlyOwner {
        uint256 tokenId = totalSupply;
        totalSupply++;
        tokenLastUpdateTime[tokenId] = block.timestamp;
        _safeMint(owner(), tokenId);
        emit RevealTruth(tokenId);
    }

    function SpeakTheTruth(uint256 tokenId, address to, string memory description) external payable NotFreeze(tokenId) {
        uint256 newFee = getNextUpdateFee();
        require(msg.value >= newFee, 'Insufficient fee');
        fee = newFee;

        if (bytes(description).length > 0) {
            // Update description
            nftDesc[tokenId] = description;
        }

        address tokenOwner = _ownerOf(tokenId);
        if (to != tokenOwner) {
            // Transfer token
            _safeTransfer(tokenOwner, to, tokenId, '');
        }

        address sender = msg.sender;
        userSpent[sender] += newFee;
        tokenLastUpdateTime[tokenId] = block.timestamp;

        emit SpeakTruth(sender, newFee, description);
    }

    function EndTruth() external {
        // Check all tokens are freeze
        for (uint256 tokenId = 0; tokenId < totalSupply; ++tokenId) {
            require(tokenLastUpdateTime[tokenId] + END_PERIOD < block.timestamp, 'Not freeze');
        }

        uint256 totalPrize = address(this).balance;
        _toTeamDevFund(totalPrize);
        // uint256 participant
    }

    /// @notice Block this function to fit the Truth.
    function approve(address to, uint256 tokenId) public virtual override {
        to;
        tokenId;
        revert();
    }

    /// @notice Block this function to fit the Truth.
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        from;
        to;
        tokenId;
        revert();
    }

    /// @notice Block this function to fit the Truth.
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        from;
        to;
        tokenId;
        revert();
    }

    /// @notice Block this function to fit the Truth.
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        from;
        to;
        tokenId;
        data;
        revert();
    }

    function setBaseTokenURI(string memory baseURI) public onlyOwner {
        baseTokenURI = baseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function _toTeamDevFund(uint256 prize) internal returns (uint256) {
        uint256 amount = (prize * TRUTH_V2_FUND_RATIO) / BPS;
        address team = owner();
        (bool succ, ) = team.call{value: amount}('');
        require(succ, 'Send ETH fail');

        return amount;
    }
}
