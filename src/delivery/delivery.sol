//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./view.sol";

contract Delivery is View, ILayerZeroReceiver {
    constructor(address endpoint, uint16 localChainId) handler(endpoint, localChainId) {}

    ////////////////////// write functions //////////////////////
    function Send(uint16 chainId, bytes calldata _payload, address payable _refunde, address _payInZro)
        public
        payable
        onlyWhitelisted
    {
        lzSend(chainId, _payload, _refunde, _payInZro);
    }

    function lzReceive(uint16 _srcChainId, bytes calldata path, uint64, bytes calldata _payload)
        external
        onlyEndpoint
    {
        bytes memory _path = path;
        address srcAddress;
        assembly {
            srcAddress := mload(add(_path, 20))
        }
        //  path from non valid delivery should be blocked .
        if (remoteAddress[_srcChainId] == address(0) || remoteAddress[_srcChainId] != srcAddress) {
            revert NotValidDelivery();
        }
        SafeReceive(_srcChainId, _payload);
    }

    // @todo
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external {}

    function whiteList(address token) public onlyWarpper {
        if (isHToken[token] || token == address(0)) revert InvalidTokenToWhiteList();
        isHToken[token] = true;
    }
    //////////////////// restict functions //////////////////// 
    function addRemoteAddress(uint16 chainId, address remoteAddr) external onlyOwner {
        // check that the chain is valid to this endpoint :
        address uln = endpoint.getSendLibraryAddress(address(this));
        if (IUln(uln).ulnLookup(chainId) == bytes32(0)) revert("chain id does not exist");
        if (chainId == LOCAL_CHAIN_ID) revert("can't be local chain id");
        bool changeRemote = remoteAddress[chainId] == address(0) ? false : true;
        remoteAddress[chainId] = remoteAddr;
        if (changeRemote) {
            // @todo emit change remote address
            return;
        }
        // @todo emit add remote address
    }

    function changeOwner(address newOwner) external onlyOwner {
        if (newOwner == address(0)) return;
        _owner = newOwner;
        //@todo emit new owner .
    }

    function setWarper(address _warpper) external onlyOwner  {
        if (address(WARPPER) != address(0)) revert("warpper already set, can't change it");
        WARPPER = Warpper(_warpper);
        isHToken[_warpper] = true;// warrper should be whitelisted , so he can send unwarp messages to the source chain. 
    }
    /////////////////// config functions ////////////////////////
    function setAdapterParams(uint16 chainId, bytes memory adapterParams ) public onlyOwner {
        adapterParam[chainId] = adapterParams;
    }
    function setConfig(uint16 _version, uint16 _chainId, uint256 _configType, bytes calldata _config)
        external
        onlyOwner
    {}

    function setSendVersion(uint16 _version) external onlyOwner {}

    function setReceiveVersion(uint16 _version) external onlyOwner {}

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external onlyOwner {}

    // @remind remove this functions in production....
    /////////////////////// testing function to be removed //////////////////////
    function  test_addRemoteAddress(uint16 chainId, address remoteAddr) external onlyOwner {
        require(chainId != LOCAL_CHAIN_ID,"can't be the local chain "); 
        remoteAddress[chainId] = remoteAddr;
    }
}
