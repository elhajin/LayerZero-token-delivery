// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

// import {Script, console2} from "forge-std/Script.sol";
// import "../src/Counter.sol";

// contract deployCounter is Script {
//     // deploy the contract on : sepolia , arbi , bsc
//     // get the rpc :

//     function setUp() public {}

//     function run() public {
//         uint256 pk = vm.envUint("private_key");
//         uint256 chainId;
//         assembly {
//             chainId := chainid()
//         }
//         string memory network;
//         if (chainId == 32337) network = "local_host";
//         else if (chainId == 11155111) network = "sepolia";
//         else if (chainId == 420) network = "optimism";
//         else if (chainId == 421613) network = "arbitrum";
//         else if (chainId == 80001) network = "mumbai";
//         string memory json = vm.readFile("./jss/refrences.json");
//         address endpoint = vm.parseJsonAddress(json, string.concat(".", network, ".endpoint"));
//         vm.startBroadcast(pk);
//         //get the address of the endpoint :
//         crossChainCounter counter = new crossChainCounter(endpoint);
//         vm.stopBroadcast();
//         console.log(address(counter));
//         console.log(network);
//     }

//     function writeToJson(uint256 chainId, address c23) public {
//         string memory network;
//         console2.log("the address at ", chainId, "\n is ", c23);
//         string memory chainid = vm.serializeUint(network, "chainId", chainId);
//         string memory addr = vm.serializeAddress(network, "address", c23);
//         string memory jsonObj = vm.serializeString(chainid, network, addr);
//         vm.writeJson(jsonObj, "./jss/jsonRef.json", network);
//     }
// }

// contract setConfig is Script {
//     address sepolia = 0x7c09ed7DE2d1D5FD629EC6D5e75213cA1d453B3e;
//     address arbitrum = 0xcEe82EA5a32bD8D54220Af410BA9E37b9F2e460d;
//     address mumbai = 0xf4b6c842193EAfED9B643df2b79Cff53DCCed243;

//     function run() public {
//         uint256 pk = vm.envUint("private_key");
//         uint256 chainId;
//         assembly {
//             chainId := chainid()
//         }
//         string memory network;
//         address localAddr;
//         if (chainId == 11155111) {
//             network = "sepolia";
//             localAddr = sepolia;
//         } else if (chainId == 421613) {
//             network = "arbitrum";
//             localAddr = arbitrum;
//         } else if (chainId == 80001) {
//             network = "mumbai";
//             localAddr = mumbai;
//         }
//         string memory json = vm.readFile("./jss/refrences.json");
//         console.log(localAddr);
//         string memory remoteKey;
//         if (localAddr == mumbai) remoteKey = "arbitrum";
//         else if (localAddr == arbitrum) remoteKey = "mumbai";
//         uint16 chainid = uint16(vm.parseJsonUint(json, string.concat(".", remoteKey, ".chainId")));
//         address remoteAddr = localAddr == arbitrum ? mumbai : arbitrum;
//         console.log(chainid);
//         console.log("should be arbi", network);
//         console.log("should be mumbai", remoteKey);

//         vm.startBroadcast(pk);
//         crossChainCounter(payable(localAddr)).setAddress(chainid, remoteAddr);
//         vm.stopBroadcast();
//     }
// }

// interface C23 {
//     function send(uint16 chainId, bool inn, uint256 rounds) external payable;
//     function estimate_fee(uint16 chainId, bool inn, uint256 rounds) external view returns (uint256 fees);
// }

// contract increment is Script {
//     address sepolia = 0x7c09ed7DE2d1D5FD629EC6D5e75213cA1d453B3e;
//     address arbitrum = 0xcEe82EA5a32bD8D54220Af410BA9E37b9F2e460d;
//     address mumbai = 0xf4b6c842193EAfED9B643df2b79Cff53DCCed243;

//     C23 c23;

//     function run() public {
//         uint256 chainId;
//         assembly {
//             chainId := chainid()
//         }
//         uint16 id = chainId == 80001 ? 10143 : 10109;
//         address addrC23 = chainId == 80001 ? mumbai : arbitrum;
//         c23 = C23(payable(addrC23));
//         // estimate gas first :
//         uint256 pk = vm.envUint("private_key");
//         address caller = vm.addr(pk);
//         uint256 fees = c23.estimate_fee(id, true, 11);
//         console.log("fees :", fees);
//         console.log("balance:", caller.balance);
//         if (fees * 2 > caller.balance) {
//             console.log("balance not enough to cover this path : ", caller.balance);
//             return;
//         } else {
//             vm.startBroadcast(pk);
//             c23.send{value: fees}(id, true, 11);
//             vm.stopBroadcast();
//         }
//         console.log("tx ends .. check on arbi chain");
//     }
// }
