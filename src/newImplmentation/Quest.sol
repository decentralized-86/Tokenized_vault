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
        uint256 questId;
        string brandName;
        uint256 brandId;
        uint256 entryFee;
        uint256 rewardFee;
        uint256 noOfUsers;
        address questAdmin;
    }

    mapping(uint256 => QuestData[]) ecoSystemQuests;
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) questParticipants;

    mapping(uint256 => uint256) noOfQuest;


    event QuestCreated(uint256 indexed brandId, uint256 indexed questId, address indexed questAdmin, uint256 entryFee, uint256 rewardFee, uint256 noOfUsers);
    event UserJoinedQuest(uint256 indexed ecosystemId, uint256 indexed questId, address indexed user);



    constructor(address __ecosystemContract){
        ecosystemContract =  IEcosystem(_ecosystemContract);

    }

     function createQuest(uint256 _brandId, uint256 _entryFee, uint256 _rewardFee, uint256 _noOfUsers) external {
        (string memory brandName, address brandAddress, , , , , ) = ecosystemContract.getEcosystemDetails(_brandId);
        require(brandAddress != address(0) && msg.sender == brandAddress, "Ecosystem does not exist");

        require(_entryFee > 0, "Entry fee must be greater than zero");
        require(_rewardFee > 0, "Reward fee must be greater than zero");
        require(_noOfUsers > 0, "Number of users must be greater than zero");

        uint256 questId = nextQuestId[_brandId]++;
        QuestData memory newQuest = QuestData({
            questId: questId,
            brandName: brandName,
            brandId: _brandId,
            entryFee: _entryFee,
            rewardFee: _rewardFee,
            noOfUsers: _noOfUsers,
            questAdmin: msg.sender
        });

        ecoSystemQuests[_brandId].push(newQuest);
        emit QuestCreated(_brandId, questId, msg.sender, _entryFee, _rewardFee, _noOfUsers);
    }
     function questParticipation(uint256 _ecosystemId, uint256 _questId) external {
        require(ecosystemContract.isUserPartOfEcosystem(_ecosystemId, msg.sender), "User not part of ecosystem");
        
        QuestData storage quest = ecoSystemQuests[_ecosystemId][_questId];
        require(!quest.participants[msg.sender], "Already joined the quest");
        require(quest.noOfUsers > 0, "Quest user limit reached");

        quest.participants[msg.sender] = true;
        quest.noOfUsers -= 1;

        emit UserJoinedQuest(_ecosystemId, _questId, msg.sender);
    }
    function rewardDistribution(uint256 _ecosystemId, uint256 _questId) external {
    QuestData storage quest = ecoSystemQuests[_ecosystemId][_questId];
    
    require(quest.participants[msg.sender], "Not a participant");
    require(!quest.claimedRewards[msg.sender], "Reward already claimed");
    
    require(questIsCompleted(_ecosystemId, _questId), "Quest not completed");
    
    uint256 rewardAmount = calculateReward(_ecosystemId, _questId, msg.sender);
    
    transferReward(msg.sender, rewardAmount);
    
    quest.claimedRewards[msg.sender] = true;
    
    emit RewardClaimed(_ecosystemId, _questId, msg.sender, rewardAmount);
}
    function CompleteQuestVerification() external {



    }
    function DeleteQuest() external {

        

    }
    function calculateReward(uint256 _ecosystemId, uint256 _questId, address participant) private view returns (uint256) {
    // Implement your reward calculation logic
    // This could be a simple equal split, based on contribution, or any complex logic
    return calculatedReward;
    }

    function questIsCompleted(uint256 _ecosystemId, uint256 _questId) private view returns (bool) {


    // Implement logic to check if the quest is completed
    return true; // Placeholder
    }
    function transferReward(address participant, uint256 rewardAmount) private {

        
    // Implement the logic to transfer rewards
}



}