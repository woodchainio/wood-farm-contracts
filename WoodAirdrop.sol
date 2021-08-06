
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
/**
Official Website: https://woodchain.io
Telegram: https://t.me/woodchainofficial
*/
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./libs/SafeBEP20.sol";
import "./libs/BEP20.sol";

contract WoodAirdrop is Ownable {
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;

    uint256 public constant tokenAtm = 2 * 1e18;
    uint256 public constant refAtm = 1 * 1e18;
    IBEP20 public wood;

    bool public isClaimActive;

    // Addresses that excluded from antiWhale
    mapping(address => bool) private claimed;
    constructor(address _wood) public {
        require(_wood != address(0));
        wood = IBEP20(_wood);

        isClaimActive = false;
    }
    
    function getAirdrop(address ref) public {
        require(isClaimActive, "getAirdrop:: Claim is not allowed yet");
        require(!claimed[msg.sender], "getAirdrop:: This user claimed");
        wood.safeTransfer(msg.sender, tokenAtm);
        if(msg.sender!= address(0) && msg.sender!= ref)
        {
            wood.safeTransfer(ref, refAtm); 
        }
        claimed[msg.sender] = true;
    }

    function setClaimActive(bool _isClaimActive) external onlyOwner {
        isClaimActive = _isClaimActive;
    }

    // Recover lost bnb and send it to the contract owner
    function recoverLostBNB() public onlyOwner {
         address payable _owner = msg.sender;
        _owner.transfer(address(this).balance);
    }
    // Ensure requested tokens aren't users WIFI tokens
    function recoverLostTokensExceptOurTokens(address _token, uint256 amount) public onlyOwner {
         IBEP20(_token).transfer(msg.sender, amount);
    }
}