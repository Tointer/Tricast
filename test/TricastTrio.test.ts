import { expect } from "chai";
import { Contract, Wallet } from "ethers";
import { ethers } from "hardhat";
import { deployContract, MockProvider, solidity } from 'ethereum-waffle';
import { decryptJsonWalletSync } from "@ethersproject/json-wallets";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("TricastTrio", function () {

  let oracle: Contract;
  let tricastTrio: Contract;
  let wallet0: SignerWithAddress;
  let wallet1: SignerWithAddress;

  beforeEach(async function () {
    const Oracle = await ethers.getContractFactory("DummyOutcomeProvider");
    oracle = await Oracle.deploy()

    const TricastTrio = await ethers.getContractFactory("TricastTrio");
    tricastTrio = await TricastTrio.deploy(oracle.address);

    const wallets = await ethers.getSigners();
    wallet0 = wallets[0];
    wallet1 = wallets[1];

    (await wallet0.sendTransaction({to: tricastTrio.address, value: 5000})).wait();
    (await wallet1.sendTransaction({to: tricastTrio.address, value: 5000})).wait();

  });

  it("Transfer funds", async () => {
    const transaction = await wallet0.sendTransaction({to: tricastTrio.address, value: 50000});
    transaction.wait();

    const balance = await tricastTrio.callStatic.getBalance(wallet0.address);
    expect(balance).to.equal(55000);
  });

  it("Place limit buy order", async () => {
    await tricastTrio.connect(wallet0).forBuyLimit(20, 30);
    const forOrderCount = await tricastTrio.callStatic.getForOrderCount(30);

    expect(forOrderCount).to.equal(1);


    await tricastTrio.connect(wallet1).againstBuyLimit(20, 30);
    const againstOrderCount = await tricastTrio.callStatic.getAgainstOrderCount(30);

    expect(againstOrderCount).to.equal(1);
  });

  it("Mint two matching for/against limit orders at middle price", async () => {
    await tricastTrio.connect(wallet0).forBuyLimit(10, 50);
    await tricastTrio.connect(wallet1).againstBuyLimit(10, 50);

    const forBalance = await tricastTrio.callStatic.getForBalance(wallet0.address);
    const againstBalance = await tricastTrio.callStatic.getAgainstBalance(wallet0.address);

    const forBalance1 = await tricastTrio.callStatic.getForBalance(wallet1.address);
    const againstBalance1 = await tricastTrio.callStatic.getAgainstBalance(wallet1.address);

    expect(againstBalance).to.equal(0);
    expect(forBalance1).to.equal(0);

    expect(forBalance).to.equal(10);
    expect(againstBalance1).to.equal(10);
  });

});