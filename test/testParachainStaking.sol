// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "forge-std/console.sol";

// import "../lib/moonbeam/precompiles/ERC20.sol";

// Various helper methods for interfacing with the Tellor pallet on another parachain via XCM
import "../lib/moonbeam/precompiles/XcmTransactorV2.sol";
import "../lib/moonbeam/precompiles/XcmUtils.sol";

import "../src/ParachainRegistry.sol";
import "../src/Parachain.sol";
import "../src/ParachainStaking.sol";
// import "../src/ParachainGovernance.sol";

contract TestToken is ERC20, Ownable {
    constructor(uint256 initialSupply) ERC20("TestToken", "TT") {
        _mint(msg.sender, initialSupply);
    }
}

contract ParachainStakingTest is Test {
    TestToken public token;
    ParachainRegistry public registry;
    ParachainStaking public staking;

    address public paraOwner = address(0x1111);

    // Parachain registration
    uint32 public fakeParaId = 12;
    uint8 public fakePalletInstance = 8;
    uint256 public fakeStakeAmount = 100;

    function setUp() public {
        token = new TestToken(1_000_000 * 10 ** 18);
        registry = new ParachainRegistry();
        staking = new ParachainStaking(address(registry), address(token));

        vm.prank(paraOwner);
        registry.fakeRegister(fakeParaId, fakePalletInstance, fakeStakeAmount);
        

        // Register parachain
        // console.log("derivativeAddressOfParachain: %s", derivativeAddressOfParachain);
        // vm.startPrank(derivativeAddressOfParachain);
        // registry.register(
        //     fakeParaId, // _paraId
        //     fakePalletInstance, // _palletInstance
        //     100   // _stakeAmount
        // );
        // vm.stopPrank();
    }

    function testConstructor() public {
        assertEq(address(staking.token()), tokenAddress);
        assertEq(address(staking.registryAddress()), address(registry));
        assertEq(address(staking.governance()), address(0x0));
    }

    function testInit() public {
        staking.init(address(0x1));
        assertEq(address(staking.governance()), address(0x1));
    }

    function testDepositParachainStake() public {
        staking.init(address(0x2));

        // Try to deposit stake with incorrect parachain
        vm.startPrank(paraOwner);
        vm.expectRevert("parachain not registered");
        staking.depositParachainStake(
            uint32(1234),               // _paraId
            bytes("consumerChainAcct"), // _account
            100                         // _amount
        );
        
        // Try deposit stake w/o token
        assertEq(registry.owner(fakeParaId), paraOwner);
        vm.expectRevert("transfer case 2 failed");
        staking.depositParachainStake(
            fakeParaId,                 // _paraId
            bytes("consumerChainAcct"), // _account
            100                         // _amount
        );
        vm.stopPrank();
    }

}