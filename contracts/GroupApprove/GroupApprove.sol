// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "./IMPC.sol";
import "./ICross.sol";

contract GroupApprove {
    struct Task {
        address to;
        bytes data;
        bool executed;
    }

    struct SigData {
        bytes32 sigHash;
        bytes32 smgID; 
        bytes r;
        bytes32 s;
    }

    // slip-0044 chainId
    uint256 public chainId;
    uint256 public taskCount;
    address public foundation;
    address public signatureVerifier;
    address public oracle;

    // proposalId => task
    mapping(uint256 => Task) public tasks;

    enum GroupStatus { none, initial, curveSet, failed, selected, ready, unregistered, dismissed }

    modifier onlyFoundation() {
        require(msg.sender == foundation, "not foundation");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "not self");
        _;
    }

    modifier onlySmg(uint proposalId, bytes32 smgID, bytes calldata r, bytes32 s) {
        bytes32 sigHash = keccak256(abi.encode(proposalId, chainId));
        _verifyMpcSignature(
            SigData(
                sigHash, smgID, r, s
            )
        );
        _;
    }

    event Proposal(
        uint256 indexed proposalId, 
        address indexed to, 
        bytes data
    );

    event ApprovedAndExecuted(
        uint256 indexed proposalId, 
        address indexed to, 
        bytes data,
        bytes32 smgID
    );

    event TransferFoundation(
        address indexed oldFoundation, 
        address indexed newFoundation
    );

    error SignatureVerifyFailed(
        bytes32 smgID,
        bytes32 sigHash,
        bytes r,
        bytes32 s
    );

    error StoremanGroupNotReady(
        bytes32 smgID,
        uint256 status,
        uint256 timestamp,
        uint256 startTime,
        uint256 endTime
    );
    
    constructor(address _foundation, address _signatureVerifier, address _oracle, address _cross) {
        require(_foundation != address(0), "foundation is empty");
        address _oracleCross;
        address _signatureVerifierCross;

        // cross check oracle and signatureVerifier address with cross contract
        (, _oracleCross, , , _signatureVerifierCross) = ICross(_cross).getPartners();
        oracle = _oracle;
        signatureVerifier = _signatureVerifier;
        require(_oracle == _oracleCross, "oracle not match");
        require(_signatureVerifier == _signatureVerifierCross, "signatureVerifier not match");

        chainId = ICross(_cross).currentChainID(); // read from cross
        require(chainId != 0, "chainId is empty");

        foundation = _foundation;
    }

    function proposal(
        uint256 _chainId,
        address _to, 
        bytes memory _data
    ) external onlyFoundation {
        require(_data.length > 0, "data is empty");
        require(_to != address(0), "to is empty");
        require(_chainId == chainId, "chainId not match");

        // save task 
        tasks[taskCount] = Task(_to, _data, false);
        emit Proposal(taskCount, _to, _data);
        taskCount++;
    }

    function approveAndExecute(
        uint256 proposalId,
        bytes32 smgID,
        bytes calldata r,
        bytes32 s
    ) external onlySmg(proposalId, smgID, r, s) {
        Task storage task = tasks[proposalId];
        require(task.to != address(0), "task not exists");
        require(!task.executed, "task already executed");

        (bool success, ) = task.to.call(task.data);
        require(success, "call failed");
        task.executed = true;
        emit ApprovedAndExecuted(proposalId, task.to, task.data, smgID);
    }

    function halt(address _to, bool _halt) external onlyFoundation {
        ICross(_to).setHalt(_halt);
    }

    function transferFoundation(address _newFoundation) external onlySelf {
        require(_newFoundation != address(0), "new foundation is empty");
        require(_newFoundation != foundation, "new foundation is same as old");
        foundation = _newFoundation;
        emit TransferFoundation(foundation, _newFoundation);
    }

    // -------- internal functions --------

    /// @notice                                 check the storeman group is ready or not
    /// @param smgID                            ID of storeman group
    /// @return curveID                         ID of elliptic curve
    /// @return PK                              PK of storeman group
    function _acquireReadySmgInfo(bytes32 smgID)
        internal
        view
        returns (uint curveID, bytes memory PK)
    {
        uint8 status;
        uint startTime;
        uint endTime;
        (,status,,,,curveID,,PK,,startTime,endTime) = IMPC(oracle).getStoremanGroupConfig(smgID);

        if (!(status == uint8(GroupStatus.ready) && block.timestamp >= startTime && block.timestamp <= endTime)) {
            revert StoremanGroupNotReady({
                smgID: smgID,
                status: uint256(status),
                timestamp: block.timestamp,
                startTime: startTime,
                endTime: endTime
            });
        }

        return (curveID, PK);
    }

    /// @notice       convert bytes to bytes32
    /// @param b      bytes array
    /// @param offset offset of array to begin convert
    function _bytesToBytes32(bytes memory b, uint offset) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(add(b, offset), 32))
        }
    }

    /**
     * @dev Verifies an MPC signature for a given message and Storeman Group ID
     * @param sig The signature to verify
     */
    function _verifyMpcSignature(SigData memory sig) internal {
        uint curveID;
        bytes memory PK;

        // Acquire the curve ID and group public key for the given Storeman Group ID
        (curveID, PK) = _acquireReadySmgInfo(sig.smgID);

        // Extract the X and Y components of the group public key
        bytes32 PKx = _bytesToBytes32(PK, 0);
        bytes32 PKy = _bytesToBytes32(PK, 32);

        // Extract the X and Y components of the signature
        bytes32 Rx = _bytesToBytes32(sig.r, 0);
        bytes32 Ry = _bytesToBytes32(sig.r, 32);

        // Verify the signature using the Wanchain MPC contract
        if (!IMPC(signatureVerifier).verify(curveID, sig.s, PKx, PKy, Rx, Ry, sig.sigHash)) {
            revert SignatureVerifyFailed({
                smgID: sig.smgID,
                sigHash: sig.sigHash,
                r: sig.r,
                s: sig.s
            });
        }
    }
}
