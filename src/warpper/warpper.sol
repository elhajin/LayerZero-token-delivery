//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IHtoken.sol";
import "../interfaces/L0_interfaces.sol";
import "../utils/safeCaller.sol";
import "../delivery/delivery.sol";
import "../utils/errors.sol";
/*
- any one can warp and unwarp the token .
- the router bridge will call this warpper contract to warp token and send it to another chain .
- the Htokens are unwarped only where they get warpped . 
- the Htokens should  
 */

contract Warpper {
    IHtoken immutable HTOKEN;
    uint16 immutable CHAIN_ID;
    Delivery immutable DELIVERY;
    uint32 constant MAX_DATA_COPY = 200;

    using safeCaller for bytes;
    //mapping that stores a realToken to his Htoken (warper)

    mapping(address => mapping(uint16 => address)) tokenToH;
    mapping(address Htoken => HTinfo) HtokenInfo;


    constructor(address _HtokenImpl, uint16 _chainId, address _delivery) {
        HTOKEN = IHtoken(_HtokenImpl);
        CHAIN_ID = _chainId;
        DELIVERY = Delivery(_delivery);
    }
    // this can only be called by in the same chain . and the clone token should not be an H token

    function warp(address token, uint256 amount, address to) public returns (uint256) {
        if (HtokenInfo[token].nativeChain != 0) revert tokenAlreadyWarpped(HtokenInfo[token]);
        // take the tokens from the user :
        uint balanceWarrperBefore = IHtoken(token).balanceOf(address(this));
        bytes memory _transaferFromParams =
            abi.encodeWithSignature("transferFrom(address,address,uint256)", msg.sender, address(this), amount);
        (bool success,) = _transaferFromParams.safeExternalCall(0, 0, token, 0);
        if (!success) revert FailedToTransferFrom(msg.sender);
        address Htoken = tokenToH[token][CHAIN_ID];
        if (Htoken == address(0)) {
            (string memory name, string memory symbol) = _setHtokenMetadata(token);
            Htoken = _clone(token, CHAIN_ID, name, symbol, IHtoken(token).decimals()); // deploy an Htoken for this new token.
            tokenToH[token][CHAIN_ID] = Htoken; // store the token.
            HtokenInfo[Htoken] = HTinfo(token, CHAIN_ID); // store htoken info .
        }
        uint totalSupply = IHtoken(Htoken).totalSupply();
        // mint the user the token :
        IHtoken(Htoken).mint(to, amount);
        _checkInvariant(token,Htoken,balanceWarrperBefore, totalSupply);
        return amount;
    }

    function unwarp(address token, uint256 amount, address to) public returns (uint256) {
        address Htoken = tokenToH[token][CHAIN_ID];
        if (Htoken == address(0)) revert NoNativeToken();
        uint totalSupply = IHtoken(Htoken).totalSupply();
        IHtoken(Htoken).transferFrom(msg.sender, address(this), amount);
        uint256 tokenAmt = IHtoken(Htoken).burn(address(this), IERC20(Htoken).balanceOf(address(this)));
        // send token to the caller :
        bytes memory _transferParams = abi.encodeWithSignature("transfer(address,uint256)", to, tokenAmt);
        uint balanceBefore = IHtoken(token).balanceOf(address(this));
        (bool success,) = _transferParams.safeExternalCall(0, 0, token, 0);
        if (!success) revert FailedToTransferTokens();
        if (balanceBefore - IHtoken(token).balanceOf(address(this)) > totalSupply -IHtoken(Htoken).totalSupply() ) revert BrokenInvariant("total supply greater then warpper balance");
        return tokenAmt;
    }

    function clone(address nativeToken, uint16 nativeChainId, string memory name, string memory symbol, uint8 decimals)
        external
        returns (address)
    {
        if (nativeChainId == CHAIN_ID) revert ChainIdCantBeLocal("only warpper can clone native ");
        if (msg.sender != address(DELIVERY)) revert OnlyValidDelivery();
        address HT = _clone(nativeToken, nativeChainId, name, symbol, decimals);
        // there will be tokens that have the same address in diffrent chains , so need to store the chain id also .
        if (tokenToH[nativeToken][nativeChainId] != address(0)) revert TokenExist();
        tokenToH[nativeToken][nativeChainId] = HT;
        HtokenInfo[HT] = HTinfo(nativeToken, nativeChainId);
        return HT;
    }

    /////////////////////// view function /////////////////////////
    function getHtokenInfo(address Htoken) public view returns (HTinfo memory info) {
        return HtokenInfo[Htoken];
    }
    function getHtoken(address token, uint16 chainId) public view returns(address) {
        return tokenToH[token][chainId];
    }

    ////////////////////// internal function /////////////////////////////

    function _clone(address token, uint16 chainId, string memory name, string memory symbol, uint8 decimals)
        internal
        returns (address)
    {
        address Hclone;
        bytes20 addr = bytes20(address(HTOKEN));
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), addr)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            Hclone := create(0, clone, 0x37)
        }
        if (Hclone == address(0)) revert failedToCreateClone();
        IHtoken(Hclone).inialize(address(DELIVERY), token, address(this), chainId, name, symbol, decimals);
        if (IHtoken(Hclone).INITIALIZED() != 1) revert FailedToInitializeClone();
        // whitelist the token in the dilevery contract :
        DELIVERY.whiteList(Hclone);
        return Hclone;
    }

    function _setHtokenMetadata(address token) internal view returns (string memory name, string memory symbol) {
        name = string.concat("Hawk ", IHtoken(token).name());
        symbol = string.concat("H", IHtoken(token).symbol());
    }

    function _checkInvariant(address token, address Htoken,uint ts,uint balB) internal view {
        if (IERC20(token).balanceOf(address(this))- balB< IERC20(Htoken).totalSupply() -ts) {
            revert BrokenInvariant("total supply greater then warpper balance");
        }
    }
}
