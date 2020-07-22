pragma solidity ^0.4.24;
import "./StoremanType.sol";
import "../lib/PosLib.sol";
import "../interfaces/IMetric.sol";
import "./StoremanUtil.sol";

library IncentiveLib {
    using Deposit for Deposit.Records;
    

    event incentive(bytes32 indexed groupId, address indexed pkAddr, bool indexed finished);

    function getGroupIncentive(StoremanType.StoremanGroup storage group, uint time,uint crossChainCo,uint chainTypeCo) public view returns (uint)  {
        return PosLib.getMinIncentive(Deposit.getLastValue(group.deposit),time,crossChainCo, chainTypeCo);
        //return 30000000;
    }

    function calIncentive(uint groupIncentive, uint groupWeight, uint weight) public returns (uint) {
        return groupIncentive*weight/groupWeight;
    }

    function incentiveCandidator(StoremanType.StoremanData storage data, address wkAddr,IMetric metric) public  {
        StoremanType.Candidate storage sk = data.candidates[wkAddr];
        StoremanType.StoremanGroup storage group = data.groups[sk.groupId];
        
        uint fromDay = group.workTime;
        if(sk.incentivedDay != 0) {
            fromDay = sk.incentivedDay + 1;
        }
        uint endDay = StoremanUtil.getDaybyTime(now)-1;
        if(endDay > group.workTime+group.totalTime) {
            endDay = group.workTime+group.totalTime;
        }
        
        uint day;
        for(day = fromDay; day < endDay; day++) {

            if(msg.gas < 1000000 ){ // check the gas. because calculate delegator incentive need more gas left.
                emit incentive(group.groupId, wkAddr, false);
                return;
            }
            
            uint idx = 0;
            for(;idx < group.selectedCount;idx++) {
                 address addr = group.selectedNode[idx];
                 if (addr == sk.pkAddress) {
                     break;
                 }
            }
     
            if( group.groupIncentive[day] == 0 && 
                metric.getPrdInctMetric(group.groupId, day, day)[idx] > group.incentiveThresHold){
                
                group.groupIncentive[day] = getGroupIncentive(group, day,data.crossChainCo,data.chainTypeCo); // TODO: change to the correct time
                sk.incentive[day] = calIncentive(group.groupIncentive[day], group.depositWeight.getValueById(day),  StoremanUtil.calSkWeight(data.standaloneWeight,sk.deposit.getValueById(day)));
                sk.incentive[0] +=  sk.incentive[day];
                
                while(sk.incentivedDelegator != sk.delegatorCount) {
                    address deAddr = sk.addrMap[sk.incentivedDelegator];
                    //StoremanType.Delegator storage de = sk.delegators[deAddr];           
                    sk.delegators[deAddr].incentive[day] += calIncentive(group.groupIncentive[day], group.depositWeight.getValueById(day), sk.delegators[deAddr].deposit.getValueById(day));
                    sk.delegators[deAddr].incentive[0] = sk.delegators[deAddr].incentive[day];


                    // StoremanType.Delegator storage de = sk.delegators[deAddr];           
                    // de.incentive[day] += calIncentive(group.groupIncentive[day], group.depositWeight.getValueById(day), de.deposit.getValueById(day));
                    // de.incentive[0] = de.incentive[day];
                    sk.incentivedDelegator++;
                }
            }

            //TODO: recoed the incentived day.
            sk.incentivedDay = day;
        }
        
        
        sk.incentivedDelegator = 0;
        sk.incentivedDay = 0;
        
        emit incentive(group.groupId, wkAddr, true);

            // TODO 所有的sk完成incentive, group状态进入dismissed, sk的当前group变成nextGroup.
        
    }

    event selectedEvent(bytes32 indexed groupId, uint indexed count, address[] members);
    function toSelect(StoremanType.StoremanData storage data,bytes32 groupId) public {
        StoremanType.StoremanGroup storage group = data.groups[groupId];
        if(group.memberCount < group.memberCountDesign){
             group.status = StoremanType.GroupStatus.failed;
            return;
        }
        // first, select the sm from white list.
        // TODO: check all white list should stakein.
        for(uint m = 0; m<group.whiteCount;m++){
            group.selectedNode[m] = group.whiteMap[m];
        }
        address[] memory members = new address[](group.memberCountDesign);
        uint groupDeposit = 0;
        uint groupDepositWeight = 0;
        uint day = group.workTime;
        for(uint i = 0; i<group.memberCountDesign; i++){
            members[i] = group.selectedNode[i];
            StoremanType.Candidate storage sk = data.candidates[group.selectedNode[i]];
            groupDeposit += (sk.deposit.getLastValue()+sk.delegateDeposit);
            groupDepositWeight += (StoremanUtil.calSkWeight(data.standaloneWeight,sk.deposit.getLastValue())+sk.delegateDeposit);
        }
        Deposit.Record memory deposit = Deposit.Record(day, groupDeposit);
        Deposit.Record memory depositWeight = Deposit.Record(day, groupDepositWeight);
        emit selectedEvent(group.groupId, group.memberCountDesign, members);
        group.status = StoremanType.GroupStatus.selected;
        group.deposit.addRecord(deposit);
        group.depositWeight.addRecord(depositWeight);
        return;
    }
 
}