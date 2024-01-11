//SPDX-License-Identifier:MIT
pragma solidity 0.8.15;

interface IEscrow {
    function deposit(address tokenAddress, uint256 brandId, uint256 amount) external;
}

import "./WrappedToken.sol"

contract Ecosystem is  {
    struct EcosystemData {
        string brandName;
        address brandAddress;
        address assetAddress;
        address wrappedToken;
        uint256 entryPrice;
        uint256 noOfUsers;
        uint256 appreciationPercentage;
        uint256 threshold;
    }

    mapping(uint256 => EcosystemData) private ecosystems;
    mapping(uint256 => mapping(address => bool)) userParticipation;
    mapping(address => uint256) userBalances;
    uint256 private ecosystemCount;
    address private immutable escrowAddress;

     modifier onlyBrand(uint256 _ecosystemId) {
        require(msg.sender == ecosystems[_ecosystemId].brandAddress, "Not authorized");
        _;
    }

    event EcosystemCreated(uint256 indexed brandId, address indexed brandAddress, uint256 entryPrice, uint256 noOfUsers, uint256 threshold);
    event UserEnteredEcosystem(uint256 indexed ecosystemId, address indexed user, uint256 amount);

    constructor(address _escrowAddress) {
        escrowAddress = _escrowAddress;
    }


    function createEcosystem(
        string memory _brandName, 
        address _brandAddress, 
        address _assetAddress,
        uint256 _entryPrice, 
        uint256 _noOfUsers, 
        uint256 _appreciationPercentage, 
        uint256 _threshold
    ) external {
         uint256 appreciationAmountPerUser = _entryPrice * _appreciationPercentage / 100;
         uint256 totalAppreciationAmount = appreciationAmountPerUser * _noOfUsers;

        IEscrow asset = IEscrow(escrowAddress);
        require(asset.deposit(_brandAddress ,ecosystemCount , totalAppreciationAmount ), "Transfer to escrow failed");

        GToken wrappedToken = new GToken(_brandName, "SymbolForToken");
        wrappedToken.transferOwnership(_brandAddress);


        ecosystems[ecosystemCount] = EcosystemData(
            _brandName, 
            _brandAddress,
            _assetAddress, 
             address(wrappedToken),
            _entryPrice, 
            _noOfUsers, 
            _appreciationPercentage, 
            _threshold
        );
        emit EcosystemCreated(ecosystemCount, _brandAddress, _entryPrice, _noOfUsers, _threshold);
        ecosystemCount++;
        
    }
     function updateEcosystem(
        uint256 _ecosystemId,
        string memory _brandName, 
        uint256 _newNoOfUsers, 
        uint256 _entryPrice, 
        uint256 _appreciationPercentage, 
        uint256 _threshold
    ) external onlyBrand(_ecosystemId) {
        EcosystemData storage ecosystem = ecosystems[_ecosystemId];

         require(_newNoOfUsers >= ecosystem.noOfUsers, "Cannot reduce user count");

        uint256 additionalUsers = _newNoOfUsers - ecosystem.noOfUsers;
        uint256 additionalAppreciationAmountPerUser = _entryPrice * _appreciationPercentage / 100;
        uint256 totalAdditionalAppreciationAmount = additionalAppreciationAmountPerUser * additionalUsers;

        if (totalAdditionalAppreciationAmount > 0) {
            IEscrow asset = IEscrow(escrowAddress);
            require(asset.deposit(ecosystem.brandAddress ,_ecosystemId , totalAdditionalAppreciationAmount ), "Transfer to escrow failed");
        }


        ecosystem.brandName = _brandName;
        ecosystem.entryPrice = _entryPrice;
        ecosystem.noOfUsers = _noOfUsers;
        ecosystem.appreciationPercentage = _appreciationPercentage;
        ecosystem.threshold = _threshold;
    }
    function enterEcosystem(uint256 _ecosystemId) external {
            EcosystemData storage ecosystem = ecosystems[ecosystemId];
            require(ecosystem.brandAddress != address(0), "Ecosystem does not exist");
            require(!userParticipation[ecosystemId][msg.sender], "User already part of the ecosystem");

             IERC20 token = IERC20(ecosystem.assetAddress);
            require(token.transferFrom(msg.sender, address(this), ecosystem.entryPrice), "Token transfer failed");   //asset token is being transferred actually from the user to the contract okay 

            userParticipation[ecosystemId][msg.sender] = true;
            userDeposits[msg.sender] += ecosystem.entryPrice;

            //Calculate the Amount of Gtoken to be minted actually 
            uint256 appreciationAmountPerUser = ecosystem.entryPrice * ecosystem.appreciationPercentage / 100;
            IEscrow escrow = IEscrow(escrowAddress);
            escrow.transferToEcosystem(ecosystem.assetAddress, _ecosystemId, appreciationAmountPerUser);
            uint256 totalGTokenAmount = ecosystem.entryPrice + appreciationAmountPerUser;
            
            GToken gToken = GToken(ecosystem.wrappedToken);
            gToken.mint(msg.sender, totalGTokenAmount);

            emit UserEnteredEcosystem(ecosystemId, msg.sender, ecosystem.entryPrice);
    }

    function withdraw(uint256 _ecosystemId, uint256 _amount) external {
    EcosystemData storage ecosystem = ecosystems[_ecosystemId];
    require(userParticipation[_ecosystemId][msg.sender], "User not part of the ecosystem");
    require(_amount >= ecosystem.threshold, "Amount below threshold");

    GToken gToken = GToken(ecosystem.wrappedToken);
    require(gToken.balanceOf(msg.sender) >= _amount, "Insufficient GToken balance");
    
    gToken.burnFrom(msg.sender, _amount);

    uint256 assetAmount = calculateAssetAmount(_amount, ecosystem);

    IEscrow escrow = IEscrow(escrowAddress);
    escrow.transferAssets(ecosystem.assetAddress, _ecosystemId, assetAmount, msg.sender);

    emit UserWithdrawn(_ecosystemId, msg.sender, assetAmount);
}

function calculateAssetAmount(uint256 _gTokenAmount, EcosystemData storage ecosystem) private view returns (uint256) {
}


     function getEcosystemDetails(uint256 _ecosystemId) external view returns (EcosystemData memory) {
        return ecosystems[_ecosystemId];
    }

     function listEcosystems() external view returns (uint256[] memory) {
        uint256[] memory ids = new uint256[](ecosystemCount);
        for (uint256 i = 0; i < ecosystemCount; i++) {
            ids[i] = i;
        }
        return ids;
     }
     function isUserPartOfEcosystem(uint256 _ecosystemId, address _user) external view returns (bool) {
    return userParticipation[_ecosystemId][_user];
}

}