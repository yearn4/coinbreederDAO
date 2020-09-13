const StakeToken = artifacts.require('StackToken')
const BREE = artifacts.require('Token.sol');
const BREE_STAKE_FARM = artifacts.require('BREE_STAKE_FARM.sol');
const ethers =require("./helpers/ether.js");
require('chai')
    .use(require('chai-as-promised'))
    .should()


contract('BREE', ([deployer, investor1, user1, user2,user3,user4, user5,user6,user7,user8]) => {


    beforeEach(async function () {
        this.token = await BREE.new();
        this.BREE_STAKE_FARM = await BREE_STAKE_FARM.new( this.token.address);
        this.StakeToken = await StakeToken.new(this.token.address, this.BREE_STAKE_FARM.address,investor1);
    });

 
    describe('Token Stacking ', function(){
        beforeEach(async function(){
            await this.token.transfer(user1,ethers.ether(5000));
            await this.token.approve(this.StakeToken.address, ethers.ether(5000),{from:user1});
            await this.StakeToken.stackingPool(ethers.ether(4000),{from:user1});
            var balanceCon = await this.token.balanceOf(this.StakeToken.address);
            console.log("Balance is ", balanceCon.toString());
            // total Stack till today
            var stack = await this.BREE_STAKE_FARM.YourTotalStakesTillToday(this.StakeToken.address);
            console.log("Stack Token ", stack.toString())
             // Stack by user 2
            await this.token.transfer(user2,ethers.ether(4000));
            await this.token.approve(this.StakeToken.address, ethers.ether(4000),{from:user2});
            await this.StakeToken.stackingPool(ethers.ether(4000),{from:user2});
 
            await this.token.transfer(user3,ethers.ether(4000));
            await this.token.approve(this.StakeToken.address, ethers.ether(4000),{from:user3});
            await this.StakeToken.stackingPool(ethers.ether(4000),{from:user3});

            var balanceCon1 = await this.token.balanceOf(this.StakeToken.address);
            console.log("Balance is ", balanceCon1.toString());

           
 
        })
        it("it return stacking Balance ", async function(){
            var stack1 = await this.BREE_STAKE_FARM.YourTotalStakesTillToday(this.StakeToken.address);
            console.log("Stack Token ", stack1.toString())
        })
     it("Unstack token", async function(){
         await this.StakeToken.callUnstake();
        //  console.log()
     })
        // it('Deposite token by Users', async function(){
        //     // Stack by user 1
        //    await this.token.transfer(user1,ethers.ether(5000));
        //    await this.token.approve(this.StakeToken.address, 5000,{from:user1});
        //    await this.StakeToken.stackingPool(4000,{from:user1});
        //    var balanceCon = await this.token.balanceOf(this.StakeToken.address);
        //    console.log("Balance is ", balanceCon.toString());
        //    // total Stack till today
        //    var stack = await this.BREE_STAKE_FARM.YourTotalStakesTillToday(this.StakeToken.address);
        //    console.log("Stack Token ", stack.toString())
        //     // Stack by user 2
        //    await this.token.transfer(user2,4000);
        //    await this.token.approve(this.StakeToken.address, 4000,{from:user2});
        //    await this.StakeToken.stackingPool(4000,{from:user2});

        //    var balanceCon1 = await this.token.balanceOf(this.StakeToken.address);
        //    console.log("Balance is ", balanceCon1.toString());



        // })
    
    })
})