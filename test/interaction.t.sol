//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./utils/l0_setup.sol";
/*
 * users always get the same amount of Htoken ,as they send to the warpper. 
 * can not warp a token that is already warpped . 
 * htoken.totalSupply <= nativeToken.balanceOf(warpper);
 * 
 */
contract Interaction is SetUp {
    function test_warpToken() public {
        uint balanceUser1Before = token1.balanceOf(user1);
        vm.startPrank(user1);
        token1.approve(address(warpper1),100 ether);
        warpper1.warp(address(token1),50 ether,user3);
        // get the htoken info : 
        address htoken1 = warpper1.getHtoken(address(token1),chainId1);
        // assertion :
        assertEq(Htoken(htoken1).balanceOf(user3) , 50 ether);
        assertEq(token1.balanceOf(address(warpper1)),50 ether);
        assertEq(token1.balanceOf(user1),balanceUser1Before - 50 ether);
        assertEq(18,Htoken(htoken1).decimals());
        assertEq_string(Htoken(htoken1).name(),"Hawk token one");
        assertEq_string(Htoken(htoken1).symbol(),"HT1");
        // another warps : 
        vm.stopPrank();
        vm.startPrank(user2);
        token1.approve(address(warpper1),100 ether);
        warpper1.warp(address(token1),100 ether,user1);
        assertEq(100 ether,Htoken(htoken1).balanceOf(user1));
        assertEq(Htoken(htoken1).totalSupply(),150 ether);
        assertEq(token1.balanceOf(address(warpper1)),150 ether);
    }

    function test_unwarpToken() public {
        // first warp token1, and token2 : 
        vm.startPrank(user1);
        warpper1.warp(address(token1),1030 ether,user3);
        vm.startPrank(user2);
        warpper1.warp(address(token2),2000 ether,user3);
        
        // get Htoken : 
        Htoken  htoken1 = Htoken(warpper1.getHtoken(address(token1),chainId1));
        Htoken htoken2 = Htoken(warpper1.getHtoken(address(token2),chainId1));
        assertEq(htoken1.balanceOf(user3), 1030 ether);
        assertEq(htoken2.balanceOf(user3),2000 ether);
        assertEq(token1.balanceOf(address(warpper1)),1030 ether);
        assertEq(token2.balanceOf(address(warpper1)),2000 ether);
        vm.startPrank(user3);
        uint user3Bal = htoken1.balanceOf(user3);
        vm.expectRevert();
        warpper1.unwarp(address(token1),user3Bal,user3);
        htoken1.approve(address(warpper1),user3Bal);
        warpper1.unwarp(address(token1),user3Bal,user3);  
        // assertion : 
        assertEq(token1.balanceOf(address(warpper1)),0);
        assertEq(token1.balanceOf(user3),1030 ether);
        assertEq(htoken1.balanceOf(user3),0);
        assertEq(htoken1.totalSupply() ,0);
        
    }

    // path chain 1 => chain 2
    function test_send() public {
        // warp token : 
        vm.deal(user1,100 ether);
        vm.startPrank(user1);
        warpper1.warp(address(token1),1030 ether,user1);
        Htoken  htoken1 = Htoken(warpper1.getHtoken(address(token1),chainId1));
        // call estimateTransferFee : 
        (uint nativeFee , uint zroFee) = htoken1.estimateTransferFee(false,chainId2,user3,1000 ether);
        console.log("nativeFee : ",nativeFee);
        assertEq(zroFee,0);
        // send cross chain from user1 transfer to  user3,  
        htoken1.send{value: nativeFee }(chainId2,user3,1000 ether,false);
        Htoken htoken2 = Htoken(warpper2.getHtoken(address(token1),chainId1));
        uint totalsupply = htoken1.totalSupply() + htoken2.totalSupply();
        uint totalBalance = token1.balanceOf(address(warpper1));
        // assertion : 
        assertEq_string(htoken2.name(),htoken1.name());
        assertEq_string(htoken2.symbol(),htoken1.symbol());
        assertEq(htoken1.balanceOf(user1),30 ether,"bob change balance not Accurate");
        assertEq(htoken2.balanceOf(user3),1000 ether,"vika balance is not accurate");
        assertEq(totalsupply,totalBalance,"real balance no equal the total supply ");
    }
    
    // path : chain 2 => chain 1. 
    function test_sendFrom() public {
        // warp token : 
        vm.startPrank(user1);
        warpper2.warp(address(token1),1000 ether,user1);
        Htoken  htoken1 = Htoken(warpper2.getHtoken(address(token1),chainId2));
        htoken1.approve(user3,1000 ether);
        (uint nativeFee ,) = htoken1.estimateTransferFee(false,chainId1,user3,999 ether);
        
        vm.deal(user3,nativeFee * 4);
        vm.startPrank(user3);
        htoken1.sendFrom{value: user3.balance}(chainId1,user1,user3,999 ether , false);
        Htoken htoken2 = Htoken(warpper1.getHtoken(address(token1),chainId2));
        uint totalsupply = htoken1.totalSupply() + htoken2.totalSupply();
        uint totalBalance = token1.balanceOf(address(warpper2));
         // assertion : 
        assertEq_string(htoken2.name(),htoken1.name());
        assertEq_string(htoken2.symbol(),htoken1.symbol());
        assertEq(user3.balance,nativeFee * 3);
        assertEq(htoken2.balanceOf(user3),999 ether,"dstToken: vika change balance not Accurate");
        assertEq(htoken1.balanceOf(user3),0,"srcToken :  token vika balance is not accurate");
        assertEq(htoken2.balanceOf(user1),0,"dstToken: bob balance is not accurate");
        assertEq(htoken1.balanceOf(user1),1 ether,"srcToken : bob balance is not accurate");
        assertEq(htoken1.allowance(user1,user3),1 ether,"remaining allwance  not accurate");
        assertEq(totalsupply,totalBalance,"real balance no equal the total supply ");
    }


}
