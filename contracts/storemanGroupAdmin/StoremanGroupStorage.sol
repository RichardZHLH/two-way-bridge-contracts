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

import "../components/BasicStorage.sol";
import "../interfaces/ITokenManager.sol";
import "../interfaces/IMetric.sol";
import "../lib/Deposit.sol";
import "./StoremanType.sol";
import "../interfaces/IQuota.sol";


contract StoremanGroupStorage is BasicStorage {

  /// token manager instance address
  ITokenManager public tokenManager;
  /// HTLC instance address
  IMetric public metric;
  IQuota public quotaInst;



  uint backupCountDefault = 3;
  uint minStake = 50000;
  address[] public badAddrs;
  uint[] public badTypes;
  uint memberCountDefault=4;
  uint thresholdDefault = 3;
  uint standaloneWeightDefault = 1500;
  uint chainTypeCoDefault = 10000;

  address  public  greateGpkAddr;
  // StoremanType.GroupConfig  configDefault = StoremanType.GroupConfig({
  //   memberCountDesign:memberCountDefault,
  //   threshold:thresholdDefault
  // });

  StoremanType.StoremanData data;

  constructor() public {
    data.conf.standaloneWeight = standaloneWeightDefault;
    data.conf.backupCount = backupCountDefault;
    data.conf.chainTypeCoDefault = chainTypeCoDefault;
  }

}
