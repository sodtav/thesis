// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.25 <0.8.15;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/mad.sol";

/*
* @desc Tester for the mad contract.  
*/

contract testMad {

    mad madTesting = mad(DeployedAddresses.mad());

    /*
    * @desc Tests if the initalization is correct and the constructor is working properly.  
    */
    
    function testInitalization() public {
        
        uint256 correctInitial = 1000;

        Assert.equal(madTesting.returnBalance(tx.origin), correctInitial, "First account must have 1000 tokens");
        Assert.equal(madTesting.returnTotalCoins(), correctInitial, "Inital coins must be 1000");

    }

    /*
    * @desc Tests if the mint function that creates new coins is working properly.
    */
    
    function testMint() public {

        uint256 correctMint = 1000;
        uint256 correctTotalAfterMint = 2000;

        madTesting.mint(address(this), 1000);

        Assert.equal(madTesting.returnBalance(address(this)), correctMint, "This contract's account must have 1000 tokens");
        Assert.equal(madTesting.returnTotalCoins(), correctTotalAfterMint, "Total coins should be 2000");

    }

    /*
    * @desc Tests if the allow function that allows an address to spend another address' funds is working properly.
    */
    
    function testAllow() public {

        uint256 correctAllow = 500;

        madTesting.allow(0x0000000000000000000000000000000000000001, 500);
        
        Assert.equal(madTesting.returnAllowed(address(this), 0x0000000000000000000000000000000000000001), correctAllow, "The allowance should be 500");

    }

    /*
    * @desc Tests if the adjustAllowed function that adjusts the amount of coins an address is allowed to spend on behalf of the caller is working properly.
    */
    
    function testAdjustAllowed() public {

        uint256 correctAdjustAllowedPositive = 1000;
        uint256 correctAdjustAllowedNegative = 800;
        
        madTesting.allow(0x0000000000000000000000000000000000000002, 500);

        madTesting.adjustAllowed(0x0000000000000000000000000000000000000002, 500);

        Assert.equal(madTesting.returnAllowed(address(this), 0x0000000000000000000000000000000000000002), correctAdjustAllowedPositive, "The allowance should be 1000");

        madTesting.adjustAllowed(0x0000000000000000000000000000000000000002, -200);

        Assert.equal(madTesting.returnAllowed(address(this), 0x0000000000000000000000000000000000000002), correctAdjustAllowedNegative, "The allowance should be 800");

    }

    /*
    * @desc Tests if the internalAdjustAllowed function that adjusts the amount of coins an address is allowed to spend on behalf of another address is working properly.
    */
    
    function testInternalAdjustAllowed() public {

        uint256 correctInternalAdjustAllowedPositive = 1000;
        uint256 correctInternalAdjustAllowedNegative = 800;
        
        madTesting.allow(0x0000000000000000000000000000000000000003, 500);

        madTesting.internalAdjustAllowed(address(this), 0x0000000000000000000000000000000000000003, 500);

        Assert.equal(madTesting.returnAllowed(address(this), 0x0000000000000000000000000000000000000003), correctInternalAdjustAllowedPositive, "The allowance should be 1000");

        madTesting.internalAdjustAllowed(address(this), 0x0000000000000000000000000000000000000003, -200);

        Assert.equal(madTesting.returnAllowed(address(this), 0x0000000000000000000000000000000000000003), correctInternalAdjustAllowedNegative, "The allowance should be 800");

    }

    /*
    * @desc Tests if the sendCoins function that sends the specified amount of coins to the specified address from the caller's balance is working properly.
    */
    
    function testSendCoins() public {

        uint256 correctSendCoinsTarget = 200;
        uint256 correctSendCoinsSender = 800;

        madTesting.sendCoins(0x0000000000000000000000000000000000000004, 200);

        Assert.equal(madTesting.returnBalance(0x0000000000000000000000000000000000000004), correctSendCoinsTarget, "The balance should be 200");
        Assert.equal(madTesting.returnBalance(address(this)), correctSendCoinsSender, "The balance should be 800");

    }

    /*
    * @desc Tests if the indirectSendCoins function that sends the specified amount of coins to the specified address from another specified address 
    * in behalf of the caller is working properly.
    */
    
    function testIndirectSendCoins() public {

        uint256 correctIndirectSendCoinsTarget = 200;
        uint256 correctIndirectSendCoinsSender = 800;

        madTesting.mint(0x0000000000000000000000000000000000000005, 1000);
        madTesting.internalAdjustAllowed(0x0000000000000000000000000000000000000005, address(this), 1000);
        madTesting.indirectSendCoins(0x0000000000000000000000000000000000000005, 0x0000000000000000000000000000000000000006, 200);

        Assert.equal(madTesting.returnBalance(0x0000000000000000000000000000000000000006), correctIndirectSendCoinsTarget, "The balance should be 200");
        Assert.equal(madTesting.returnBalance(0x0000000000000000000000000000000000000005), correctIndirectSendCoinsSender, "The balance should be 800");

    }

    /*
    * @desc Tests if the burn function that destroys the specified amount of coins from the caller's balance is working properly.
    */
    
    function testBurn() public {

        uint256 correctBurn = 500;
        uint256 totalCoinsBeforeBurn = madTesting.returnTotalCoins();

        madTesting.burn(300);

        Assert.equal(madTesting.returnBalance(address(this)), correctBurn, "The balance should be 500 after burn");
        Assert.equal(madTesting.returnTotalCoins(), totalCoinsBeforeBurn-300, "Total coins should be 2700");

    }

    /*
    * @desc Tests if the indirectBurn function that destroys the specified amount of coins from the specified address' balance on behalf of the caller is working properly.
    */
    
    function testIndirectBurn() public {

        uint256 correctIndirectBurn = 600;
        uint256 totalCoinsBeforeIndirectBurn = madTesting.returnTotalCoins();

        madTesting.indirectBurn(0x0000000000000000000000000000000000000005, 200);

        Assert.equal(madTesting.returnBalance(0x0000000000000000000000000000000000000005), correctIndirectBurn, "The balance should be 600");
        Assert.equal(madTesting.returnTotalCoins(), totalCoinsBeforeIndirectBurn-200, "Total coins should be 2500");

    }


}