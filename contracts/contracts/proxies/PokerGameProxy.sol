// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract PokerGameProxy is UUPSUpgradeable {
    address public implementation;
    address public admin;

    event ImplementationChanged(address indexed newImplementation);

    constructor(address _implementation) {
        implementation = _implementation;
        admin = msg.sender;
    }

    fallback() external payable {
        _delegate(implementation);
    }

    receive() external payable {
        _delegate(implementation);
    }

    function _delegate(address _impl) internal {
        (bool success, ) = _impl.delegatecall(msg.data);
        require(success, "Delegatecall failed");
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyAdmin {
        implementation = newImplementation;
        emit ImplementationChanged(newImplementation);
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can upgrade");
        _;
    }
}
