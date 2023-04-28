pragma solidity ^0.8.0;

import "../lib/moonbeam/precompiles/XcmTransactorV2.sol"; // Various helper methods for interfacing with the Tellor pallet on another parachain via XCM
// import { IRegistry, ParachainNotRegistered } from "./ParachainRegistry.sol";
import {IRegistry} from "./ParachainRegistry.sol";
import {IParachainGovernance} from "./interfaces/IParachainGovernance.sol";

// Helper contract providing cross-chain messaging functionality
abstract contract Parachain {
    IRegistry internal registry; // registry as separate contract to share state between staking and governance contracts

    XcmTransactorV2 private constant xcmTransactor = XCM_TRANSACTOR_V2_CONTRACT;

    // The amount of weight an XCM operation takes. This is a safe overestimate. Based on https://docs.moonbeam.network/builders/interoperability/xcm/fees/
    uint64 private constant xcmInstructionFee = 1000000000;
    //  Number of XCM instruction to be used (DescendOrigin, WithdrawAssets, BuyExecution, Transact) due to using transactThroughSigned.
    uint64 private constant xcmInstructionCount = 4;

    constructor(address _registry) {
        registry = IRegistry(_registry);
    }

    /// @dev Report stake to a registered parachain.
    /// @param _parachain Para The registered parachain.
    /// @param _staker address The address of the staker.
    /// @param _reporter bytes The corresponding address of the reporter on the parachain.
    /// @param _amount uint256 The staked amount for the parachain.
    function reportStakeDeposited(
        IRegistry.Parachain memory _parachain,
        address _staker,
        bytes calldata _reporter,
        uint256 _amount
    ) internal {
        // Prepare remote call and send

        // The benchmarked weight of report_stake_deposited dispatchable function on the corresponding pallet
        uint64 transactRequiredWeightAtMost = 1218085000;

        bytes memory call = abi.encodePacked(
            _parachain.palletInstance, // pallet index within parachain runtime
            hex"0C", // fixed call index within pallet: 12
            _reporter, // account id of reporter on target parachain
            bytes32(reverse(_amount)), // amount
            _staker // staker
        );
        uint64 overallWeight;
        assembly {
            overallWeight := add(transactRequiredWeightAtMost, mul(xcmInstructionFee, xcmInstructionCount))
        }
        uint256 feeAmount = convertWeightToFee(overallWeight, _parachain.weightToFee);
        transactThroughSigned(
            _parachain.id, transactRequiredWeightAtMost, call, feeAmount, overallWeight, _parachain.feeLocation
        );
    }

    /// @dev Report stake withdraw request to a registered parachain.
    /// @param _parachain Para The registered parachain.
    /// @param _account bytes The account identifier on the parachain.x"0F
    /// @param _amount uint256 The staked amount for the parachain.
    /// @param _staker address The address of the staker.
    function reportStakeWithdrawRequested(
        IRegistry.Parachain memory _parachain,
        bytes memory _account,
        uint256 _amount,
        address _staker
    ) internal {
        // The benchmarked weight of report_staking_withdraw_request dispatchable function on the corresponding pallet
        uint64 transactRequiredWeightAtMost = 1155113000;
        bytes memory call = abi.encodePacked(
            _parachain.palletInstance, // pallet index within parachain runtime
            hex"0D", // fixed call index within pallet: 13
            _account,
            bytes32(reverse(_amount)),
            _staker // staker
        );
        uint64 overallWeight;
        assembly {
            overallWeight := add(transactRequiredWeightAtMost, mul(xcmInstructionFee, xcmInstructionCount))
        }
        uint256 feeAmount = convertWeightToFee(overallWeight, _parachain.weightToFee);
        transactThroughSigned(
            _parachain.id, transactRequiredWeightAtMost, call, feeAmount, overallWeight, _parachain.feeLocation
        );
    }

    /// @dev Report slash to a registered parachain. Recipient will always be the governance contract.
    /// @param _parachain Para The registered parachain.
    /// @param _reporter address The corresponding address of the reporter on the parachain.
    /// @param _amount uint256 Amount slashed.
    function reportSlash(IRegistry.Parachain memory _parachain, bytes memory _reporter, uint256 _amount) internal {
        // The benchmarked weight of report_slash dispatchable function on the corresponding pallet
        uint64 transactRequiredWeightAtMost = 1051143000;
        bytes memory call = abi.encodePacked(
            _parachain.palletInstance, // pallet index within parachain runtime
            hex"0F", // fixed call index within pallet: 15
            _reporter, // account id of reporter on target parachain
            bytes32(reverse(_amount)) // amount
        );
        uint64 overallWeight;
        assembly {
            overallWeight := add(transactRequiredWeightAtMost, mul(xcmInstructionFee, xcmInstructionCount))
        }
        uint256 feeAmount = convertWeightToFee(overallWeight, _parachain.weightToFee);
        transactThroughSigned(
            _parachain.id, transactRequiredWeightAtMost, call, feeAmount, overallWeight, _parachain.feeLocation
        );
    }

    /// @dev Report stake withdraw to a registered parachain.
    /// @param _parachain Para The registered parachain.
    /// @param _reporter address Address of staker on EVM compatible chain w/ Tellor controller contracts.
    /// @param _amount uint256 Amount withdrawn.
    function reportStakeWithdrawn(IRegistry.Parachain memory _parachain, bytes memory _reporter, uint256 _amount)
        internal
    {
        // The benchmarked weight of report_stake_withdrawn dispatchable function on the corresponding pallet
        uint64 transactRequiredWeightAtMost = 261856000;
        bytes memory call = abi.encodePacked(
            _parachain.palletInstance, // pallet index within runtime
            hex"0E", // fixed call index within pallet: 14
            _reporter, // account id of reporter on target parachain
            bytes32(reverse(_amount)) // amount
        );
        uint64 overallWeight;
        assembly {
            overallWeight := add(transactRequiredWeightAtMost, mul(xcmInstructionFee, xcmInstructionCount))
        }
        uint256 feeAmount = convertWeightToFee(overallWeight, _parachain.weightToFee);
        transactThroughSigned(
            _parachain.id, transactRequiredWeightAtMost, call, feeAmount, overallWeight, _parachain.feeLocation
        );
    }

    /// @dev Report vote tallied to registered parachain.
    /// @param _parachain Para The registered parachain.
    /// @param _disputeId bytes32 The unique identifier of the dispute.
    /// @param _outcome VoteResult The outcome of the vote.
    function reportVoteTallied(
        IRegistry.Parachain memory _parachain,
        bytes32 _disputeId,
        IParachainGovernance.VoteResult _outcome
    ) internal {
        // The benchmarked weight of report_vote_tallied dispatchable function on the corresponding pallet
        uint64 transactRequiredWeightAtMost = 198884000;
        bytes memory call = abi.encodePacked(
            _parachain.palletInstance, // pallet index within runtime
            hex"10", // fixed call index within pallet: 16
            _disputeId, // dispute id
            _outcome // outcome
        );
        uint64 overallWeight;
        assembly {
            overallWeight := add(transactRequiredWeightAtMost, mul(xcmInstructionFee, xcmInstructionCount))
        }
        uint256 feeAmount = convertWeightToFee(overallWeight, _parachain.weightToFee);
        transactThroughSigned(
            _parachain.id, transactRequiredWeightAtMost, call, feeAmount, overallWeight, _parachain.feeLocation
        );
    }

    /// @dev Report vote executed to a registered parachain.
    /// @param _parachain Para The registered parachain.
    /// @param _disputeId bytes32 The unique identifier of the dispute.
    function reportVoteExecuted(IRegistry.Parachain memory _parachain, bytes32 _disputeId) internal {
        // The benchmarked weight of report_vote_executed dispatchable function on the corresponding pallet
        uint64 transactRequiredWeightAtMost = 323353000;
        bytes memory call = abi.encodePacked(
            _parachain.palletInstance, // pallet index within runtime
            hex"0D", // fixed call index within pallet: 13
            _disputeId // dispute id
        );
        uint64 overallWeight;
        assembly {
            overallWeight := add(transactRequiredWeightAtMost, mul(xcmInstructionFee, xcmInstructionCount))
        }
        uint256 feeAmount = convertWeightToFee(overallWeight, _parachain.weightToFee);
        transactThroughSigned(
            _parachain.id, transactRequiredWeightAtMost, call, feeAmount, overallWeight, _parachain.feeLocation
        );
    }

    function transactThroughSigned(
        uint32 _paraId,
        uint64 _transactRequiredWeightAtMost,
        bytes memory _call,
        uint256 _feeAmount,
        uint64 _overallWeight,
        XcmTransactorV2.Multilocation memory _feeLocation
    ) private {
        // Create multi-location based on supplied paraId
        XcmTransactorV2.Multilocation memory location = XcmTransactorV2.Multilocation(1, x1(_paraId));
        // Send remote transact
        xcmTransactor.transactThroughSignedMultilocation(
            location, _feeLocation, _transactRequiredWeightAtMost, _call, _feeAmount, _overallWeight
        );
    }

    function parachain(uint32 _paraId) private pure returns (bytes memory) {
        // 0x00 denotes Parachain: https://docs.moonbeam.network/builders/xcm/xcm-transactor/#building-the-precompile-multilocation
        return abi.encodePacked(hex"00", bytes4(_paraId));
    }

    function x1(uint32 _paraId) internal pure returns (bytes[] memory) {
        bytes[] memory interior = new bytes[](1);
        interior[0] = parachain(_paraId);
        return interior;
    }

    // https://ethereum.stackexchange.com/questions/83626/how-to-reverse-byte-order-in-uint256-or-bytes32
    function reverse(uint256 input) internal pure returns (uint256 v) {
        assembly {
            v := input
            // swap bytes
            v :=
                or(
                    shr(8, and(v, 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00)),
                    shl(8, and(v, 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF))
                )

            // swap 2-byte long pairs
            v :=
                or(
                    shr(16, and(v, 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000)),
                    shl(16, and(v, 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF))
                )

            // swap 4-byte long pairs
            v :=
                or(
                    shr(32, and(v, 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000)),
                    shl(32, and(v, 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF))
                )

            // swap 8-byte long pairs
            v :=
                or(
                    shr(64, and(v, 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000)),
                    shl(64, and(v, 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF))
                )

            // swap 16-byte long pairs
            v := or(shr(128, v), shl(128, v))
        }
    }

    function registryAddress() public view returns (address _addr) {
        // return address(registry);
        assembly {
            _addr := sload(registry.slot)
        }
    }

    /// @dev Converts provided weight to fee for XCM execution.
    /// @param overallWeight uint256 Combined weight of consumer chain's dispatchable function (wrapped in transact) and XCM instructions.
    /// @param weightToFee uint256 Fee per weight (constant multiplier)
    function convertWeightToFee(uint256 overallWeight, uint256 weightToFee) internal pure returns (uint256 z) {
        // overall xcm fee cost based on constantMultiplier
        assembly {
            z := mul(overallWeight, weightToFee)
        }
    }
}
