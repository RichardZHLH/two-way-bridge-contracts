
pragma solidity 0.4.26;
import "../components/Halt.sol";
import "./QuotaStorage.sol";
import "../tokenManager/ITokenManager.sol";
import "../interfaces/IStoremanGroup.sol";
import "../interfaces/IOracle.sol";

interface IDebtOracle {
    function isDebtClean(bytes32 storemanGroupId) external view returns (bool);
}
contract QuotaDelegate is QuotaStorage, Halt {

    function config(
        address _priceOracleAddr,
        address _htlcAddr,
        address _fastHtlcAddr,
        address _depositOracleAddr,
        address _tokenManagerAddress,
        uint _depositRate,
        string _depositTokenSymbol
    ) external onlyOwner {
        priceOracleAddress = _priceOracleAddr;
        htlcGroupMap[_htlcAddr] = true;
        htlcGroupMap[_fastHtlcAddr] = true;
        depositOracleAddress = _depositOracleAddr;
        depositRate = _depositRate;
        depositTokenSymbol = _depositTokenSymbol;
        tokenManagerAddress = _tokenManagerAddress;
    }

    function setDebtOracle(address oracle) external onlyOwner {
        debtOracleAddress = oracle;
    }

    function setFastCrossMinValue(uint value) external onlyOwner {
        fastCrossMinValue = value;
    }

    function userMintLock(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];

        uint mintQuota = getUserMintQuota(tokenId, storemanGroupId);
        require(
            mintQuota >= value,
            "Quota is not enough"
        );

        if (!quota._active) {
            quota._active = true;
            storemanTokensMap[storemanGroupId][storemanTokenCountMap[storemanGroupId]] = tokenId;
            storemanTokenCountMap[storemanGroupId] = storemanTokenCountMap[storemanGroupId]
                .add(1);
        }

        quota.asset_receivable = quota.asset_receivable.add(value);
    }

    function smgMintLock(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];

        if (!quota._active) {
            quota._active = true;
            storemanTokensMap[storemanGroupId][storemanTokenCountMap[storemanGroupId]] = tokenId;
            storemanTokenCountMap[storemanGroupId] = storemanTokenCountMap[storemanGroupId]
                .add(1);
        }

        quota.debt_receivable = quota.debt_receivable.add(value);
    }

    function userMintRevoke(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.asset_receivable = quota.asset_receivable.sub(value);
    }

    function smgMintRevoke(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.debt_receivable = quota.debt_receivable.sub(value);
    }

    function userMintRedeem(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.debt_receivable = quota.debt_receivable.sub(value);
        quota._debt = quota._debt.add(value);
    }

    function smgMintRedeem(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.asset_receivable = quota.asset_receivable.sub(value);
        quota._asset = quota._asset.add(value);
    }

    function userFastMint(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];

        uint mintQuota = getUserMintQuota(tokenId, storemanGroupId);
        require(
            mintQuota >= value,
            "Quota is not enough"
        );

        require(checkFastMinValue(tokenId, value), "Less than minimize value");

        if (!quota._active) {
            quota._active = true;
            storemanTokensMap[storemanGroupId][storemanTokenCountMap[storemanGroupId]] = tokenId;
            storemanTokenCountMap[storemanGroupId] = storemanTokenCountMap[storemanGroupId]
                .add(1);
        }
        quota._asset = quota._asset.add(value);
    }

    function smgFastMint(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];

        if (!quota._active) {
            quota._active = true;
            storemanTokensMap[storemanGroupId][storemanTokenCountMap[storemanGroupId]] = tokenId;
            storemanTokenCountMap[storemanGroupId] = storemanTokenCountMap[storemanGroupId]
                .add(1);
        }
        quota._debt = quota._debt.add(value);
    }

    function userFastBurn(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        require(checkFastMinValue(tokenId, value), "Less than minimize value");

        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        require(quota._debt.sub(quota.debt_payable) >= value, "Value is invalid");
        quota._debt = quota._debt.sub(value);
    }

    function smgFastBurn(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota._asset = quota._asset.sub(value);
    }

    function userBurnLock(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        require(quota._debt.sub(quota.debt_payable) >= value, "Value is invalid");
        quota.debt_payable = quota.debt_payable.add(value);
    }

    function smgBurnLock(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.asset_payable = quota.asset_payable.add(value);
    }

    function userBurnRevoke(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.debt_payable = quota.debt_payable.sub(value);
    }

    function smgBurnRevoke(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota.asset_payable = quota.asset_payable.sub(value);
    }

    function userBurnRedeem(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota._asset = quota._asset.sub(value);
        quota.asset_payable = quota.asset_payable.sub(value);
    }

    function smgBurnRedeem(
        uint tokenId,
        bytes32 storemanGroupId,
        uint value
    ) external onlyHtlc {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        quota._debt = quota._debt.sub(value);
        quota.debt_payable = quota.debt_payable.sub(value);
    }

    function debtLock(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];

        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];

            require( src.debt_receivable == uint(0) && src.debt_payable == uint(0),
                "There are debt_receivable or debt_payable in src storeman"
            );

            if (src._debt == 0) {
                continue;
            }

            Quota storage dst = quotaMap[id][dstStoremanGroupId];
            if (!dst._active) {
                dst._active = true;
                storemanTokensMap[dstStoremanGroupId][storemanTokenCountMap[dstStoremanGroupId]] = id;
                storemanTokenCountMap[dstStoremanGroupId] = storemanTokenCountMap[dstStoremanGroupId]
                    .add(1);
            }

            dst.debt_receivable = dst.debt_receivable.add(src._debt);
            src.debt_payable = src.debt_payable.add(src._debt);
        }
    }

    function debtRedeem(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];
            if (src._debt == 0) {
                continue;
            }
            Quota storage dst = quotaMap[id][dstStoremanGroupId];

            dst.debt_receivable = dst.debt_receivable.sub(src.debt_payable);
            dst._debt = dst._debt.add(src._debt);

            src.debt_payable = 0;
            src._debt = 0;
        }
    }

    function debtRevoke(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];
            if (src._debt == 0) {
                continue;
            }
            Quota storage dst = quotaMap[id][dstStoremanGroupId];

            dst.debt_receivable = dst.debt_receivable.sub(src.debt_payable);
            src.debt_payable = 0;
        }
    }

    function assetLock(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];

            require( src.asset_receivable == uint(0) && src.asset_payable == uint(0),
                "There are asset_receivable or asset_payable in src storeman"
            );

            if (src._asset == 0) {
                continue;
            }

            Quota storage dst = quotaMap[id][dstStoremanGroupId];
            if (!dst._active) {
                dst._active = true;
                storemanTokensMap[dstStoremanGroupId][storemanTokenCountMap[dstStoremanGroupId]] = id;
                storemanTokenCountMap[dstStoremanGroupId] = storemanTokenCountMap[dstStoremanGroupId]
                    .add(1);
            }

            dst.asset_receivable = dst.asset_receivable.add(src._asset);
            src.asset_payable = src.asset_payable.add(src._asset);
        }
    }

    function assetRedeem(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];
            if (src._asset == 0) {
                continue;
            }
            Quota storage dst = quotaMap[id][dstStoremanGroupId];

            dst.asset_receivable = dst.asset_receivable.sub(src.asset_payable);
            dst._asset = dst._asset.add(src._asset);

            src.asset_payable = 0;
            src._asset = 0;
        }
    }

    function assetRevoke(
        bytes32 srcStoremanGroupId,
        bytes32 dstStoremanGroupId
    ) external onlyHtlc {
        uint tokenCount = storemanTokenCountMap[srcStoremanGroupId];
        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[srcStoremanGroupId][i];
            Quota storage src = quotaMap[id][srcStoremanGroupId];
            if (src._asset == 0) {
                continue;
            }
            Quota storage dst = quotaMap[id][dstStoremanGroupId];

            dst.asset_receivable = dst.asset_receivable.sub(src.asset_payable);
            src.asset_payable = 0;
        }
    }

    function getUserMintQuota(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint)
    {
        string memory symbol;
        uint decimals;
        uint tokenPrice;

        (symbol, decimals) = getTokenAncestorInfo(tokenId);
        tokenPrice = getPrice(symbol);
        if (tokenPrice == 0) {
            return 0;
        }

        uint fiatQuota = getUserFiatMintQuota(storemanGroupId, symbol);

        return fiatQuota.div(tokenPrice).mul(10**decimals).div(1 ether);
    }

    function getSmgMintQuota(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint)
    {
        string memory symbol;
        uint decimals;
        uint tokenPrice;

        (symbol, decimals) = getTokenAncestorInfo(tokenId);
        tokenPrice = getPrice(symbol);
        if (tokenPrice == 0) {
            return 0;
        }

        uint fiatQuota = getSmgFiatMintQuota(storemanGroupId, symbol);

        return fiatQuota.div(tokenPrice).mul(10**decimals).div(1 ether);
    }

    function getUserBurnQuota(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint burnQuota)
    {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        burnQuota = quota._debt.sub(quota.debt_payable);
    }

    function getSmgBurnQuota(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint burnQuota)
    {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        burnQuota = quota._asset.sub(quota.asset_payable);
    }

    function getAsset(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint asset, uint asset_receivable, uint asset_payable)
    {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        return (quota._asset, quota.asset_receivable, quota.asset_payable);
    }

    function getDebt(uint tokenId, bytes32 storemanGroupId)
        public
        view
        returns (uint debt, uint debt_receivable, uint debt_payable)
    {
        Quota storage quota = quotaMap[tokenId][storemanGroupId];
        return (quota._debt, quota.debt_receivable, quota.debt_payable);
    }

    function isDebtClean(bytes32 storemanGroupId) external view returns (bool) {
        uint tokenCount = storemanTokenCountMap[storemanGroupId];
        if (tokenCount == 0) {
            if (debtOracleAddress == address(0)) {
                return true;
            } else {
                IDebtOracle debtOracle = IDebtOracle(debtOracleAddress);
                return debtOracle.isDebtClean(storemanGroupId);
            }
        }

        for (uint i = 0; i < tokenCount; i++) {
            uint id = storemanTokensMap[storemanGroupId][i];
            Quota storage src = quotaMap[id][storemanGroupId];
            if (src._debt > 0 || src.debt_payable > 0 || src.debt_receivable > 0) {
                return false;
            }

            if (src._asset > 0 || src.asset_payable > 0 || src.asset_receivable > 0) {
                return false;
            }
        }
        return true;
    }

    function getFastMinCount(uint tokenId) public view returns (uint, string, uint, uint, uint) {
        if (fastCrossMinValue == 0) {
            return (0, "", 0, 0, 0);
        }
        string memory symbol;
        uint decimals;
        (symbol, decimals) = getTokenAncestorInfo(tokenId);
        uint price = getPrice(symbol);
        uint count = fastCrossMinValue.mul(10**decimals).div(price);
        return (fastCrossMinValue, symbol, decimals, price, count);
    }
    function checkFastMinValue(uint tokenId, uint value) private view returns (bool) {
        if (fastCrossMinValue == 0) {
            return true;
        }
        string memory symbol;
        uint decimals;
        (symbol, decimals) = getTokenAncestorInfo(tokenId);
        uint price = getPrice(symbol);
        uint count = fastCrossMinValue.mul(10**decimals).div(price);
        return value >= count;
    }

    function getFiatDeposit(bytes32 storemanGroupId) private view returns (uint) {
        uint deposit = getDepositAmount(storemanGroupId);
        return deposit.mul(getPrice(depositTokenSymbol));
    }

    function getUserFiatMintQuota(bytes32 storemanGroupId, string rawSymbol) private view returns (uint) {
        string memory symbol;
        uint decimals;

        uint totalTokenUsedValue = 0;
        for (uint i = 0; i < storemanTokenCountMap[storemanGroupId]; i++) {
            uint id = storemanTokensMap[storemanGroupId][i];
            (symbol, decimals) = getTokenAncestorInfo(id);
            Quota storage q = quotaMap[id][storemanGroupId];
            uint tokenValue = q.asset_receivable.add(q._asset).mul(getPrice(symbol)).mul(1 ether).div(10**decimals); 
            totalTokenUsedValue = totalTokenUsedValue.add(tokenValue);
        }

        uint depositValue = 0;
        if (keccak256(rawSymbol) == keccak256("WAN")) {
            depositValue = getFiatDeposit(storemanGroupId);
        } else {
            depositValue = getFiatDeposit(storemanGroupId).mul(DENOMINATOR).div(depositRate); 
        }

        if (depositValue <= totalTokenUsedValue) {
            return 0;
        }

        return depositValue.sub(totalTokenUsedValue); 
    }

    function getSmgFiatMintQuota(bytes32 storemanGroupId, string rawSymbol) private view returns (uint) {
        string memory symbol;
        uint decimals;

        uint totalTokenUsedValue = 0;
        for (uint i = 0; i < storemanTokenCountMap[storemanGroupId]; i++) {
            uint id = storemanTokensMap[storemanGroupId][i];
            (symbol, decimals) = getTokenAncestorInfo(id);
            Quota storage q = quotaMap[id][storemanGroupId];
            uint tokenValue = q.debt_receivable.add(q._debt).mul(getPrice(symbol)).mul(1 ether).div(10**decimals); 
            totalTokenUsedValue = totalTokenUsedValue.add(tokenValue);
        }

        uint depositValue = 0;
        if (keccak256(rawSymbol) == keccak256("WAN")) {
            depositValue = getFiatDeposit(storemanGroupId);
        } else {
            depositValue = getFiatDeposit(storemanGroupId).mul(DENOMINATOR).div(depositRate); 
        }

        if (depositValue <= totalTokenUsedValue) {
            return 0;
        }

        return depositValue.sub(totalTokenUsedValue); 
    }

    function getDepositAmount(bytes32 storemanGroupId)
        private
        view
        returns (uint deposit)
    {
        IStoremanGroup smgAdmin = IStoremanGroup(depositOracleAddress);
        (,,deposit,,,,,,,,) = smgAdmin.getStoremanGroupConfig(storemanGroupId);
    }

    function getTokenAncestorInfo(uint tokenId)
        private
        view
        returns (string ancestorSymbol, uint decimals)
    {
        ITokenManager tokenManager = ITokenManager(tokenManagerAddress);
        (,,ancestorSymbol,decimals,) = tokenManager.getAncestorInfo(tokenId);
    }

    function stringToBytes32(string memory source) public pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function getPrice(string symbol) private view returns (uint price) {
        IOracle oracle = IOracle(priceOracleAddress);
        price = oracle.getValue(stringToBytes32(symbol));
    }
}
