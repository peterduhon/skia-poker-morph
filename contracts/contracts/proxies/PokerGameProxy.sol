// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract SkiaPokerProxy is UUPSUpgradeable {
    address public admin;

    event ImplementationChanged(address indexed newImplementation);

    constructor(address initialImplementation) {
        _upgradeTo(initialImplementation);
        admin = msg.sender;
    }

    fallback() external payable {
        _delegate(_implementation());
    }

    receive() external payable {
        _delegate(_implementation());
    }

    function _delegate(address implementation) internal {
        (bool success, ) = implementation.delegatecall(msg.data);
        require(success, "Delegatecall failed");
    }

    function _implementation() internal view returns (address impl) {
        bytes32 position = keccak256("eip1967.proxy.implementation");
        assembly {
            impl := sload(position)
        }
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {
        _upgradeTo(newImplementation);
        emit ImplementationChanged(newImplementation);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can upgrade");
        _;
    }
}
