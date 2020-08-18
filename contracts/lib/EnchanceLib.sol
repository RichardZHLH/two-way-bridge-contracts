/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
pragma solidity ^0.4.24;
import "./SafeMath.sol";

library EnhancementLib {

    using SafeMath for uint;
    uint public constant DIVISOR = 10000;
    address constant PRECOMPILE_CONTRACT_ADDR = 0x268;

    /**
     * public function
     * @dev get epochid according to the giving blockTime
     *
     * @param blockTime the block time for caculate echoid
     * @return epochid
     */
    function getEpochId(uint256 blockTime) public view returns (uint256) {
        bytes32 functionSelector = keccak256("getEpochId(uint256)");

        (uint256 result, bool success) = callWith32BytesReturnsUint256(
            0x262,
            functionSelector,
            bytes32(blockTime)
        );

        require(success, "ASSEMBLY_CALL getEpochId failed");

        return result;
    }

    /**
     * public function
     * @dev get the pos return rate for storeman group at the specified time
     * @param groupStartTime the start time for storeman group
     * @param curTime the time for getting return rate
     * @return result the return rate for pos at current time
     * @return success the result for calling precompile contract,true is success,false is failed
     */
    function getPosAvgReturn(uint256 groupStartTime,uint256 curTime)  public view returns(uint256 result,bool success) {

       bytes32 functionSelector = 0x8c114a5100000000000000000000000000000000000000000000000000000000;
       address to = PRECOMPILE_CONTRACT_ADDR;

       assembly {
            let freePtr := mload(0x40)
            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), groupStartTime)
            mstore(add(freePtr, 36), curTime)

            // call ERC20 Token contract transfer function
            success := staticcall(gas, to, freePtr,68, freePtr, 32)
            result := mload(freePtr)
        }
    }

    /**
     * public function
     * @dev add 2 point on the curve
     * @param x1 the x value for first point
     * @param y1 the y value for first point
     * @param x2 the x value for second point
     * @param y2 the y value for second point
     * @return retx the x value for result point
     * @return rety the y value for result point
     * @return success the result for calling precompile contract,true is success,false is failed
     */
    function add(uint256 x1, uint256 y1, uint256 x2,uint256 y2)  public view returns(uint256 retx, uint256 rety,bool success) {

       bytes32 functionSelector =0xe022d77c00000000000000000000000000000000000000000000000000000000;
       address to = PRECOMPILE_CONTRACT_ADDR;

       assembly {
            let freePtr := mload(0x40)
            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), x1)
            mstore(add(freePtr, 36), y1)
            mstore(add(freePtr, 68), x2)
            mstore(add(freePtr, 100), y2)

            // call ERC20 Token contract transfer function
            success := staticcall(gas,to, freePtr,132, freePtr, 64)

            retx := mload(freePtr)
            rety := mload(add(freePtr,32))
        }

    }

    /**
     * public function
     * @dev point on curve to multiple base point
     * @param scalar for mul
     * @return x the x value for result point
     * @return y the y value for result point
     * @return success the result for calling precompile contract,true is success,false is failed
     */
    function s256MulG(uint256 scalar)   public view returns(uint256 x, uint256 y,bool success) {
        bytes32 functionSelector = 0xbb734c4e00000000000000000000000000000000000000000000000000000000;//keccak256("mulG(uint256)");
        address to = PRECOMPILE_CONTRACT_ADDR;
        assembly {
            let freePtr := mload(0x40)

            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), scalar)

            // call ERC20 Token contract transfer function
            success := staticcall(gas, to, freePtr,36, freePtr, 64)

            x := mload(freePtr)
            y := mload(add(freePtr,32))
        }

    }
	
    /**
     * public function     
     * @dev point on curve to multiple base point
     * @param scalar for mul 
     * @return x the x value for result point
     * @return y the y value for result point
     * @return success the result for calling precompile contract,true is success,false is failed
     */ 
    function bn256MulG(uint256 scalar)   public view returns(uint256 x, uint256 y,bool success) {
        bytes32 functionSelector = 0x0e5725cd00000000000000000000000000000000000000000000000000000000;
        address to = PRECOMPILE_CONTRACT_ADDR;
        assembly {
            let freePtr := mload(0x40)

            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), scalar)

            // call ERC20 Token contract transfer function
            success := staticcall(gas, to, freePtr,36, freePtr, 64)

            x := mload(freePtr)
            y := mload(add(freePtr,32))   
        }
        
    }



    function s256CalPolyCommit(bytes polyCommit, bytes pk)   public view returns(uint256 sx, uint256 sy,bool success) {

        bytes32 functionSelector = 0x66c85fc200000000000000000000000000000000000000000000000000000000;
       return polyCal(polyCommit,pk,functionSelector);
    }

    function bn256CalPolyCommit(bytes polyCommit, bytes pk)  public view returns (uint256 sx, uint256 sy,bool success) {

       bytes32 functionSelector = 0x77f683ba00000000000000000000000000000000000000000000000000000000;
       return polyCal(polyCommit,pk,functionSelector);
    }

    function polyCal(bytes polyCommit, bytes pk,bytes32 functionSelector) internal view returns(uint256 sx, uint256 sy,bool success) {
        address to = PRECOMPILE_CONTRACT_ADDR;
       require((polyCommit.length + pk.length)%64 == 0, "error len polyCommint or pk");

       uint polyCommitCnt = polyCommit.length/64;
       uint total = (polyCommitCnt + 1)*2;

       assembly {
            let freePtr := mload(0x40)
            mstore(freePtr, functionSelector)
            mstore(add(freePtr,4), mload(add(polyCommit,32)))
            mstore(add(freePtr,36), mload(add(polyCommit,64)))
            let loopCnt := 1
            loop:
                jumpi(loopend, eq(loopCnt,polyCommitCnt))
                mstore(add(freePtr,add(4,mul(loopCnt,64))),         mload(add(add(add(polyCommit,32),mul(loopCnt,64)),0)))
                mstore(add(freePtr,add(4,add(mul(loopCnt,64),32))), mload(add(add(add(add(polyCommit,32),mul(loopCnt,64)),0),32)))
                loopCnt := add(loopCnt, 1)
                jump(loop)
            loopend:

            mstore(add(freePtr,    add(4,mul(loopCnt,64))),     mload(add(pk,32)))
            mstore(add(freePtr,add(add(4,mul(loopCnt,64)),32)), mload(add(pk,64)))

            success := staticcall(gas,to, freePtr,add(mul(total,32),4), freePtr, 64)

            sx := mload(freePtr)
            sy := mload(add(freePtr, 32))
        }
    }

    /**
     * public function
     * @dev encrypt message according to specified random,iv and public key
     * @param rbpri the specified random numbers
     * @param iv the specified iv value
     * @param mes the plain message for encrypt
     * @param pub the public key for encrypt
     * @return bytes the encrypted message
     * @return success the result for calling precompile contract,true is success,false is failed
     */
    function enc(bytes32 rbpri,bytes32 iv,uint256 mes, bytes pub)   public view returns (bytes,bool success) {
       bytes32 functionSelector = 0xa1ecea4b00000000000000000000000000000000000000000000000000000000;
       address to = PRECOMPILE_CONTRACT_ADDR;
       bytes memory cc = new bytes(6*32);
       assembly {
           let freePtr := mload(0x40)
            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), rbpri)
            mstore(add(freePtr, 36), iv)
            mstore(add(freePtr, 68), mes)
            mstore(add(freePtr, 100), mload(add(pub,32)))
            mstore(add(freePtr, 132), mload(add(pub,64)))

            // call ERC20 Token contract transfer function
            success := staticcall(gas,to, freePtr,164, freePtr,1024)

            let loopCnt := 0
            loop:
                jumpi(loopend, eq(loopCnt,6))
                mstore(add(cc,mul(add(loopCnt,1),32)),mload(add(freePtr,mul(loopCnt,32))))
                loopCnt := add(loopCnt, 1)
                jump(loop)
            loopend:
        }

        return (cc,success);
    }


    /**
     * public function
     * @dev verify the signature
     * @param hash the hash value for signature
     * @param r the r value for signature
     * @param s the s value for signature
     * @param pk the public key for encrypt
     * @return bool the result for verify,true is success,false is failed
     */
    function checkSig (bytes32 hash, bytes32 r, bytes32 s, bytes pk) public view returns(bool) {
       bytes32 functionSelector = 0x861731d500000000000000000000000000000000000000000000000000000000;
       address to = PRECOMPILE_CONTRACT_ADDR;
       uint256 result;
       bool success;
       assembly {
            let freePtr := mload(0x40)

            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), hash)
            mstore(add(freePtr, 36), r)
            mstore(add(freePtr, 68), s)
            mstore(add(freePtr, 100), mload(add(pk,32)))
            mstore(add(freePtr, 132), mload(add(pk,64)))

            // call ERC20 Token contract transfer function
            success := staticcall(gas, to, freePtr,164, freePtr, 32)

            result := mload(freePtr)
        }

        if (success) {
            return result == 1;
        } else {
            return false;
        }
    }


    /**
     * public function
     * @dev get the hard cap for storeman return rate
     * @param time for caculation
     * @return uint256 the hard cap for storeman return
     * @return bool the result for calling precompile contract,true is success,false is failed
     */
    function getHardCap (uint256 time) public view returns(uint256,bool) {
       bytes32 functionSelector = 0xfa7c2faf00000000000000000000000000000000000000000000000000000000;
       address to = PRECOMPILE_CONTRACT_ADDR;
       uint256 posReturn;
       bool    success;
       assembly {
            let freePtr := mload(0x40)
            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), time)
            success := staticcall(gas, to, freePtr,36, freePtr, 32)
            posReturn := mload(freePtr)
        }

        return (posReturn,success);

    }

    /**
     * public function
     * @dev get minimum incentive for storeman group
     * @param smgDeposit the storeman deposit
     * @param smgStartTime the storeman group start time
     * @return uint256 the minimum return for storeman group
     */
    function getMinIncentive (uint256 smgDeposit,uint256 smgStartTime) public view returns(uint256) {

        uint256 p1;
        bool    success;

        (p1,success) = getPosAvgReturn(smgStartTime,now);
        if(!success) {
            return 0;
        }
        uint256 p1Return = smgDeposit.mul(p1).div(DIVISOR);

        uint256 hardcap;
        (hardcap,success) = getHardCap(now);
        if(!success) {
            return 0;
        }

        uint256 hardcapReturn = hardcap.mul(1 ether).div(DIVISOR);

        return hardcapReturn<=p1Return?hardcapReturn:p1Return;
    }

    /**
     * public function
     * @dev point on curve to multiple scalar
     * @param scalar for mul
     * @return xPk the x value for result point
     * @return yPk the y value for result point
     * @return success the result for calling precompile contract,true is success,false is failed
     */
    function mulPk(uint256 scalar, uint256 xPk, uint256 yPk)
       public
       view
       returns (uint256 x, uint256 y, bool success) {
       bytes32 functionSelector = 0xa99aa2f200000000000000000000000000000000000000000000000000000000;
       address to = PRECOMPILE_CONTRACT_ADDR;

       assembly {
            let freePtr := mload(0x40)
            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), scalar)
            mstore(add(freePtr,36), xPk)
            mstore(add(freePtr,68), yPk)

            success := staticcall(gas, to, freePtr,100, freePtr, 64)

            x := mload(freePtr)
            y := mload(add(freePtr,32))
        }

    }

    /**
     * public function
     * @dev point on curve to multiple scalar on s256
     * @param scalar for mul
     * @return xPk the x value for result point
     * @return yPk the y value for result point
     * @return success the result for calling precompile contract,true is success,false is failed
     */
    function s256ScalarMul(uint256 scalar, uint256 xPk, uint256 yPk)
    public
    view
    returns (uint256 x, uint256 y, bool success) {
       address to = 0x43;
       assembly {
            let freePtr := mload(0x40)
            mstore(add(freePtr, 0), scalar)
            mstore(add(freePtr,32), xPk)
            mstore(add(freePtr,64), yPk)

            success := staticcall(gas, to, freePtr,96, freePtr, 64)

            x := mload(freePtr)
            y := mload(add(freePtr,32))
        }

    }


    /**
     * public function
     * @dev add 2 point on the curve
     * @param x1 the x value for first point
     * @param y1 the y value for first point
     * @param x2 the x value for second point
     * @param y2 the y value for second point
     * @return retx the x value for result point
     * @return rety the y value for result point
     * @return success the result for calling precompile contract,true is success,false is failed
     */
    function s256add(uint256 x1, uint256 y1, uint256 x2,uint256 y2)  public view returns(uint256 retx, uint256 rety,bool success) {
       address to = 0x42;
       assembly {
            let freePtr := mload(0x40)
            mstore(add(freePtr, 0), x1)
            mstore(add(freePtr, 32), y1)
            mstore(add(freePtr, 64), x2)
            mstore(add(freePtr, 96), y2)

            // call ERC20 Token contract transfer function
            success := staticcall(gas,to, freePtr,128, freePtr, 64)

            retx := mload(freePtr)
            rety := mload(add(freePtr,32))
        }

    }


    /**
     * public function
     * @dev point on curve to multiple scalar on s256
     * @param scalar for mul
     * @return xPk the x value for result point
     * @return yPk the y value for result point
     * @return success the result for calling precompile contract,true is success,false is failed
     */
    function bn256ScalarMul(uint256 scalar, uint256 xPk, uint256 yPk)
    public
    view
    returns (uint256 x, uint256 y, bool success) {
       address to = 0x7;

       assembly {
            let freePtr := mload(0x40)
            mstore(add(freePtr,0), xPk)
            mstore(add(freePtr,32), yPk)
            mstore(add(freePtr, 64), scalar)

            success := staticcall(gas, to, freePtr,96, freePtr, 64)

            x := mload(freePtr)
            y := mload(add(freePtr,32))
        }

    }


    /**
     * public function
     * @dev add 2 point on the curve bn256
     * @param x1 the x value for first point
     * @param y1 the y value for first point
     * @param x2 the x value for second point
     * @param y2 the y value for second point
     * @return retx the x value for result point
     * @return rety the y value for result point
     * @return success the result for calling precompile contract,true is success,false is failed
     */
    function bn256add(uint256 x1, uint256 y1, uint256 x2,uint256 y2)  public view returns(uint256 retx, uint256 rety,bool success) {
       address to = 0x6;
       assembly {
            let freePtr := mload(0x40)
            mstore(add(freePtr, 0), x1)
            mstore(add(freePtr, 32), y1)
            mstore(add(freePtr, 64), x2)
            mstore(add(freePtr, 96), y2)

            // call ERC20 Token contract transfer function
            success := staticcall(gas,to, freePtr,128, freePtr, 64)

            retx := mload(freePtr)
            rety := mload(add(freePtr,32))
        }

    }

   /**
     * public function
     * @dev point on curve to multiple scalar on s256
     * @param input check paring data
     * @return success the result for calling precompile contract,true is success,false is failed
     */
    function bn256Pairing(bytes memory input) public returns (bytes32 result) {
        // input is a serialized bytes stream of (a1, b1, a2, b2, ..., ak, bk) from (G_1 x G_2)^k
        uint256 len = input.length;
        require(len % 192 == 0);
        assembly {
            let memPtr := mload(0x40)
            let success := call(gas, 0x08, 0, add(input, 0x20), len, memPtr, 0x20)
            switch success
            case 0 {
                revert(0,0)
            } default {
                result := mload(memPtr)
            }
        }


    }


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function callWith32BytesReturnsUint256(
        address to,
        bytes32 functionSelector,
        bytes32 param1
    ) private view returns (uint256 result, bool success) {
        assembly {
            let freePtr := mload(0x40)

            mstore(freePtr, functionSelector)
            mstore(add(freePtr, 4), param1)

            // call ERC20 Token contract transfer function
            success := staticcall(gas, to, freePtr, 36, freePtr, 32)

            result := mload(freePtr)
        }
    }



}