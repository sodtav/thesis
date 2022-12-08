// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.8.15;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/thesis.sol";

/*
* @desc Tester for the thesis contract.  
*/

contract testThesis {

    thesis thesisTest = thesis(DeployedAddresses.thesis());

    /*
    * @desc Tests if the initalization is correct and the constructor is working properly.  
    */
    
    function testInitalization() public {
        
        string memory correctName = "SinoCoin";
        string memory correctSymbol = "SINC";

        Assert.equal(thesisTest.name(), correctName, "Name should be SinoCoin");
        Assert.equal(thesisTest.symbol(), correctSymbol, "Symbol should be SINC");
        Assert.equal(thesisTest.decimals(), uint(18), "Decimals should be 18");

    }

    /*
    * @desc Tests if the mint function that creates new coins is working properly.
    */
    
    function testMint() public {

        uint256 correctMint = 1000;
        uint256 correctTotalAfterMint = 1000;

        thesisTest.mint(address(this), 1000);

        Assert.equal(thesisTest.balanceOf(address(this)), correctMint, "This contract's account must have 1000 tokens");
        Assert.equal(thesisTest.totalSupply(), correctTotalAfterMint, "Total coins should be 1000");

    }

    /*
    * @desc Tests if the approve function that allows an address to spend another address' funds is working properly.
    */
    
    function testApprove() public {

        uint256 correctApprove = 500;

        thesisTest.approve(0x0000000000000000000000000000000000000001, 500);
        
        Assert.equal(thesisTest.allowance(address(this), 0x0000000000000000000000000000000000000001), correctApprove, "The allowance should be 500");

    }

    /*
    * @desc Tests if the adjustAllowed function that adjusts the amount of coins an address is allowed to spend on behalf of the caller is working properly.
    */
    
    function testAdjustAllowed() public {

        uint256 correctAdjustAllowedPositive = 1000;
        uint256 correctAdjustAllowedNegative = 800;
        
        thesisTest.approve(0x0000000000000000000000000000000000000002, 500);

        thesisTest.adjustAllowed(address(this), 0x0000000000000000000000000000000000000002, 500);

        Assert.equal(thesisTest.allowance(address(this), 0x0000000000000000000000000000000000000002), correctAdjustAllowedPositive, "The allowance should be 1000");

        thesisTest.adjustAllowed(address(this), 0x0000000000000000000000000000000000000002, -200);

        Assert.equal(thesisTest.allowance(address(this), 0x0000000000000000000000000000000000000002), correctAdjustAllowedNegative, "The allowance should be 800");

    }

    /*
    * @desc Tests if the transfer function that sends the specified amount of coins to the specified address from the caller's balance is working properly.
    */
    
    function testTransfer() public {

        uint256 correctSendCoinsTarget = 200;
        uint256 correctSendCoinsSender = 800;

        thesisTest.transfer(0x0000000000000000000000000000000000000004, 200);

        Assert.equal(thesisTest.balanceOf(0x0000000000000000000000000000000000000004), correctSendCoinsTarget, "The balance should be 200");
        Assert.equal(thesisTest.balanceOf(address(this)), correctSendCoinsSender, "The balance should be 800");

    }

    /*
    * @desc Tests if the transferFrom function that sends the specified amount of coins to the specified address from another specified address 
    * on behalf of the caller is working properly.
    */
    
    function testTansferFrom() public {

        uint256 correctIndirectSendCoinsTarget = 200;
        uint256 correctIndirectSendCoinsSender = 800;

        thesisTest.mint(0x0000000000000000000000000000000000000005, 1000);
        thesisTest.adjustAllowed(0x0000000000000000000000000000000000000005, address(this), 1000);
        thesisTest.transferFrom(0x0000000000000000000000000000000000000005, 0x0000000000000000000000000000000000000006, 200);

        Assert.equal(thesisTest.balanceOf(0x0000000000000000000000000000000000000006), correctIndirectSendCoinsTarget, "The balance should be 200");
        Assert.equal(thesisTest.balanceOf(0x0000000000000000000000000000000000000005), correctIndirectSendCoinsSender, "The balance should be 800");
        Assert.equal(thesisTest.allowance(0x0000000000000000000000000000000000000005, address(this)), 800, "The amount allowed to spend should be 800");

    }

    /*
    * @desc Tests if the burn function that destroys the specified amount of coins from an address' balance is working properly.
    */
    
    function testBurn() public {

        uint256 correctBurn = 700;

        thesisTest.mint(0x0000000000000000000000000000000000000007, 1000);

        uint256 totalCoinsBeforeBurn = thesisTest.totalSupply();

        thesisTest.burn(0x0000000000000000000000000000000000000007, 300);

        Assert.equal(thesisTest.balanceOf(0x0000000000000000000000000000000000000007), correctBurn, "The balance should be 700 after burn");
        Assert.equal(thesisTest.totalSupply(), totalCoinsBeforeBurn-300, "Total coins should be 2700");

    }

    /*
    *
    */

    function testRegisterDevice() public {

        address firstCorrectAddress = 0x0000000000000000000000000000000000000008;
        address secondCorrectAddress = 0x0000000000000000000000000000000000000009;

        thesisTest.registerDevice(0x0000000000000000000000000000000000000008, 1);
        thesisTest.registerDevice(0x0000000000000000000000000000000000000008, 2);
        thesisTest.registerDevice(0x0000000000000000000000000000000000000009, 3);

        Assert.equal(thesisTest.registeredDevices(1), firstCorrectAddress, "The address is not correct");
        Assert.equal(thesisTest.registeredDevices(2), firstCorrectAddress, "The address is not correct");
        Assert.equal(thesisTest.registeredDevices(3), secondCorrectAddress, "The address is not correct");

    }

    /*
    *
    */

    function testTransferFromDeviceID() public {

        thesisTest.mint(0x0000000000000000000000000000000000000010, 1000);

        uint256 correctCoinsSender = 600;
        uint256 correctCoinsTarget = 400;

        thesisTest.transferFromDeviceID(2, 0x0000000000000000000000000000000000000010, 400);

        Assert.equal(thesisTest.balanceOf(0x0000000000000000000000000000000000000010), correctCoinsSender, "Sender balance should be 600");
        Assert.equal(thesisTest.balanceOf(0x0000000000000000000000000000000000000008), correctCoinsTarget, "Sender balance should be 400");

    }


}