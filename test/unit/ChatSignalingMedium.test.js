const { SHA256, enc } = require("crypto-js");
const { ethers, deployments, getNamedAccounts } = require("hardhat");
const { assert, expect } = require("chai");
const {
  isCallTrace,
} = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

describe("Chat Signaling Medium", async function () {
  //DEPLOYER IS ALWAYS A PARTICIPANT BECAUSE CONTRACT CONSTRUCTOR REGISTERS EMPTY NAME
  let contract, deployer;
  beforeEach(async function () {
    deployer = (await getNamedAccounts()).deployer;

    await deployments.fixture(["all"]);
    //const abi = (await deployments.get("ChatSignalingMedium")).abi;
    contract = await ethers.getContract("ChatSignalingMedium", deployer);
  });
  describe("Unregistered", async function () {
    const testName = "risenow";
    const testNameHash = SHA256(testName);
    const testNameHashStr = "0x" + testNameHash.toString(enc.Hex);
    const testEncryptionKey = testNameHashStr;
    it("Should return detect unregistered address as non-participant", async function () {
      const signers = await ethers.getSigners();
      const user = signers[1].address;

      const isParticipant = await contract.isParticipantAddress(user);
      const tmp = await contract.getParticipantNameHashByAddress(user);

      assert.equal(isParticipant, false);
    });
    it("Should return detect unregistered name as non-participant", async function () {
      const isParticipant = await contract.isParticipantNameHash(
        testNameHashStr
      );
      //const tmp = await contract.getParticipantNameHashByAddress(deployer);
      //console.log(tmp);
      assert.equal(isParticipant, false);
    });
  });
  describe("Registration", async function () {
    const testName = "risenow";
    const testNameHash = SHA256(testName);
    const testNameHashStr = "0x" + testNameHash.toString(enc.Hex);
    const testEncryptionKey = testNameHashStr; // just a <bytes> type placeholder
    console.log(testNameHashStr);
    beforeEach(async function () {
      const resp = await contract.register(testName, testEncryptionKey);
      await resp.wait(1);
    });
    it("Should detect registered address as a participant", async function () {
      const isParticipant = await contract.isParticipantAddress(deployer);

      assert.equal(isParticipant, true);
    });
    it("Should detect registered name as a participant", async function () {
      const isParticipant = await contract.isParticipantNameHash(
        testNameHashStr
      );

      assert.equal(isParticipant, true);
    });
    it("Should not allow to register already taken name", async function () {
      const anotherAccount = (await ethers.getSigners())[1];
      const contractConnectedToAnotherAccount = await contract.connect(
        anotherAccount
      );
      await expect(
        contractConnectedToAnotherAccount.register(testName, testEncryptionKey)
      ).to.be.revertedWithCustomError(
        contract,
        "ChatSignalingMedium__NameAlreadyRegistered"
      );
    });
    it("Should allow to re-register already taken name for its owner, to faciliate encryption key change", async function () {
      const temp = SHA256(testName + "salt");
      const testEncryptionKey2 = "0x" + temp.toString(enc.Hex);

      const resp = await contract.register(testName, testEncryptionKey2);
      await resp.wait(1);

      const actualEncKey = await contract.getEncryptionKeyByAddress(deployer);
      assert.equal(actualEncKey, testEncryptionKey2);
    });
  });
  console.log("Weeep");
  describe("Connection Signaling", async function () {
    const testInitiateRequestToken = "0xaa";
    const testAcceptRequestToken = "0xbb";

    const testName = "risenow";
    const testNameHash = "0x" + SHA256(testName).toString(enc.Hex);
    const testEncryptionKey = testNameHash;

    const testName2 = "juice";
    const testNameHash2 = "0x" + SHA256(testName2).toString(enc.Hex);
    const testEncryptionKey2 =
      "0x" + SHA256(testName + "salt").toString(enc.Hex);

    let nonParticipant;
    let contractConnectedToNonParticipant;
    let participant1;
    let participant2;
    let contractConnectedToParticipant1;
    let contractConnectedToParticipant2;

    beforeEach(async function () {
      const signers = await ethers.getSigners();

      contractConnectedToParticipant1 = contract;
      contractConnectedToParticipant2 = contract.connect(signers[1]);
      contractConnectedToNonParticipant = contract.connect(signers[2]);

      participant1 = signers[0];
      participant2 = signers[1];
      nonParticipant = signers[2];

      let resp = await contractConnectedToParticipant1.register(
        testName,
        testEncryptionKey
      );
      await resp.wait(1);
      resp = await contractConnectedToParticipant2.register(
        testName2,
        testEncryptionKey2
      );
      await resp.wait(1);
    });
    it("Should not allow to initiate and accept connection by non participant", async function () {
      await expect(
        contractConnectedToNonParticipant.initiateConnection(
          testNameHash,
          testInitiateRequestToken
        )
      ).to.be.revertedWithCustomError(
        contract,
        "ChatSignalingMedium__CallerIsNotAParticipant"
      );
      await expect(
        contractConnectedToNonParticipant.acceptConnection(
          testNameHash,
          testAcceptRequestToken
        )
      ).to.be.revertedWithCustomError(
        contract,
        "ChatSignalingMedium__CallerIsNotAParticipant"
      );
    });

    it("Should not allow to initiate and accept connection to non participant", async function () {
      const nonParticipantName = "bee";
      const nonParticipantNameHash =
        "0x" + SHA256(nonParticipantName).toString(enc.Hex);
      await expect(
        contractConnectedToParticipant1.initiateConnection(
          nonParticipantNameHash,
          testInitiateRequestToken
        )
      ).to.be.revertedWithCustomError(
        contract,
        "ChatSignalingMedium__RecipientIsNotAParticipant"
      );
      await expect(
        contractConnectedToParticipant1.acceptConnection(
          nonParticipantNameHash,
          testAcceptRequestToken
        )
      ).to.be.revertedWithCustomError(
        contract,
        "ChatSignalingMedium__RecipientIsNotAParticipant"
      );
    });
    it("Should not allow for participant to initiate and accept connection to himself", async function () {
      await expect(
        contractConnectedToParticipant1.initiateConnection(
          testNameHash,
          testInitiateRequestToken
        )
      ).to.be.revertedWithCustomError(
        contract,
        "ChatSignalingMedium__CannotConnectToItself"
      );
      await expect(
        contractConnectedToParticipant1.acceptConnection(
          testNameHash,
          testAcceptRequestToken
        )
      ).to.be.revertedWithCustomError(
        contract,
        "ChatSignalingMedium__CannotConnectToItself"
      );
    });
    it("Should allow participants to initiate and accept connection", async function () {
      let resp;
      resp = await contractConnectedToParticipant1.initiateConnection(
        testNameHash2,
        testInitiateRequestToken
      );
      resp.wait(1);

      const actualConnRequestToken = await contract.getConnectionRequestToken(
        testNameHash2,
        testNameHash
      );
      const actualConnRequestTokenByAddresses =
        await contract.getConnectionRequestTokenByAddresses(
          participant2.address,
          participant1.address
        );
      assert.equal(actualConnRequestToken, testInitiateRequestToken);
      assert.equal(actualConnRequestTokenByAddresses, testInitiateRequestToken);

      resp = await contractConnectedToParticipant2.acceptConnection(
        testNameHash,
        testAcceptRequestToken
      );
      resp.wait(1);
      const actualConnRequestAnswerToken =
        await contract.getConnectionRequestAnswerToken(
          testNameHash,
          testNameHash2
        );
      const actualConnRequestAnswerTokenByAddresses =
        await contract.getConnectionRequestAnswerTokenByAddresses(
          participant1.address,
          participant2.address
        );
      assert.equal(actualConnRequestAnswerToken, testAcceptRequestToken);
      assert.equal(
        actualConnRequestAnswerTokenByAddresses,
        testAcceptRequestToken
      );
    });
  });
});
