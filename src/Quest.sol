// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract QuestContract {

     TokenizedVault public immutable tokenizedVault; 

    struct Quest {
        uint256 questId;
        string description;
        uint256 entryFee; 
        uint256 rewardAmount; 
        uint256 maxParticipants;
        uint256 currentParticipants;
        uint256 questEnds; 
        bool isActive;
    }

    struct Participant {
        address userAddress;
        uint256 amountStaked; 
        bool status; 
    }

    event questCreated(uint256 indexed questId ,uint256 rewardAmount , uint256 indexed maxParticipants );
    event participationSuccessful(uint256 indexed questId ,address indexed participant);
    event RewardsDistributed(uint256 _questId);
    event QuestCompleted(uint256 indexed questId);

    Quest[] public quests;
    mapping(uint256 => Participant[]) public questParticipants;

    constructor(address _tokenizedvault){
        tokenizedVault = TokenizedVault(_tokenizedVault);
    }

    function CreateQuest(
        string memory _description,
        uint256 _entryFee,
        uint256 _rewardAmount,
        uint256 _maxParticipants,
        uint256 _questEnds
    ) external {
        Quest memory newQuest = Quest({
            questId: quests.length,
            description: _description,
            entryFee: _entryFee,
            rewardAmount: _rewardAmount,
            maxParticipants: _maxParticipants,
            currentParticipants: 0,
            questEnds: _questEnds,
            isActive: true
        });

        quests.push(newQuest);

        emit questCreated(newQuest.questId, newQuest.rewardAmount, newQuest.maxParticipants);
    }

    function participateInQuest(uint256 _questId) external  payable {
         Quest storage quest = quests[_questId];

        require(quest.isActive, "Quest is not active");
        require(quest.currentParticipants < quest.maxParticipants, "Quest is full");
        require(block.timestamp < quest.questEnds, "Quest has ended");

        require(tokenizedVault.balanceOf(msg.sender) >= quest.entryFee ,  "Insufficient gTokens");

        tokenizedVault.transferFrom(msg.sender, address(this), quest.entryFee);


        Participant memory newParticipant = Participant({
            userAddress: msg.sender,
            amountStaked: quest.entryFee,
            status: true
        });

        questParticipants[_questId].push(newParticipant);
        emit participationSuccessful(_questId, msg.sender);

        
    }
    function rewardDistribution(uint256 _questId) external {
        Quest storage quest = quests[_questId];

        require(quest.isActive, "Quest is not active");
        require(block.timestamp >= quest.questEnds, "Quest has not ended yet");
        uint256 rewardPerParticipant = quest.rewardAmount / quest.currentParticipants;

         Participant[] storage participants = questParticipants[_questId];

        for (uint256 i = 0; i < participants.length; i++) {
        if(participants[i].status) {
            tokenizedVault.transfer(participants[i].userAddress, rewardPerParticipant);
        }
    }
        quest.isActive = false;
        emit RewardsDistributed(uint256 indexed questId);
    }

   function completeQuest(uint256 _questId) external {
    Quest storage quest = quests[_questId];

    require(quest.isActive, "Quest is already completed");

    require(block.timestamp >= quest.questEnds, "Quest is still ongoing");

    quest.isActive = false;

    Participant[] storage participants = questParticipants[_questId];
    for (uint256 i = 0; i < participants.length; i++) {
        if (participants[i].userAddress == msg.sender) {
            participants[i].status = true;

            uint256 rewardPerParticipant = quest.rewardAmount / quest.currentParticipants;
            tokenizedVault.transfer(msg.sender, rewardPerParticipant);

            break;
        }
    }
    emit QuestCompleted(_questId);
}

}
