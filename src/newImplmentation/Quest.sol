//SPDX-License-Identifier : MIT
pragma solidity 0.8.15;

interface IEcosystem {
    struct EcosystemData {
        string brandName;
        address brandAddress;
        address assetAddress;
        uint256 entryPrice;
        uint256 noOfUsers;
        uint256 appreciationPercentage;
        uint256 threshold;
    }

    function getEcosystemDetails(uint256 _ecosystemId) external view returns (EcosystemData memory);
}

contract Quest {

    IEcosystem ecosystemContract;

    struct QuestData {
        string brandName;
        uint256 brandId;
        uint256 entryFee;
        uint256 rewardFee;
        uint256 noOfUsers;
        address questAdmin;
    }

    mapping(uint256 => QuestData[]) ecoSystemQuests;


    event QuestCreated(uint256 indexed brandId, address indexed questAdmin, uint256 entryFee, uint256 rewardFee, uint256 noOfUsers);


    constructor(address __ecosystemContract){
        ecosystemContract = __ecosystemContract;

    }

    function createQuest(uint256 _brandId,uint256 _entryFee,uint256 _rewardFee,uint256 _noOfUsers) external {
        (string brandName,address brandAddress,,,) = ecosystemContract.getEcosystemDetails(_brandId);
         require(brandAddress != address(0) && msg.sender == brandAddress, "Ecosystem does not exist");

        require(_entryFee > 0, "Entry fee must be greater than zero");
        require(_rewardFee > 0, "Reward fee must be greater than zero");
        require(_noOfUsers > 0, "Number of users must be greater than zero");

          QuestData memory newQuest = QuestData({
            brandName: brandName,
            brandId: _brandId,
            entryFee: _entryFee,
            rewardFee: _rewardFee,
            noOfUsers: _noOfUsers,
            questAdmin: msg.sender
        });

        ecosystemQuests[_brandId].push(newQuest);

        emit QuestCreated(_brandId, msg.sender, _entryFee, _rewardFee, _noOfUsers);


    }
    function QuestParticipation() external {
        
    }
    function rewardDistribution() external {

    }
    function CompleteQuestVerification() external {

    }
    function DeleteQuest() external {

    }



}