// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin-upgradeable/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin-upgradeable/contracts/utils/introspection/ERC165Upgradeable.sol";
import "@openzeppelin-upgradeable/contracts/utils/introspection/IERC165Upgradeable.sol";

interface IRecoveryChildV1 is IERC165Upgradeable {
    function getRecoveryParentToken() external view returns (address, uint256);
}

abstract contract RecoveryChildV1 is Initializable, ERC165Upgradeable, IRecoveryChildV1 {
    address public recoveryParentTokenContract;
    uint256 public recoveryParentTokenId;

    function __RecoveryChildV1_init(address _recoveryParentTokenContract, uint256 _recoveryParentTokenId)
        internal
        onlyInitializing
    {
        recoveryParentTokenContract = _recoveryParentTokenContract;
        recoveryParentTokenId = _recoveryParentTokenId;
    }

    function getRecoveryParentToken() public view returns (address, uint256) {
        return (recoveryParentTokenContract, recoveryParentTokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165Upgradeable, ERC165Upgradeable)
        returns (bool)
    {
        return interfaceId == type(IRecoveryChildV1).interfaceId || super.supportsInterface(interfaceId);
    }
}
