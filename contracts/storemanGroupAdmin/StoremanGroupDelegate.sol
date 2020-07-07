/*

  Copyright 2019 Wanchain Foundation.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

//                            _           _           _
//  __      ____ _ _ __   ___| |__   __ _(_)_ __   __| | _____   __
//  \ \ /\ / / _` | '_ \ / __| '_ \ / _` | | '_ \@/ _` |/ _ \ \ / /
//   \ V  V / (_| | | | | (__| | | | (_| | | | | | (_| |  __/\ V /
//    \_/\_/ \__,_|_| |_|\___|_| |_|\__,_|_|_| |_|\__,_|\___| \_/
//
//  Code style according to: https://github.com/wanchain/wanchain-token/blob/master/style-guide.rst

pragma solidity ^0.4.24;
//pragma experimental ABIEncoderV2;

import "../lib/SafeMath.sol";
import "../components/Halt.sol";
import "./StoremanGroupStorage.sol";
import "../lib/PosLib.sol";
import "./StoremanLib.sol";
import "./StoremanType.sol";
import "./IncentiveLib.sol";
import "../interfaces/IQuota.sol";


contract StoremanGroupDelegate is StoremanGroupStorage, Halt {
    using SafeMath for uint;
    using Deposit for Deposit.Records;
    /**
     *
     * EVENTS
     *
     */


    event registerStartEvent(bytes32 indexed groupId, uint workStart,uint workDuration, uint registerDuration, bytes32 indexed preGroupId);
    event StoremanGroupUnregisterEvent(bytes32 indexed groupId);


    /// @notice                           event for dissmiss storeman group
    /// @param tokenOrigAccount           token account of original chain
    /// @param storemanGroup              storeman group address
    /// @param dismissTime                  the time for storeman dismiss
    event StoremanGroupDismissedLogger(bytes tokenOrigAccount, bytes storemanGroup, uint dismissTime);

    /// @notice                           event for storeman group withdraw deposit
    /// @param tokenOrigAccount           token account of original chain
    /// @param storemanGroup              storeman group PK
    /// @param actualReturn               actual amount wan coin received, for penalty extension
    /// @param deposit                    deposit in the first place
    event StoremanGroupWithdrawLogger(bytes tokenOrigAccount, bytes storemanGroup, uint actualReturn, uint deposit);

    /// @notice                           event for storeman group update deposit
    /// @param tokenOrigAccount           token account of original chain
    /// @param storemanGroup              storeman group PK
    /// @param wanDeposit                 deposit wancoin number
    /// @param quota                      corresponding token quota
    /// @param txFeeRatio                 storeman fee ratio
    event StoremanGroupUpdateLogger(bytes tokenOrigAccount, bytes storemanGroup, uint wanDeposit, uint quota, uint txFeeRatio);


    modifier onlyGpk {
        require(msg.sender == greateGpkAddr, "Sender is not allowed");
        _;
    }

    modifier onlyGroupLeader(bytes32 groupId) {
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        require(msg.sender == group.selectedNode[0], "Sender is not allowed");
        _;
    }
    /**
    *
    * MANIPULATIONS
    *
    */
    /// @notice                           function for owner set token manager and htlc contract address
    /// @param tmAddr                     token manager contract address
    /// @param htlcAddr                   htlc contract address
    function setDependence(address tmAddr, address htlcAddr, address gpkAddr,address quotaAddr)
        external
        onlyOwner
    {
        require(tmAddr != address(0), "Invalid tokenManager address");
        require(htlcAddr != address(0), "Invalid htlc address");
        tokenManager = ITokenManager(tmAddr);
        htlc = IHTLC(htlcAddr);
        greateGpkAddr = gpkAddr;
        quotaInst = IQuota(quotaAddr);
    }



    function setBackupCount(uint backup) 
        public onlyOwner
    {
        backupCount = backup;
    }
    function getBackupCount() public view returns (uint) {
        return backupCount;
    }

    function groupWhiteNode(StoremanType.StoremanGroup storage group,bytes32 preGroupId, address[] wkAddrs, address[] senders) internal{
        for(uint i = 0; i < wkAddrs.length; i++){
            group.whiteMap[i] = wkAddrs[i];
            group.whiteWk[wkAddrs[i]] = senders[i];
            if(i < group.whiteCount) {
                group.selectedNode[i] = wkAddrs[i];
            }
        }
        group.selectedCount = group.whiteCount;

        // TODO handle the old group member. set the group deposit.
        if(preGroupId != bytes32(0x00)) {
            StoremanType.StoremanGroup storage oldGroup = data.groups[preGroupId];
            for(uint m = oldGroup.whiteCount; m<oldGroup.memberCountDesign; m++) {
                address skAddr = oldGroup.selectedNode[m];
                StoremanType.Candidate sk = data.candidates[skAddr];
                if(sk.groupId == preGroupId && sk.quited == false) {
                    group.selectedNode[group.selectedCount] = sk.pkAddress;
                    group.selectedCount++;
                }
            }
        }
    }
    /// @notice                           function for owner set token manager and htlc contract address
    /// @param groupId                    the building storeman group index.
    /// @param wkAddrs                    white list work address.
    /// @param senders                    senders address of the white list enode.
    /// @param workStart                  When the group start to work. the day ID;
    /// @param workDuration               how many days the group will work for
    /// @param registerDuration           how many days the duration that allow transfer staking.
    /// @param preGroupId                 the preview group index.
    function registerStart(bytes32 groupId,
        uint workStart,uint workDuration, uint registerDuration,  bytes32 preGroupId,  address[] wkAddrs, address[] senders)
        external
        onlyOwner
    {
        require(wkAddrs.length == senders.length, "Invalid white list length");
        require(wkAddrs.length > backupCount, "Insufficient white list");

        Deposit.Records memory deposit =  Deposit.Records(0);
        Deposit.Records memory depositWeight =  Deposit.Records(0);

        StoremanType.StoremanGroup storage group = data.groups[groupId];
        require(group.status == StoremanType.GroupStatus.none, "group has existed already");
        group.groupId = groupId;
        group.status = StoremanType.GroupStatus.initial;
        group.deposit = deposit;
        group.depositWeight = depositWeight;
        group.workDay = workStart;
        group.totalDays = workDuration;
        group.memberCountDesign = memberCountDefault;
        group.threshold = thresholdDefault;
        group.whiteCount = wkAddrs.length - backupCount;
        group.whiteCountAll = wkAddrs.length;
        emit registerStartEvent(groupId, workStart, workDuration, registerDuration, preGroupId);
        return groupWhiteNode(group, preGroupId, wkAddrs, senders);
    }
    function setGroupChain(bytes32 groupId,  uint chain1, uint chain2, uint curve1, uint curve2)
        external
        onlyOwner
    {

        StoremanType.StoremanGroup storage group = data.groups[groupId];
        group.chain1 = chain1;
        group.chain2 = chain2;
        group.curve1 = curve1;
        group.curve2 = curve2;
        group.status = StoremanType.GroupStatus.curveSeted;
    }
    function updateGroupConfig(bytes32 groupId, uint memberCountdesign, uint threshold)
        external
        onlyOwner
    {

        StoremanType.StoremanGroup storage group = data.groups[groupId];
        group.memberCountDesign = memberCountdesign;
        group.threshold = threshold;
    }

    // function getStaker(bytes32 groupId, address pkAddr) public view returns (bytes PK,uint delegateFee,uint delegatorCount) {
    //     StoremanType.Candidate storage sk = groups[groupId].candidates[pkAddr];
    //     return (sk.PK, sk.delegateFee, sk.delegatorCount);
    // }
    function getGroupIdbyAddress(address pkAddr) public view returns (bytes32, bytes32) {
        StoremanType.Candidate storage sk = data.candidates[pkAddr];
        return (sk.groupId, sk.nextGroupId);
    }


    /*
    The logic of incentive
    1) get the incentive by day and groupID.
    If the incentive array by day haven't geted from low level, the tx will try to get it.
    so the one who first incentive will spend more gas.

    2) calculate the sk incentive all days.
    3) calculate the delegator all days one by one.
     */
    function testIncentiveAll( address wkAddr) public  {
        IncentiveLib.incentiveCandidator(data, wkAddr);
    }

    function stakeIn(bytes32 groupId, bytes PK, bytes enodeID, uint delegateFee)
        public payable
    {
        return StoremanLib.stakeIn(data,groupId, PK, enodeID, delegateFee);
    }

    function stakeAppend(address skPkAddr) public payable {
        return StoremanLib.stakeAppend(data, skPkAddr);
    }

    function stakeOut(address skPkAddr) public {
        return StoremanLib.stakeOut(data, skPkAddr);
    }

    function stakeClaim(address skPkAddr) public {
        return StoremanLib.stakeClaim(data,skPkAddr);
    }

    function delegateIn(address skPkAddr)
        public
        payable
    {
        return StoremanLib.delegateIn(data,skPkAddr);
    }
    function delegateOut(address skPkAddr) public {
        return StoremanLib.delegateOut(data,skPkAddr);

    }

    function delegateClaim(address skPkAddr) public {

        return StoremanLib.delegateClaim(data, skPkAddr);
    }

    function getSelectedSmNumber(bytes32 groupId) public view returns(uint) {
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        if(group.status == StoremanType.GroupStatus.initial || group.status == StoremanType.GroupStatus.failed){
            return 0;
        }
        return group.memberCountDesign;
    }

    event selectedEvent(bytes32 indexed groupId, uint indexed count, address[] members);
    function toSelect(bytes32 groupId) 
        public onlyGroupLeader(groupId)
    {
        return IncentiveLib.toSelect(data, groupId);
    }

    function getSelectedSmInfo(bytes32 groupId, uint index) public view   returns(address, bytes, bytes){
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        address addr = group.selectedNode[index];
        StoremanType.Candidate storage sk = data.candidates[addr];
        return (addr, sk.PK,sk.enodeID);
    }

    // TODO: should we left this?  set dismissed status for some reason.
    function toSetGroupStatus(bytes32 groupId, StoremanType.GroupStatus status) public  onlyOwner {
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        group.status = status;
    }

    // function getSmInfo(bytes32 groupId, address wkAddress) public view  returns(address sender,bytes PK, address pkAddress,
    //     bool quited, uint  delegateFee,uint  deposit, uint delegateDeposit,
    //     uint incentive, uint delegatorCount
    //     ){
    //         StoremanType.StoremanGroup storage group = data.groups[groupId];
    //         StoremanType.Candidate storage sk = data.candidates[wkAddress];

    //         return (sk.sender,   sk.PK, sk.pkAddress, sk.quited,
    //             sk.delegateFee, sk.deposit.getLastValue(), sk.delegateDeposit,
    //             sk.incentive,  sk.delegatorCount 
    //         );
    // }


    function getStoremanInfo(address wkAddress)public view  returns(address sender,bytes PK, address pkAddress,
        bool quited, uint  delegateFee,uint  deposit, uint delegateDeposit,
        uint incentive, uint delegatorCount, bytes32 groupId, bytes32 nextGroupId
        ){
            StoremanType.StoremanGroup storage group = data.groups[groupId];
            StoremanType.Candidate storage sk = data.candidates[wkAddress];

            return (sk.sender,   sk.PK, sk.pkAddress, sk.quited,
                sk.delegateFee, sk.deposit.getLastValue(), sk.delegateDeposit,
                sk.incentive[0],  sk.delegatorCount, sk.groupId, sk.nextGroupId 
            );
    }

    function getSmDelegatorAddr(address wkAddr, uint deIndex) public view  returns (address){
        StoremanType.Candidate storage sk = data.candidates[wkAddr];
        return sk.addrMap[deIndex];
    }
    function getSmDelegatorInfo(address wkAddr, address deAddr) public view returns (address sender, uint deposit, uint incentive) {
        StoremanType.Candidate storage sk = data.candidates[wkAddr];
        StoremanType.Delegator storage de = sk.delegators[deAddr];
        return (de.sender, de.deposit.getLastValue(),  0); // TODO
    }
    function getSmDelegatorInfoRecord(bytes32 groupId, address wkAddr, address deAddr, uint index) public view returns (uint, uint) {
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        StoremanType.Candidate storage sk = data.candidates[wkAddr];
        StoremanType.Delegator storage de = sk.delegators[deAddr];
        return (de.deposit.records[index].id, de.deposit.records[index].value);
    }
    function setGpk(bytes32 groupId, bytes gpk1, bytes gpk2) 
        public onlyGpk {
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        //storemanGroupRegister(group.chain,groupId, gpk1, group.txFeeRatio);
        //emit storemanGroupRegisterEvent(groupId, group.chain, gpk1, gpk2);
    }

    function setInvalidSm(bytes32 groupId, uint[] slashType,  address[] badAddrs) 
        public onlyGpk
        returns(bool isContinue){
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        
        for(uint k=0; k<group.memberCount; k++){
            if(group.tickedCount + group.whiteCount >=group.whiteCountAll){
                return false;
            }
            for(uint i=0; i<badAddrs.length; i++){
                if(group.selectedNode[k] == badAddrs[i]){
                    group.selectedNode[k] = group.whiteMap[group.tickedCount+ group.whiteCount];
                    group.tickedCount += 1;
                    break;
                }
            }
        }
        
        return true;
    }

    function getThresholdByGrpId(bytes32 groupId) external view returns (uint){
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        return group.threshold;
    }


    /// @notice                           function for storeman group apply unregistration through the delegate
    /// @param groupId              storeman group groupId
    function storemanGroupUnregister(bytes32 groupId)
        external
        notHalted
    {
        StoremanType.StoremanGroup storage smg = data.groups[groupId];
        //require(msg.sender == smg.delegate, "Sender must be delegate");
        require(smg.unregisterApplyTime == 0, "Duplicate unregister");

        // TODO: check the status of group.
        smg.unregisterApplyTime = now;
        smg.status = StoremanType.GroupStatus.unregistered;
        //htlc.deactivateStoremanGroup(tokenOrigAccount, storemanGroup);

        emit StoremanGroupUnregisterEvent(groupId);
    }

    /// @notice                           function for storeman group apply unregistration through the delegate
    /// @param tokenOrigAccount           token account of original chain
    /// @param storemanGroup              storeman group PK
    function storemanGroupDismiss(bytes tokenOrigAccount, bytes storemanGroup)
        external
        notHalted
    {
        bytes32 groupId = data.storemanGroupMap[tokenOrigAccount][storemanGroup];
        StoremanType.StoremanGroup storage smg = data.groups[groupId];
        require(smg.unregisterApplyTime != 0, "please unregister first");    

        bool quitable = htlc.storemanGroupCanQuit(storemanGroup);

        require(quitable);

        smg.status = StoremanType.GroupStatus.dismissed;
        emit StoremanGroupDismissedLogger(tokenOrigAccount, storemanGroup, now);
    }



    function getStoremanGroupInfo(bytes32 id)
        external
        view
        returns(bytes32 groupId, StoremanType.GroupStatus status, uint deposit, uint whiteCount,  uint memberCount,  uint startTime, uint endTime)
    {
        StoremanType.StoremanGroup storage smg = data.groups[id];
        return (smg.groupId, smg.status, smg.deposit.getLastValue(), smg.whiteCount, smg.selectedCount,  smg.workDay, smg.workDay+smg.totalDays);
    }

    function getStoremanGroupConfig(bytes32 id)
        external
        view
        returns(bytes32 groupId, uint deposit, uint chain1, uint chain2, uint curve1, uint curve2,  bytes gpk1, bytes gpk2, uint startTime, uint endTime)
    {
        StoremanType.StoremanGroup storage smg = data.groups[id];
        return (smg.groupId, smg.deposit.getLastValue(), smg.chain1, smg.chain2,smg.curve1, smg.curve2,
         smg.gpk1, smg.gpk2, smg.workDay, smg.workDay+smg.totalDays);
    }



    function checkGroupIncentive(bytes32 id, uint day) public view returns ( uint) {
        StoremanType.StoremanGroup storage group = data.groups[id];
        return group.groupIncentive[day];
    }

    function contribute() public payable {
        // TODO add an event.
        return;
    }


    function setCoefficient(uint _crossChainCo, uint _chainTypeCo) public {
        if (_crossChainCo != 0) {
            data.crossChainCo = _crossChainCo;
        }

        if (_chainTypeCo != 0) {
             data.chainTypeCo = _chainTypeCo;
        }
     }

}
