#// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMinterController.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract DotShmSale is IMinterController {
    address public owner;
    uint256 public salePrice;
    mapping(address => uint256) public referralPercentages;
    mapping(address => bool) public registeredHolders;
    mapping(string => bool) public registeredDomains;

   
    constructor() {
        nftContractAddress = _nftContractAddress;
        owner = msg.sender;
        salePrice = 1 ether; // default sale price
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function setSalePrice(uint256 _salePrice) external onlyOwner {
        salePrice = _salePrice;
    }

    function setReferral(address _referee, uint256 _percentage) external onlyOwner {
        require(_percentage <= 20, "Referral percentage can't exceed 20%");
        referralPercentages[_referee] = _percentage;
    }

    function registerHolder(address _holder) external onlyOwner {
        registeredHolders[_holder] = true;
    }

    function registerDomain(string memory _domain) external onlyOwner {
        registeredDomains[_domain] = true;
    }

    function buyDomain(string memory _domain, address _referrer, address _nftContractAddress) payable external {
        require(msg.value >= salePrice, "Insufficient funds");
        require(!registeredDomains[_domain], "Domain already registered");
        require(registeredHolders[_referrer] || _referrer == owner, "Referrer must be a registered holder");

        uint256 referrerShare = 0;
        if (_referrer != address(0)) {
            referrerShare = (msg.value *referralPercentages[_referrer]) / 100;
            _referrer.transfer(referrerShare);
        }

        owner.transfer(msg.value - referrerShare);

        registeredDomains[_domain] = true;
        IMinterController(_nftContractAddress).mintURI(msg.sender, _domain);
        
    }

    function buyDomainWithoutReferral(string memory _domain, address _nftContractAddress) payable external {
        require(msg.value >= salePrice, "Insufficient funds");
        require(!registeredDomains[_domain], "Domain already registered");
        owner.transfer(msg.value);
        IMinterController(_nftContractAddress).mintURI(msg.sender, _domain);
    }

    function withdraw() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawERC20(address _token, uint256 _amount) external onlyOwner {
        require(_token != address(0), "Invalid token address");
        require(_amount > 0, "Invalid amount");
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Insufficient balance");

        bool success = IERC20(_token).transfer(owner, _amount);
        require(success, "Token transfer failed");
    }
}
