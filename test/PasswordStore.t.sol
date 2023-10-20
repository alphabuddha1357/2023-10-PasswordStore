// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {PasswordStore} from "../src/PasswordStore.sol";
import {DeployPasswordStore} from "../script/DeployPasswordStore.s.sol";

contract PasswordStoreTest is Test {
    PasswordStore public passwordStore;
    DeployPasswordStore public deployer;
    address public owner;

    function setUp() public {
        deployer = new DeployPasswordStore();
        passwordStore = deployer.run();
        owner = msg.sender;
    }

    function test_owner_can_set_password() public {
        vm.startPrank(owner);
        string memory expectedPassword = "myNewPassword";
        passwordStore.setPassword(expectedPassword);
        string memory actualPassword = passwordStore.getPassword();
        assertEq(actualPassword, expectedPassword);
    }

    function test_get_password() public {
        vm.startPrank(owner);
        string memory expectedPassword = "myNewPassword";
        passwordStore.setPassword(expectedPassword);
        string memory actualPassword = passwordStore.getPassword();
        assertEq(actualPassword, expectedPassword);
        console.log(getFullString(1, address(passwordStore)));
    }

    function test_non_owner_reading_password_reverts() public {
        vm.startPrank(address(1));

        vm.expectRevert(PasswordStore.PasswordStore__NotOwner.selector);
        passwordStore.getPassword();
    }

    function getFullString(
        uint256 startSlot,
        address targetContract
    ) public returns (string memory) {
        // A slot in the EVM is 32 bytes
        uint256 SLOT_SIZE = 32;
        // We load the start slot from storage
        bytes32 slotVal = vm.load(targetContract, bytes32(startSlot));
        // If the last bit of the contents of storage slot 0 is 1
        // then string is >= 32 bytes
        if ((uint256(slotVal) & 1) == 1) {
            // We can extract the string length to determine how many slots are used.
            // This formula is from solidity docs
            uint256 stringLength = (uint256(slotVal) - 1) / 2;
            // Now we know the length of the string, we can determine the number of slots used
            // This is idiomatic for divison but rounding up: https://stackoverflow.com/a/2422722
            uint256 slotsUsed = (stringLength + (SLOT_SIZE - 1)) / SLOT_SIZE;
            // Since we have a larger string, we want to jump to the
            // contiguous section of storage with the string contents
            // The start of this contiguous section is calculated using keccak256
            bytes32 nextSlot = keccak256(abi.encodePacked(startSlot));
            // We can now iterate through the slots while concatanating the string
            bytes memory resultString;
            for (uint256 i = 0; i < slotsUsed; i++) {
                // We load the contents of the storage slot
                bytes32 slotValue = vm.load(targetContract, nextSlot);
                // We concatenate the contents of the string with what we've observed so far
                resultString = abi.encodePacked(resultString, slotValue);
                // We update the next slot value to the next contiguous entry
                nextSlot = bytes32(uint256(nextSlot) + 1);
            }
            return string(resultString);
        } else {
            // Slot value is < 32 bytes
            return string(abi.encodePacked(slotVal));
        }
    }
}
