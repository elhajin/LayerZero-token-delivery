//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {safeCaller} from "../utils/safeCaller.sol";
import "../interfaces/L0_interfaces.sol";
import "../wrapper/wrapper.sol";
import "../utils/errors.sol";

abstract contract handler   {
    uint32 constant MAX_RETURN_DATA_COPY = 0;
     uint16 immutable LOCAL_CHAIN_ID;
    ILayerZeroEndpoint immutable endpoint;
    mapping(uint16 chainId => address remoteAddress) remoteAddress;
    // mapping that stores the failed self call
    mapping(uint16 chainId => mapping(uint64 nonce => bytes32 hashPayload)) failedMsg;
    // mapping that stores the size payload limit for each chain :
    mapping(uint16 chainId => uint256 size) payloadSizeLimit;
    // mapping that stores the adopterParams for each chain: 
    mapping(uint16 chainId => bytes adapterParam) adapterParam;
    /////// access control //////////
    address  _owner;
    /////// protocol vars //////////
    // wrapper contract in the local chain. 
    Wrapper  WRAPPER;
    // mapping that stores the whiteListed tokens ;
    mapping (address token => bool ) isHToken;
    // maping stores the local Token for each nativeToken and source id. 
    mapping (uint16 chainId =>mapping( address nativeToken => address localTokenAddress)) nativeToLocal;


    using safeCaller for bytes;
    modifier onlySelf() {
        if (msg.sender != address(this)) revert("only self call");
        _;
    }

    modifier onlyEndpoint() {
        if (msg.sender != address(endpoint)) revert("only endpoint call");
        _;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert("only owner call");
        _;
    }

     // only whitelisted tokens should be able to call send : 
    modifier onlyWhitelisted(){
        if (!isHToken[_msgSender()] ) revert OnlyWhiteListedTokens();
        _;
    }
    // only wraper contract should be able to set a whitelist token
    modifier  onlyWrapper {
        if (_msgSender() != address(WRAPPER)) revert OnlyWrapper();
        _;
    }
    constructor(address _endpoint, uint16 _localChainId) {
        endpoint = ILayerZeroEndpoint(_endpoint);
        _owner = msg.sender;
        LOCAL_CHAIN_ID = _localChainId;
    }
    // @todo emit an even here when the call is sucusse
    function SafeReceive(  bytes calldata payload) external onlySelf   {
        (bytes memory funcArg,uint16 nativeChain,address nativeToken,string memory name, string memory symbol,uint8 decimals) = _decodePaylod(payload);
         address localToken =nativeToLocal[nativeChain][nativeToken] ;
        if(localToken== address(0)){
          localToken =  WRAPPER.clone(nativeToken,nativeChain,name,symbol,decimals);
        }
        if (!isHToken[localToken]) revert  OnlyWhiteListedTokens();
        (bool success,) = _externalcall(0,funcArg,gasleft(),localToken);
        if (!success) revert FailedToMint();
    }
    //@todo emit an event here
    function lzSend(
        uint16 chainId,
        bytes calldata _payload,
        address payable _refunde,
        address _zroPaymentAddress
     ) internal {
        // @todo : you should store the local token if it's not stored .. 
        if(remoteAddress[chainId] == address(0)) revert NotValidDistanation();
        // calculate the path :
        bytes memory path = abi.encodePacked(remoteAddress[chainId], address(this));
        // if the is a size limit check that the payload don't exceed it :
        if (payloadSizeLimit[chainId] != 0) {
            if (_payload.length > payloadSizeLimit[chainId]) revert PayloadExceedsSizeLimit();
        }
        //  avoid stack to deep, copy params to memory . 
        bytes memory adapterParams = _getAdapterParams(chainId);
        // call the endpoint :
        endpoint.send{value: msg.value}(chainId, path, _payload, _refunde, _zroPaymentAddress, adapterParams);
    }


    //////////////// intrnal function ///////////////////////////
    function _decodePaylod(bytes memory _payload) internal pure returns(bytes memory funcArgs,uint16 srcChainId,address token,string memory name,string memory symb,uint8 dec){
            assembly {
                funcArgs := add(_payload,0x20)// set funcArgs pointer to where the actual length of function args stored (skip the first length)
                let length := mload(funcArgs)// get the length of function args 
                srcChainId := mload(add(funcArgs,add(length,2)))
                token := mload(add(funcArgs,add(length,22)))
                name := add(funcArgs,add(length,54))
                symb := add(name,add(32,mload(name)))
                dec := mload(add(symb,add(mload(symb),1)))
            }
    }
    function _storePayload(uint16 chainId,uint64 nonce, bytes32 hashPayload) internal {
        failedMsg[chainId][nonce] = hashPayload;
    }

    function _externalcall(uint32 maxDataCopy, bytes memory _calldata, uint256 _gas, address callee)
        internal
        returns (bool, bytes memory)
     {
        return _calldata.safeExternalCall(maxDataCopy, _gas, callee, 0);
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _getAdapterParams(uint16 chainId) internal view returns(bytes memory) {
        return (adapterParam[chainId]);// if non will return bytes(0) which mean use default;
    }
}
