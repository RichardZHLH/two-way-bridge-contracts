/*

  Copyright 2020 Wanchain Foundation.

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
pragma experimental ABIEncoderV2;

import "../lib/SafeMath.sol";
import "../components/Halt.sol";
import "./StoremanGroupStorage.sol";
import "../lib/PosLib.sol";
import "./StoremanLib.sol";
import "./StoremanType.sol";
import "./IncentiveLib.sol";
import "../interfaces/IQuota.sol";
import "../gpk/lib/GpkTypes.sol";


contract StoremanGroupDelegate is StoremanGroupStorage, Halt {
    using SafeMath for uint;
    using Deposit for Deposit.Records;

    event StoremanGroupRegisterStartEvent(bytes32 indexed groupId, bytes32 indexed preGroupId, uint workStart, uint workDuration, uint registerDuration);
    event StoremanGroupDismissedEvent(bytes32 indexed groupId, uint dismissTime);
    event updateGroupChainEvent(bytes32 indexed groupId, uint256 indexed chain1, uint256 indexed chain2, uint256 curve1, uint256 curve2);
    event storemanGroupContributeEvent(address indexed sender, uint indexed value);

    modifier onlyGroupLeader(bytes32 groupId) {
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        require(msg.sender == group.selectedNode[0], "Sender is not allowed");
        _;
    }

    /// @notice                           function for owner set token manager and htlc contract address
    /// @param metricAddr                 metricAddr contract address
    /// @param gpkAddr	                  gpkAddr contract address
    /// @param quotaAddr                  quotaAddr contract address
   function setDependence(address metricAddr, address gpkAddr,address quotaAddr)
        external
        onlyOwner
    {
        require(metricAddr != address(0), "Invalid metricAddr address");
        require(gpkAddr != address(0), "Invalid gpkAddr address");
        require(quotaAddr != address(0), "Invalid quotaAddr address");

        metric = metricAddr;
        createGpkAddr = gpkAddr;
        quotaInst = IQuota(quotaAddr);
    }

    /// @notice                           function for owner to open a storeman group.
    /// @param groupId                    the storeman group index.
    /// @param wkAddrs                    white list work address array.
    /// @param senders                    senders address array of the white list enode.
    /// @param workStartSecond            When the group start to work. the seconds from 1970;
    /// @param workDuration               how many seconds the group will work for
    /// @param registerDuration           how many seconds the duration that allow staking.
    /// @param preGroupId                 the preview group index.
    function storemanGroupRegisterStart(bytes32 groupId,
        uint workStartSecond,uint workDuration, uint registerDuration,  bytes32 preGroupId,  address[] wkAddrs, address[] senders)
        public
        onlyOwner
    {
        require(wkAddrs.length == senders.length, "Invalid white list length");
        if(preGroupId==bytes32(0x00) || wkAddrs.length != 0){
            require(wkAddrs.length >= data.conf.backupCount, "Insufficient white list");
        }

        Deposit.Records memory deposit =  Deposit.Records(0);
        Deposit.Records memory depositWeight =  Deposit.Records(0);

        StoremanType.StoremanGroup storage group = data.groups[groupId];
        require(group.status == StoremanType.GroupStatus.none, "group has existed already");
        group.groupId = groupId;
        group.status = StoremanType.GroupStatus.initial;
        group.deposit = deposit;
        group.depositWeight = depositWeight;
        group.workTime = workStartSecond;
        group.totalTime = workDuration;
        group.memberCountDesign = memberCountDefault;
        group.threshold = thresholdDefault;
        group.registerTime = now;
        group.registerDuration = registerDuration;
        emit StoremanGroupRegisterStartEvent(groupId, preGroupId, workStartSecond, workDuration, registerDuration);
        return StoremanLib.inheritNode(data,group, preGroupId, wkAddrs, senders);
    }

    /// @dev	                    set the group chain and curve.
    /// @param groupId	            the group id
    function updateGroupChain(bytes32 groupId,  uint chain1, uint chain2, uint curve1, uint curve2)
        external
        onlyOwner
    {

        StoremanType.StoremanGroup storage group = data.groups[groupId];
        group.chain1 = chain1;
        group.chain2 = chain2;
        group.curve1 = curve1;
        group.curve2 = curve2;
        group.status = StoremanType.GroupStatus.curveSeted;
        emit updateGroupChainEvent(groupId, chain1, chain2, curve1, curve2);
    }

    /// @dev	                    update the group default parameter.
    /// @param groupId	            the group id
    /// @param memberCountdesign	how many member in the group.
    /// @param threshold	        the minimum signature.
    /// @param minStakeIn	        the minimum stake when stakeIn
    /// @param delegateFee	        how many fee the node receive from delegation.
    function updateGroupConfig(bytes32 groupId, uint memberCountdesign, uint threshold, uint minStakeIn, uint delegateFee)
        external
        onlyOwner
    {
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        group.memberCountDesign = memberCountdesign;
        group.threshold = threshold;
        group.minStakeIn = minStakeIn;
        group.delegateFee = delegateFee;
    }

    function incentiveCandidator( address wkAddr) external   {
        IncentiveLib.incentiveCandidator(data, wkAddr,metric);
    }

    /// @notice                             Staker use this interface to stake wan to SC.
    /// @param groupId                      the storeman group index.
    /// @param PK                           the agent keystore's public key.
    /// @param enodeID                      the agent enodeID, use for p2p network.
    function stakeIn(bytes32 groupId, bytes PK, bytes enodeID)
        external
        notHalted
        payable
    {
        return StoremanLib.stakeIn(data, groupId, PK, enodeID);
    }

    /// @notice                             Staker use this interface to append wan to SC.
    /// @param wkAddr                     the agent keystore's address, which publickey is specified when stakeIn.
    function stakeAppend(address wkAddr)
        external
        notHalted
        payable
    {
        return StoremanLib.stakeAppend(data, wkAddr);
    }

    /// @notice                             Staker use this interface to anounce he will not continue in next group.
    ///  the next group will open in advance of the current group end. so if a node want to quit, it should call stakeOut before the new group open. 
    ///  If the new group has opened, the node in old group can't stake out.
    /// @param wkAddr                     the agent keystore's address, which publickey is specified when stakeIn.
    function stakeOut(address wkAddr) external notHalted {
        return StoremanLib.stakeOut(data, wkAddr);
    }
    function checkCanStakeOut(address wkAddr) external view returns(bool) {
        return StoremanLib.checkCanStakeOut(data, wkAddr);
    }

    function checkCanStakeClaim(address wkAddr) external view returns(bool){
        return StoremanLib.checkCanStakeClaim(data, wkAddr);
    }
    function stakeClaim(address wkAddr) external notHalted {
        return StoremanLib.stakeClaim(data,wkAddr);
    }
    function stakeIncentiveClaim(address wkAddr) external notHalted {
        return StoremanLib.stakeIncentiveClaim(data,wkAddr);
    }

    function delegateIn(address wkAddr)
        external
        notHalted
        payable
    {
        return StoremanLib.delegateIn(data,wkAddr);
    }
    function delegateOut(address wkAddr) external {
        return StoremanLib.delegateOut(data,wkAddr);

    }
    function delegateClaim(address wkAddr) external {

        return StoremanLib.delegateClaim(data, wkAddr);
    }
    function delegateIncentiveClaim(address wkAddr) external {

        return StoremanLib.delegateIncentiveClaim(data, wkAddr);
    }
    function partIn(address wkAddr)
        external
        notHalted
        payable
    {
        return StoremanLib.partIn(data,wkAddr);
    }
    function partOut(address wkAddr) external notHalted{
        return StoremanLib.partOut(data,wkAddr);

    }
    function partClaim(address wkAddr) external notHalted{
        return StoremanLib.partClaim(data,wkAddr);
    }

    function getSelectedSmNumber(bytes32 groupId) public view returns(uint) {
        return StoremanUtil.getSelectedSmNumber(data, groupId);
    }
    function getSelectedStoreman(bytes32 groupId) public view returns(address[]) {
        return StoremanUtil.getSelectedStoreman(data, groupId);
    }
    function select(bytes32 groupId)
        external
        notHalted
    {
        return IncentiveLib.toSelect(data, groupId);
    }

    function getSelectedSmInfo(bytes32 groupId, uint index) public view   returns(address wkAddr, bytes PK, bytes enodeId){
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        address addr = group.selectedNode[index];
        StoremanType.Candidate storage sk = data.candidates[addr];
        return (addr, sk.PK,sk.enodeID);
    }

    // To change  group status for unexpected reason.
    function updateGroupStatus(bytes32 groupId, StoremanType.GroupStatus status) external  onlyOwner {
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        group.status = status;
    }

    // //
    // function getStoremanInfo(address wkAddr) external view  returns(address sender,bytes PK, address wkAddr,
    //     bool quited, uint  deposit, uint delegateDeposit,
    //     uint incentive, uint delegatorCount, bytes32 groupId, bytes32 nextGroupId, uint incentivedDay, uint slashedCount
    //     ){
    //         StoremanType.Candidate storage sk = data.candidates[wkAddr];

    //         return (sk.sender,   sk.PK, sk.wkAddr, sk.quited,
    //             sk.deposit.getLastValue(), sk.delegateDeposit,
    //             sk.incentive[0],  sk.delegatorCount, sk.groupId, sk.nextGroupId, sk.incentivedDay, sk.slashedCount
    //         );
    // }

    function getStoremanIncentive(address wkAddr, uint day) public view returns(uint incentive) {
        StoremanType.Candidate storage sk = data.candidates[wkAddr];
        return sk.incentive[day];
    }

    function getSmDelegatorInfoIncentive(address wkAddr, address deAddr, uint day) public view returns ( uint) {
        StoremanType.Candidate storage sk = data.candidates[wkAddr];
        StoremanType.Delegator storage de = sk.delegators[deAddr];
        return (de.incentive[day]);
    }

    function getSmDelegatorInfo(address wkAddr, address deAddr) public view returns (address sender, uint deposit, uint incentive) {
        StoremanType.Candidate storage sk = data.candidates[wkAddr];
        StoremanType.Delegator storage de = sk.delegators[deAddr];
        return (de.sender, de.deposit.getLastValue(),  de.incentive[0]);
    }

    function setGpk(bytes32 groupId, bytes gpk1, bytes gpk2)
        public
    {
        require(msg.sender == createGpkAddr, "Sender is not allowed");
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        group.gpk1 = gpk1;
        group.gpk2 = gpk2;
        group.status = StoremanType.GroupStatus.ready;
    }


    function setInvalidSm(bytes32 groupId, GpkTypes.SlashType[] slashType,  address[] badAddrs)
        public
        returns(bool isContinue)
    {
        require(msg.sender == createGpkAddr, "Sender is not allowed");
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        if(group.status != StoremanType.GroupStatus.selected) {
            return false;
        }
        for(uint k = 0; k < group.selectedCount; k++){
            if(group.tickedCount + group.whiteCount >= group.whiteCountAll){
                group.status == StoremanType.GroupStatus.failed;
                return false;
            }
            for(uint i = 0; i<badAddrs.length; i++){
                if(group.selectedNode[k] == badAddrs[i]){
                    group.tickedNode[group.tickedCount] = group.selectedNode[k];
                    group.selectedNode[k] = group.whiteMap[group.tickedCount + group.whiteCount];
                    group.tickedCount += 1;
                    if(slashType[i] == GpkTypes.SlashType.SijInvalid || slashType[i] == GpkTypes.SlashType.CheckInvalid) {
                        recordSmSlash(badAddrs[i]);
                    }
                    break;
                }
            }
        }
        return true;
    }

    function recordSmSlash(address wk) 
        public
    {
        require((msg.sender == metric) || (msg.sender == createGpkAddr), "Sender is not allowed");
        StoremanType.Candidate storage sk = data.candidates[wk];
        sk.slashedCount++;
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
        onlyGroupLeader(groupId)
    {
        return StoremanLib.storemanGroupUnregister(data, groupId);
    }

    /// @notice                           function for storeman group apply unregistration through the delegate
    /// @param groupId                    storeman groupId
    function storemanGroupDismiss(bytes32 groupId)
        external
        notHalted
        onlyGroupLeader(groupId)
    {
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        bool quitable = quotaInst.isDebtClean(groupId);
        require(quitable, "can not dismiss");

        group.status = StoremanType.GroupStatus.dismissed;
        emit StoremanGroupDismissedEvent(groupId, now);
        // group状态进入dismissed, 并且完成了收益结算, sk的当前group变成nextGroup.
        StoremanType.Candidate storage sk;
        for(uint i=0; i<group.memberCount; i++){
            sk = data.candidates[group.selectedNode[i]];
            if(sk.incentivedDay+1 == StoremanUtil.getDaybyTime(group.workTime+group.totalTime)) {
                if(bytes32(0x00) != sk.nextGroupId) {
                    sk.groupId = sk.nextGroupId;
                    sk.nextGroupId = bytes32(0x00);
                }
            }
        }
    }

    function checkGroupDismissable(bytes32 groupId) public returns(bool) {
        bool dismissable = quotaInst.isDebtClean(groupId);
        return dismissable;
    }

    function getStoremanInfo(address wkAddr) external view returns(StoremanType.StoremanInfo si){
        StoremanType.Candidate storage sk = data.candidates[wkAddr];

        si.sender = sk.sender;
        si.enodeID = sk.enodeID;
        si.PK = sk.PK;
        si.wkAddr = sk.wkAddr;
        si.isWhite = sk.isWhite;
        si.quited = sk.quited;
        si.delegatorCount = sk.delegatorCount;
        si.delegateDeposit = sk.delegateDeposit;
        si.partnerCount = sk.partnerCount;
        si.partnerDeposit = sk.partnerDeposit;
        si.crossIncoming = sk.crossIncoming;
        si.slashedCount = sk.slashedCount;
        si.incentivedDelegator = sk.incentivedDelegator;
        si.incentivedDay = sk.incentivedDay;
        si.groupId = sk.groupId;
        si.nextGroupId = sk.nextGroupId;
        si.deposit = sk.deposit.getLastValue();
    }
    function getStoremanGroupInfo(bytes32 id) public view returns(StoremanType.StoremanGroupInfo info){
        StoremanType.StoremanGroup storage smg = data.groups[id];
        info.groupId = smg.groupId;
        info.status = smg.status;
        info.deposit = smg.deposit.getLastValue();
        info.depositWeight = smg.depositWeight.getLastValue();
        info.selectedCount = smg.selectedCount;
        info.memberCount = smg.memberCount;
        info.whiteCount = smg.whiteCount;
        info.whiteCountAll = smg.whiteCountAll;
        info.startTime = smg.workTime;
        info.endTime = smg.workTime+smg.totalTime;
        info.registerTime = smg.registerTime;
        info.registerDuration = smg.registerDuration;
        info.memberCountDesign = smg.memberCountDesign;
        info.threshold = smg.threshold;
        info.chain1 = smg.chain1;
        info.chain2 = smg.chain2;
        info.curve1 = smg.curve1;
        info.curve2 = smg.curve2;
        info.tickedCount = smg.tickedCount;
        info.minStakeIn = smg.minStakeIn;
        info.crossIncoming = smg.crossIncoming;
        info.gpk1 = smg.gpk1;
        info.gpk2 = smg.gpk2;
        info.delegateFee = smg.delegateFee;
    }
    // function getStoremanGroupInfo(bytes32 id)
    //     external
    //     view
    //     returns(bytes32 groupId, StoremanType.GroupStatus status, uint deposit, uint whiteCount,  uint memberCount,  uint startTime, uint endTime)
    // {
    //     StoremanType.StoremanGroup storage smg = data.groups[id];
    //     return (smg.groupId, smg.status, smg.deposit.getLastValue(), smg.whiteCount, smg.selectedCount,  smg.workTime, smg.workTime+smg.totalTime);
    // }

    function getStoremanGroupConfig(bytes32 id)
        external
        view
        returns(bytes32 groupId, StoremanType.GroupStatus status, uint deposit, uint chain1, uint chain2, uint curve1, uint curve2,  bytes gpk1, bytes gpk2, uint startTime, uint endTime, uint delegateFee)
    {
        StoremanType.StoremanGroup storage smg = data.groups[id];
        return (smg.groupId, smg.status,smg.deposit.getLastValue(), smg.chain1, smg.chain2,smg.curve1, smg.curve2,
         smg.gpk1, smg.gpk2, smg.workTime, smg.workTime+smg.totalTime, smg.delegateFee);
    }
    function getStoremanGroupTime(bytes32 id)
        external
        view
        returns(bytes32 groupId,  uint registerTime, uint registerDuration,  uint startTime, uint endTime)
    {
        StoremanType.StoremanGroup storage smg = data.groups[id];
        return (smg.groupId, smg.registerTime, smg.registerDuration, smg.workTime, smg.workTime+smg.totalTime);
    }


    function checkGroupIncentive(bytes32 id, uint day) public view returns ( uint) {
        StoremanType.StoremanGroup storage group = data.groups[id];
        return group.groupIncentive[day];
    }

    function contribute() public payable {
        emit storemanGroupContributeEvent(msg.sender, msg.value);
        data.contribution = data.contribution.add(msg.value);
        return;
    }

    function smgTransfer(bytes32 smgID) external payable{
        StoremanType.StoremanGroup storage group = data.groups[smgID];
        group.crossIncoming =  group.crossIncoming.add(msg.value);
        uint i;
        StoremanType.Candidate storage sk;
        for(i=0; i<group.selectedCount; i++) {
            sk = data.candidates[group.selectedNode[i]];
            sk.crossIncoming = sk.crossIncoming.add(msg.value.div(group.selectedCount));
        }
    }

    function setChainTypeCo(uint chain1, uint chain2, uint co) public  onlyOwner {
        if(chain1 < chain2) {
            data.chainTypeCo[chain1][chain2] = co;
        } else {
            data.chainTypeCo[chain2][chain1] = co;
        }
    }
    function getChainTypeCo(uint chain1, uint chain2) public view returns (uint co) {
        return IncentiveLib.getChainTypeCo(data, chain1, chain2);
    }

    function getStoremanConf() public view returns(uint backupCount, uint standaloneWeight, uint delegationMulti) {
        return (data.conf.backupCount, data.conf.standaloneWeight, data.conf.DelegationMulti);
    }
    function updateStoremanConf(uint backupCount, uint standaloneWeight, uint DelegationMulti) public onlyOwner {
        data.conf.backupCount = backupCount;
        data.conf.standaloneWeight = standaloneWeight;
        data.conf.DelegationMulti = DelegationMulti;
    }
    function getGlobalIncentive() public view returns(uint contribution, uint totalReward) {
        return (data.contribution, data.totalReward);
    }
}
