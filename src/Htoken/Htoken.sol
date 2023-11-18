//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IHtoken.sol";
import "./ERC20.sol";
import "../delivery/delivery.sol";

contract Htoken is ERC20, IHtoken {
    address WARPPER; // 20 bytes
    uint8 public INITIALIZED; // 1 byte
    uint8 _decimals; // 1 bytes
    uint32 nativeFee; //4 bytes
    uint16 SOURCE_CHAIN_ID; // 2bytes
    address TOKEN;
    Delivery DELIVERY;
    address ZRO;

    //////////////////////// modifiers ////////////////////////////
    modifier once() {
        if (INITIALIZED != 0) revert("already initialized");
        _;
        INITIALIZED = 1;
    }

    modifier OnlyWarpperOrDelevery() {
        address sender = _msgSender();
        if (sender != WARPPER && sender != address(DELIVERY)) revert("only warpper call");
        _;
    }

    ///////////////////// write functions /////////////////////
    function inialize(
        address _delivery,
        address token,
        address warpper,
        uint16 chainId,
        string memory name,
        string memory symbol,
        uint8 dec
    ) external once {
        _name = name;
        _symbol = symbol;
        _decimals = dec;
        WARPPER = warpper;
        TOKEN = token;
        SOURCE_CHAIN_ID = chainId;
        DELIVERY = Delivery(_delivery);
    }

    function mint(address to, uint256 amount) public OnlyWarpperOrDelevery returns (uint256) {
        _mint(to, amount);
        return amount;
    }

    function burn(address from, uint256 amount) public returns (uint256) {
        if (msg.sender != from) _spendAllowance(from, _msgSender(), amount);
        _burn(from, amount);
        return amount;
    }

    function send(uint16 chainId, address to, uint256 amount, bool _payInZro) external payable {
        // burn token from user :
        _burn(_msgSender(), amount);
        _crossChainTransfer(chainId, to, amount, _payInZro);
    }

    function sendFrom(uint16 chainId, address from, address to, uint256 amount, bool _payInZro) external payable {
        burn(from, amount);
        _crossChainTransfer(chainId, to, amount, _payInZro);
    }

    //////////////////////// internal function /////////////////////////

    function _crossChainTransfer(uint16 chainId, address to, uint256 amount, bool _payInZro) internal {
        // encode the data : [lengthCalldata+calldata+SRCchainId+srcNativeAddress+nameLength+name+symbolLength+symbol];
        bytes memory _functionArgs = abi.encodeWithSelector(this.mint.selector, to, amount);
        bytes memory payload = _encode(_functionArgs);
        (uint256 native, uint256 zro) = DELIVERY.estimateFees(chainId, payload, _payInZro);
        address zroPayer = zro != 0 ? msg.sender : address(0); //[sc] if zro != 0 , msg.sender ,should be tx.orgin, dapps should only pay in eth
        if (msg.value < native) revert InsufficientNativeFee(native);
        //[sc] if msg.sender dosn't except eth and there is a refund send to him . this will never success.
        DELIVERY.Send{value: msg.value}(chainId, payload, payable(_msgSender()), zroPayer);
        //@todo emit en event here .
    }

    function _encode(bytes memory functionArgs) internal view returns (bytes memory payload) {
        // encode source chain and source address :
        bytes memory source = abi.encode(SOURCE_CHAIN_ID, TOKEN);
        // encode name and symbol :
        bytes memory symbol = bytes(_symbol);
        bytes memory name = bytes(_name);
        // funcArgs length + funcArgs + sourceChainId + sourceTokenAddress + name length + name +symbol length + symbol
        return bytes.concat(
            abi.encode(functionArgs.length),
            functionArgs,
            source,
            abi.encode(name.length),
            name,
            abi.encode(symbol.length),
            symbol,
            abi.encode(_decimals)
        );
    }
    ///////////////////////////// view functions /////////////////////////

    function estimateTransferFee(bool payInZro, uint16 chainId, address to, uint256 amount)
        public
        view
        returns (uint256 native, uint256 zro)
    {
        bytes memory _functionArgs = abi.encodeWithSelector(this.mint.selector, to, amount);
        _functionArgs = _encode(_functionArgs);
        (native, zro) = DELIVERY.estimateFees(chainId, _functionArgs, payInZro);
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }
}
