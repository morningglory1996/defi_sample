const DappToken = artifacts.require("DappToken");
const DaiToken = artifacts.require("DaiToken");
const TokenFarm = artifacts.require("TokenFarm");

const { expect, assert } = require("chai");


contract("TokenFarm", async (accounts) => {
  [owner, investor] = accounts;
  let daiToken, dappToken, tokenFarm;

  function tokens(n) {
    return web3.utils.toWei(n, "ether")
  }

  before(async () => {
    // コントラクト読み込み
    daiToken = await DaiToken.new();
    dappToken = await DappToken.new();
    tokenFarm = await TokenFarm.new(dappToken.address, daiToken.address);
    // DApp tokenをtokenFarmへ全額送金
    await dappToken.transfer(tokenFarm.address, tokens("1000000"));
    //mDaiをinvestorへ送金
    await daiToken.transfer(investor, tokens("100"));
  })

  describe("Mock Dai deployment", async () => {
    it("has a name", async () => {
      const name = await daiToken.name();
      expect(name).to.be.equal("Mock DAI Token");
    })
  })

  describe("DApp Token deployment", async () => {
    it("has a name", async () => {
      const name = await dappToken.name();
      expect(name).to.be.equal("DApp Token");
    })
  })

  describe("Token Farm deployment", async () => {
    it("has a name", async () => {
      const name = await tokenFarm.name();
      expect(name).to.be.equal("Dapp Token Farm");
    })

    it("contract has tokens", async () => {
      let balance = await dappToken.balanceOf(tokenFarm.address);
      expect(balance.toString()).to.be.equal(tokens("1000000"));
    })
  })

  describe("Farming Tokens", async () => {
    it("rewards investors for staking mDai tokens", async () => {
      let result;
      // investorの残高チェック
      result = await daiToken.balanceOf(investor);
      expect(result.toString()).to.be.equal(tokens("100"));
      // mDaiをstake
      await daiToken.approve(tokenFarm.address, tokens("100"), { from: investor });
      await tokenFarm.stakeTokens(tokens("100"), { from: investor });
      // investorの残高チェック
      result = await daiToken.balanceOf(investor);
      expect(result.toString()).to.be.equal(tokens("0"));
      // tokenFarmのmDai残高チェック
      result = await daiToken.balanceOf(tokenFarm.address);
      expect(result.toString()).to.be.equal(tokens("100"));
      // investorのstakingBalanceをチェック
      result = await tokenFarm.stakingBalance(investor);
      expect(result.toString()).to.be.equal(tokens("100"));
      // investorのstaking statusをチェック
      result = await tokenFarm.isStaking(investor);
      expect(result.toString()).to.be.equal('true');
      // stakersにDAppを配布
      await tokenFarm.issueTokens({ from: owner });
      // stakersのDApp残高を確認
      result = await dappToken.balanceOf(investor);
      expect(result.toString()).to.be.equal(tokens("100"));
      // ownerのみがissue token可能かチェック
      try {
        await tokenFarm.issueTokens({ from: investor });
        assert(true);
      } catch (error) {
        return;
      }
      assert(false, "The Contract did not throw.");
      // unstake tokes
      await tokenFarm.unstakeTokens({ from: investor });
      // unstake後の残高チェック
      result = await daiToken.balanceOf(investor);
      expect(result.toString()).to.be.equal(tokens("100"));
      result = await daiToken.balanceOf(tokenFarm.address);
      expect(result.toString()).to.be.equal(tokens("0"));
      result = await tokenFarm.stakingBalance(investor);
      expect(result.toString()).to.be.equal(tokens("0"));
      result = await tokenFarm.isStaking(investor);
      expect(result.toString()).to.be.equal(tokens("false"));
    })
  })
})

