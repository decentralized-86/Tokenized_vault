// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./mixins/ERC4626.sol";

contract TokenizedVault is ERC4626 {


    ERC20 public immutable asset;

    constructor(address _underlyingAsset) ERC4626(_underlyingAsset ,"GToken","GRT") {}

    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
    shares = convertToShares(assets);
    asset.safeTransferFrom(msg.sender, address(this), assets);
    _mint(receiver, shares);
    emit Deposit(msg.sender, receiver, assets, shares);
}
    function mint(uint256 shares, address receiver) public override returns (uint256 assets) {
    assets = previewMint(shares);
    asset.safeTransferFrom(msg.sender, address(this), assets);
    _mint(receiver, shares);
    emit Deposit(msg.sender, receiver, assets, shares);
}
    function withdraw(uint256 assets, address receiver) public override returns (uint256 shares) {
    shares = previewWithdraw(assets);
    if (msg.sender != receiver) {
        uint256 allowed = allowance[receiver][msg.sender];
        require(allowed >= shares, "Insufficient allowance");
        if (allowed != type(uint256).max) allowance[receiver][msg.sender] = allowed - shares;
    }
    beforeWithdraw(assets, shares);

    _burn(receiver, shares);

    emit Withdraw(msg.sender, receiver, receiver, assets, shares);

    asset.safeTransfer(receiver, assets);
}

function redeem(uint256 shares, address receiver) public  override returns (uint256 assets) {
    assets = previewRedeem(shares);
    if (msg.sender != receiver) {
        uint256 allowed = allowance[receiver][msg.sender];
        require(allowed >= shares, "Insufficient allowance");
        if (allowed != type(uint256).max) allowance[receiver][msg.sender] = allowed - shares;
    }
    beforeWithdraw(assets, shares);
    _burn(receiver, shares);
    emit Withdraw(msg.sender, receiver, receiver, assets, shares);
    asset.safeTransfer(receiver, assets);
}
function convertToShares(uint256 assets) public view override returns (uint256 shares) {
    uint256 totalShares = totalSupply(); 
    uint256 totalAssetsInVault = totalAssets(); 
    if (totalShares == 0) {
        shares = assets;
    } else {
        shares = (assets * totalShares) / totalAssetsInVault;
    }
    return shares;
}

function convertToAssets(uint256 shares) public view override returns (uint256 assets) {
    uint256 totalShares = totalSupply(); 
    uint256 totalAssetsInVault = totalAssets();

    if (totalShares == 0) {
        assets = shares;
    } else {
        assets = (shares * totalAssetsInVault) / totalShares;
    }

    return assets;
}

function totalAssets() external view override returns(uint256){
    return asset.balanceOf(address(this));
}
function previewMint(uint256 assets) public view returns (uint256 shares) {
        shares = convertToShares(assets);
        return shares;
    }

    function previewWithdraw(uint256 assets) public view returns (uint256 shares) {
        shares = convertToShares(assets);
        //fees or other considerations, should be applied here 
        return shares;
    }

    function previewRedeem(uint256 shares) public view returns (uint256 assets) {
        assets = convertToAssets(shares);
        // If there are fees or other considerations, here 
        return assets;
    }

}
