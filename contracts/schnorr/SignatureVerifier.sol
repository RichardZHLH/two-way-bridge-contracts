pragma solidity ^0.4.24;

import "../components/Halt.sol";
import "../interfaces/ISignatureVerifier.sol";

/// @dev for multi curves contract call.
interface IBaseSignVerifier {
    function verify(
        bytes32 signature,
        bytes32 groupKeyX,
        bytes32 groupKeyY,
        bytes32 randomPointX,
        bytes32 randomPointY,
        bytes32 message
    ) external returns (bool);
}

contract SignatureVerifier is Halt {

    /// @dev a map from a uint256 curveId to it's verifier contract address.
    mapping(uint256 => address) public verifierMap;

    /// @dev verify is used for check signature.
    function verify(
        uint256 curveId,
        bytes32 signature,
        bytes32 groupKeyX,
        bytes32 groupKeyY,
        bytes32 randomPointX,
        bytes32 randomPointY,
        bytes32 message
    ) external returns (bool) {
        require(verifierMap[curveId] != address(0), "curveId not correct");
        IBaseSignVerifier verifier = IBaseSignVerifier(verifierMap[curveId]);
        return verifier.verify(signature, groupKeyX, groupKeyY, randomPointX, randomPointY, message);
    }

    function register(uint256 curveId, address verifierAddress) external onlyOwner {
        verifierMap[curveId] = verifierAddress;
    }
}
