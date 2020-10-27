<template>
  <div class="hello">
    <h2 v-if="loading">loading...</h2>
    <div v-if="!loading">
      <h3>mDai Balance {{ mDaiBalance | tokens }}mDai</h3>
      <h3>Staking Balance {{ stakingBalance | tokens }}mDai</h3>
      <h3>Reward {{ dappTokenBalance | tokens }}DApp</h3>
      <h3>
        <form @submit.prevent="stakeTokens">
          <p>
            <input type="number" v-model="amount">
            mDai
          </p>
          <p>
            <button type="submit">STAKE</button>
          </p>
          <p>
            <button @click="unstakeTokens">UNSTAKE</button>
          </p>
        </form>
      </h3>
    </div>
  </div>
</template>

<script>
import Web3 from "web3";
import mDai from "../../build/contracts/DaiToken.json"
import DAppToken from "../../build/contracts/DappToken.json"
import TokenFarm from "../../build/contracts/TokenFarm.json"

let web3;

export default {
  name: 'HelloWorld',
  data() {
    return {
      account: "",
      mDaiToken: {},
      mDaiBalance: 0,
      dappToken: {},
      dappTokenBalance: 0,
      tokenFarm: {},
      stakingBalance: 0,
      amount: 0,
      loading: true
    }
  },
  filters: {
    tokens(v) {
      return window.web3.utils.fromWei(v, "ether");
    }
  },
  methods: {
    async loadWeb3() {
      if (window.ethereum) {
        window.web3 = new Web3(window.ethereum);
        await window.ethereum.enable();
      }
      else if (window.web3) {
        window.web3 = new Web3(window.web3.currentProvider);
      }
      else {
        window.alert("Non-ethereum browser detected");
      }
    },
    async loadBlockchainData() {
      web3 = window.web3;

      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];

      const networkId = await web3.eth.net.getId();
      // mDaiトークン読み込み
      const mDaiData = mDai.networks[networkId];
      if(mDaiData) {
        const mDaiToken = new web3.eth.Contract(mDai.abi, mDaiData.address);
        this.mDaiToken = mDaiToken;
        this.mDaiBalance = await mDaiToken.methods.balanceOf(this.account).call();
      } else {
        window.alert("mDai contract not deployed to detected network.");
      }
      // DAppトークン読み込み
      const dappTokenData = DAppToken.networks[networkId];
      if(dappTokenData) {
        const dappToken = new web3.eth.Contract(DAppToken.abi, dappTokenData.address);
        this.dappToken = dappToken;
        this.dappTokenBalance = await dappToken.methods.balanceOf(this.account).call();
      } else {
        window.alert("DApp Token contract not deployed to detected network.");
      }
      // TokenFarmトークン読み込み
      const tokenFarmData = TokenFarm.networks[networkId];
      if(tokenFarmData) {
        const tokenFarm = new web3.eth.Contract(TokenFarm.abi, tokenFarmData.address);
        this.tokenFarm = tokenFarm;
        this.stakingBalance = await tokenFarm.methods.stakingBalance(this.account).call();
      } else {
        window.alert("TokenFarm contract not deployed to detected network.");
      }
    },
    async stakeTokens() {
      this.loading = true;
      const amount = window.web3.utils.toWei(this.amount, "ether");
      await this.mDaiToken.methods.approve(this.tokenFarm._address, amount).send({ from: this.account })
      .on("transactionHash", async () => {
        await this.tokenFarm.methods.stakeTokens(amount).send({ from: this.account });
        this.loading = false;
      })
    },
    async unstakeTokens() {
      this.loading = true;
      await this.tokenFarm.methods.unstakeTokens().send({ from: this.account })
      .on("transactionHash", async () => {
        this.loading = false;
      })
    }
  },
  async created() {
    await this.loadWeb3();
    await this.loadBlockchainData();
    this.loading = false;
  }
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h3 {
  margin: 40px 0 0;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
} 
a {
  color: #42b983;
}
</style>
