// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// Various helper methods for interfacing with the Tellor pallet on another parachain via XCM
import "../lib/moonbeam/precompiles/XcmTransactorV2.sol";
import "../lib/moonbeam/precompiles/XcmUtils.sol";

interface IRegistry {
    struct Parachain {
        uint32 id;
        address owner;
        bytes palletInstance;
        uint256 weightToFee;
        XcmTransactorV2.Multilocation feeLocation;
        Weights weights;
    }

    struct Weights {
        uint64 reportStakeDeposited;
        uint64 reportStakeWithdrawRequested;
        uint64 reportStakeWithdrawn;
        uint64 reportVoteTallied;
        uint64 reportVoteExecuted;
        uint64 reportSlash;
    }


    function getById(uint32 _id) external view returns (Parachain memory);
    function getByAddress(address _address) external view returns (Parachain memory);
}

contract ParachainRegistry is IRegistry {
    mapping(uint32 => Parachain) private registrations; // Parachain ID => Parachain
    mapping(address => uint32) private owners; // Owner => Parachain ID

    XcmTransactorV2 private constant xcmTransactor = XCM_TRANSACTOR_V2_CONTRACT;
    XcmUtils private constant xcmUtils = XCM_UTILS_CONTRACT;

    event ParachainRegistered(address caller, uint32 parachain, address owner);

    /// @dev Register parachain, along with index of Tellor pallet within corresponding runtime.
    /// @param _paraId uint32 The parachain identifier.
    /// @param _palletInstance uint8 The index of the Tellor pallet within the parachain's runtime.
    /// @param _weightToFee uint256 The constant multiplier(fee per weight) used to convert weight to fee
    /// @param _feeLocation XcmTransactorV2.Multilocation The location of the currency type of consumer chain.
    /// @param _weights Weights Weight of dispatchables on the corresponding pallet
    function register(
        uint32 _paraId,
        uint8 _palletInstance,
        uint256 _weightToFee,
        XcmTransactorV2.Multilocation memory _feeLocation,
        Weights memory _weights
    ) external {
        // Ensure sender is on parachain
        address derivativeAddress =
            xcmUtils.multilocationToAddress(XcmUtils.Multilocation(1, x2(_paraId, _palletInstance)));
        require(msg.sender == derivativeAddress, "Not owner");
        registrations[_paraId] =
            Parachain(_paraId,
                      msg.sender,
                      abi.encodePacked(_palletInstance),
                      _weightToFee,
                      _feeLocation,
                      _weights);
        owners[msg.sender] = _paraId;
        emit ParachainRegistered(msg.sender, _paraId, msg.sender);
    }

    function getById(uint32 _id) external view override returns (Parachain memory) {
        return registrations[_id];
    }

    function getByAddress(address _address) external view override returns (Parachain memory) {
        return registrations[owners[_address]];
    }

    function parachain(uint32 _paraId) private pure returns (bytes memory) {
        // 0x00 denotes Parachain: https://docs.moonbeam.network/builders/xcm/xcm-transactor/#building-the-precompile-multilocation
        return abi.encodePacked(hex"00", abi.encodePacked(_paraId));
    }

    function pallet(uint8 _palletInstance) private pure returns (bytes memory) {
        // 0x04 denotes PalletInstance: https://docs.moonbeam.network/builders/xcm/xcm-transactor/#building-the-precompile-multilocation
        return abi.encodePacked(hex"04", abi.encodePacked(_palletInstance));
    }

    function x2(uint32 _paraId, uint8 _palletInstance) public pure returns (bytes[] memory) {
        bytes[] memory interior = new bytes[](2);
        interior[0] = parachain(_paraId);
        interior[1] = pallet(_palletInstance);
        return interior;
    }
}
