// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
/**
Official Website: https://woodchain.io
Telegram: https://t.me/woodchainofficial
*/
import "@openzeppelin/contracts/math/SafeMath.sol";
import "./libs/IBEP20.sol";
import "./libs/SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract WoodPresale is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    // The number of unclaimed WOOD tokens the user has
    mapping(address => uint256) public woodUnclaimed;
    // Last time user claimed WOOD
    mapping(address => uint256) public lastWoodClaimed;

    // WOOD token
    IBEP20 WOOD;
    // BUSD token
    IBEP20 BUSD;
    // Sale active
    bool public isSaleActive;
    // Claim active
    bool public isClaimActive;
    // Starting timestamp
    uint256 public startingTimeStamp;
    // Total WOOD sold
    uint256 public totalWoodSold = 0;
    // Price of presale WOOD: 0.2 BUSD
    uint256 private constant BUSDPerWood = 20;

    // Time per percent
    uint256 private constant timePerPercent = 600;

    address constant BUSD_ADDRESS = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    uint256 public firstHarvestTimestamp;

    address payable owner;

    uint256 public constant WOOD_HARDCAP = 700000 ether;

    modifier onlyOwner() {
        require(msg.sender == owner, "You're not the owner");
        _;
    }

    event TokenBuy(address user, uint256 tokens);
    event TokenClaim(address user, uint256 tokens);

    constructor(
        address _WOOD,
        uint256 _startingTimestamp
    ) public {
        WOOD = IBEP20(_WOOD);
        BUSD = IBEP20(BUSD_ADDRESS);
        isSaleActive = true;
        owner = msg.sender;
        startingTimeStamp = _startingTimestamp;
    }

    function setSaleActive(bool _isSaleActive) external onlyOwner {
        isSaleActive = _isSaleActive;
    }

    function setClaimActive(bool _isClaimActive) external onlyOwner {
        isClaimActive = _isClaimActive;
        if (firstHarvestTimestamp == 0 && _isClaimActive) {
            firstHarvestTimestamp = block.timestamp;
        }
    }

    function buy(uint256 _amount, address _buyer) public nonReentrant {
        require(isSaleActive, "Presale has not started");
        require(
            block.timestamp >= startingTimeStamp,
            "Presale has not started"
        );

        address buyer = _buyer;
        uint256 tokens = _amount.div(BUSDPerWood).mul(100);

        require(
            totalWoodSold + tokens <= WOOD_HARDCAP,
            "Wood presale hardcap reached"
        );

        BUSD.safeTransferFrom(buyer, address(this), _amount);

        woodUnclaimed[buyer] = woodUnclaimed[buyer].add(tokens);
        totalWoodSold = totalWoodSold.add(tokens);
        emit TokenBuy(buyer, tokens);
    }

    
    function claim() external {
        require(isClaimActive, "Claim is not allowed yet");
        require(
            woodUnclaimed[msg.sender] > 0,
            "User should have unclaimed WOOD tokens"
        );
        require(
            WOOD.balanceOf(address(this)) >= woodUnclaimed[msg.sender],
            "There are not enough WOOD tokens to transfer."
        );

        if (lastWoodClaimed[msg.sender] == 0) {
            lastWoodClaimed[msg.sender] = firstHarvestTimestamp;
        }

        uint256 allowedPercentToClaim = block
        .timestamp
        .sub(lastWoodClaimed[msg.sender])
        .div(timePerPercent);

        lastWoodClaimed[msg.sender] = block.timestamp;

        if (allowedPercentToClaim > 100) {
            allowedPercentToClaim = 100;
            // ensure they cannot claim more than they have.
        }

        uint256 woodToClaim = woodUnclaimed[msg.sender]
        .mul(allowedPercentToClaim)
        .div(100);
        woodUnclaimed[msg.sender] = woodUnclaimed[msg.sender].sub(woodToClaim);

        WOOD.safeTransfer(msg.sender, woodToClaim);
        emit TokenClaim(msg.sender, woodToClaim);
    }


    function withdrawFunds() external onlyOwner {
        BUSD.safeTransfer(msg.sender, BUSD.balanceOf(address(this)));
    }

    function withdrawUnsoldWOOD() external onlyOwner {
        uint256 amount = WOOD.balanceOf(address(this)) - totalWoodSold;
        WOOD.safeTransfer(msg.sender, amount);
    }

    function emergencyWithdraw() external onlyOwner {
        WOOD.safeTransfer(msg.sender, WOOD.balanceOf(address(this)));
    }
}