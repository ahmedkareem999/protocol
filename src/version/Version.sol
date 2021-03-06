pragma solidity ^0.4.17;

import '../Fund.sol';
import '../FundInterface.sol';
import '../dependencies/DBC.sol';
import '../dependencies/Owned.sol';
import './VersionInterface.sol';

/// @title Version Contract
/// @author Melonport AG <team@melonport.com>
/// @notice Simple and static Management Fee.
contract Version is DBC, Owned {

    // FIELDS

    // Constant fields
    bytes32 public constant TERMS_AND_CONDITIONS = 0x47173285a8d7341e5e972fc677286384f802f8ef42a5ec5f03bbfa254cb01fad; // Hashed terms and conditions as displayed on IPFS.
    // Constructor fields
    string public VERSION_NUMBER; // SemVer of Melon protocol version
    address public MELON_ASSET; // Address of Melon asset contract
    address public GOVERNANCE; // Address of Melon protocol governance contract
    // Methods fields
    bool public isShutDown; // Governance feature, if yes than setupFund gets blocked and shutDownFund gets opened
    mapping (address => address) public managerToFunds; // Links manager address to fund addresses created using this version
    address[] public listOfFunds; // A complete list of fund addresses created using this version
    mapping (string => bool) fundNameExists; // Links fund names to boolean based on existence
    // EVENTS

    event FundUpdated(uint id);

    // PRE, POST, INVARIANT CONDITIONS

    /// @dev Proofs that terms and conditions have been read and understood
    /// @param v ellipitc curve parameter v
    /// @param r ellipitc curve parameter r
    /// @param s ellipitc curve parameter s
    /// @return signed Whether or not terms and conditions have been read and understood
    function termsAndConditionsAreSigned(uint8 v, bytes32 r, bytes32 s) internal returns (bool signed) {
        return ecrecover(
            // Parity does prepend \x19Ethereum Signed Message:\n{len(message)} before signing.
            //  Signature order has also been changed in 1.6.7 and upcoming 1.7.x,
            //  it will return rsv (same as geth; where v is [27, 28]).
            // Note that if you are using ecrecover, v will be either "00" or "01".
            //  As a result, in order to use this value, you will have to parse it to an
            //  integer and then add 27. This will result in either a 27 or a 28.
            //  https://github.com/ethereum/wiki/wiki/JavaScript-API#web3ethsign
            sha3("\x19Ethereum Signed Message:\n32", TERMS_AND_CONDITIONS),
            v,
            r,
            s
        ) == msg.sender; // Has sender signed TERMS_AND_CONDITIONS
    }

    // CONSTANT METHODS

    function getMelonAsset() constant returns (address) { return MELON_ASSET; }
    function notShutDown() internal returns (bool) { return !isShutDown; }
    function getFundById(uint withId) constant returns (address) { return listOfFunds[withId]; }
    function getLastFundId() constant returns (uint) { return listOfFunds.length -1; }
    function getFundByManager(address ofManager) constant returns (address) { return managerToFunds[ofManager]; }
    function fundNameTaken(string withName) constant returns (bool) { return fundNameExists[withName]; }

    // NON-CONSTANT METHODS

    /// @param versionNumber SemVer of Melon protocol version
    /// @param ofGovernance Address of Melon governance contract
    /// @param ofMelonAsset Address of Melon asset contract
    function Version(
        string versionNumber,
        address ofGovernance,
        address ofMelonAsset
    ) {
        VERSION_NUMBER = versionNumber;
        GOVERNANCE = ofGovernance;
        MELON_ASSET = ofMelonAsset;
    }

    function shutDown() external pre_cond(msg.sender == GOVERNANCE) { isShutDown = true; }

    /// @param withName human-readable descriptive name (not necessarily unique)
    /// @param ofReferenceAsset Asset against which performance reward is measured against
    /// @param ofManagementRewardRate A time based reward, given in a number which is divided by 10 ** 15
    /// @param ofPerformanceRewardRate A time performance based reward, performance relative to ofReferenceAsset, given in a number which is divided by 10 ** 15
    /// @param ofParticipation Address of participation module
    /// @param ofRiskMgmt Address of risk management module
    /// @param ofSphere Address of sphere, which contains address of data feed module
    /// @param v ellipitc curve parameter v
    /// @param r ellipitc curve parameter r
    /// @param s ellipitc curve parameter s
    /// @return Deployed Fund with manager set as msg.sender
    function setupFund(
        string withName,
        address ofReferenceAsset,
        uint ofManagementRewardRate,
        uint ofPerformanceRewardRate,
        address ofParticipation,
        address ofRiskMgmt,
        address ofSphere,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        pre_cond(termsAndConditionsAreSigned(v, r, s))
        pre_cond(notShutDown())
        pre_cond(!fundNameExists[withName])
    {
        address fund = new Fund(
            msg.sender,
            withName,
            ofReferenceAsset,
            ofManagementRewardRate,
            ofPerformanceRewardRate,
            MELON_ASSET,
            ofParticipation,
            ofRiskMgmt,
            ofSphere
        );
        listOfFunds.push(fund);
        fundNameExists[withName] = true;
        managerToFunds[msg.sender] = fund;
        FundUpdated(getLastFundId());
    }

    /// @dev Dereference Fund and trigger selfdestruct
    function shutDownFund(uint id)
        pre_cond(isShutDown)
    {
        FundInterface Fund = FundInterface(getFundById(id));
        Fund.shutDown();
        FundUpdated(id);
    }
}
