pragma solidity ^0.4.11;

import "ds-test/test.sol";
import "../datafeeds/DataFeed.sol";
import "../system/Governance.sol";
import "../participation/Participation.sol";
import "../assets/PreminedAsset.sol";
import "../riskmgmt/RiskMgmt.sol";
import "../exchange/thirdparty/SimpleMarket.sol";
import "../sphere/Sphere.sol";
import "../Fund.sol";
import "./Version.sol";


contract VersionTest is DSTest {
    DataFeed datafeed;
    Governance governance;
    Participation participation;
    PreminedAsset melonToken;
    RiskMgmt riskMgmt;
    SimpleMarket simpleMarket;
    Sphere sphere;
    Version version;

    // constants
    string FUND_NAME = "My Fund";
    string VERSION_NUMBER = "1.2.3";
    uint INTERVAL = 0;
    uint VALIDITY = 60;
    uint MELON_DECIMALS = 18;
    uint PREMINED_AMOUNT = 10 ** 28;
    uint MANAGEMENT_REWARD = 0;
    uint PERFORMANCE_REWARD = 0;
    address MANAGER_ADDRESS = this;
    string MELON_NAME = "Melon Token";
    string MELON_SYMBOL = "MLN-T";
    string MELON_URL = "https://www.melonport.com";
    bytes32 MOCK_IPFS_HASH = 0x86b5eed81db5f691c36cc83eb58cb5205bd2090bf3763a19f0c5bf2f074dd84b;
    bytes32 MOCK_CHAIN_ID = 0xd8344c361317e3736173f8da91dec3ca1de32f3cc0a895fd6363fbc20fd21985;
    address MOCK_BREAK_IN = 0x2186C5EaAf6CbF55BF1b9cD8130D8a6A71E4486a;
    address MOCK_BREAK_OUT = 0xd9AE70149D256D4645c03aB9D5423A1B70d8804d;


//TODO: uncomment these tests when ds-test issue is resolved:
//      https://github.com/dapphub/ds-test/issues/6
    function setUp() {
        governance = new Governance();
        melonToken = new PreminedAsset(MELON_NAME, MELON_SYMBOL, MELON_DECIMALS, PREMINED_AMOUNT);
        version = new Version(VERSION_NUMBER, governance, melonToken);
        datafeed = new DataFeed(melonToken, MELON_NAME, MELON_SYMBOL, MELON_DECIMALS, MELON_URL, MOCK_IPFS_HASH, MOCK_CHAIN_ID, MOCK_BREAK_IN, MOCK_BREAK_OUT, INTERVAL, VALIDITY);
        riskMgmt = new RiskMgmt();
        simpleMarket = new SimpleMarket();
        sphere = new Sphere(datafeed, simpleMarket);
        participation = new Participation();
    }

    function testSetupFund() {
        version.setupFund(
            FUND_NAME,
            melonToken,
            MANAGEMENT_REWARD,
            PERFORMANCE_REWARD,
            participation,
            riskMgmt,
            sphere
        );
        uint fundId = version.getLastFundId();
        address fundAddressFromManager = version.getFundByManager(MANAGER_ADDRESS);
        address fundAddressFromId = version.getFundById(fundId);

        assertEq(fundAddressFromId, fundAddressFromManager);
        assertEq(fundId, 0);
    }

    function testShutdownFund() {
        version.setupFund(
            FUND_NAME,
            melonToken,
            MANAGEMENT_REWARD,
            PERFORMANCE_REWARD,
            participation,
            riskMgmt,
            sphere
        );
        uint fundId = version.getLastFundId();
        address fundAddress = version.getFundById(fundId);
        Fund fund = Fund(fundAddress);
        version.shutDownFund(fundId);
        bool fundIsShutDown = fund.isShutDown();

        assert(fundIsShutDown);
    }
}
