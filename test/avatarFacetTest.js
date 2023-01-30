const {
    getSelectors,
    FacetCutAction,
    removeSelectors,
    findAddressPositionInFacets
} = require('../scripts/libraries/diamond.js')

const { deployMockVRFCoordinator, deployDiamond } = require('../scripts/testDeploy.js')

const { assert, expect } = require('chai')
const { ethers } = require('hardhat')

describe ('avatarFacetTest', async function() {

    let mockVRFCoordinator
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let avatarFacet
    let avatarMockFacet
    let libERC721Factory
    let libAvatar
    let vrfFacet

    before(async function () {
        mockVRFCoordinator = await deployMockVRFCoordinator()
        diamondAddress = await deployDiamond(mockVRFCoordinator.address)
        libERC721Factory = await ethers.getContractFactory('LibERC721')
        libAvatar = await ethers.getContractFactory('LibAvatar')
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
        ownershipFacet = await ethers.getContractAt('OwnershipFacet', diamondAddress)
        avatarFacet = await ethers.getContractAt('AvatarFacet', diamondAddress)
        vrfFacet = await ethers.getContractAt('VRFFacet', diamondAddress)
        avatarMockFacet = await ethers.getContractAt('AvatarInitializeFacet', diamondAddress)
    })

    it('should revert when avatar minting to 0x0 address', async () => {      
        await expect(avatarFacet.mint(ethers.constants.AddressZero)).to.be.revertedWith("AvatarFacet: mint to zero address!");
    })

    it('should revert when avatar minting switch is not open', async () => {      
        const [_, addr1] = await ethers.getSigners()
        await expect(avatarFacet.mint(addr1.address)).to.be.revertedWith("AvatarFacet: avatar mint is not started");
    })

    it('should revert when it is not the owner of Contract calling mintSwitch function', async () => {
        const [_, addr1] = await ethers.getSigners()
        await expect(avatarFacet.connect(addr1).mintSwitch()).to.be.revertedWith("LibDiamond: Must be contract owner");
    })

    it('should revert when chainlink is not initialized', async () => {      
        const [_, addr1] = await ethers.getSigners();

        await avatarFacet.mintSwitch()

        await expect(avatarFacet.mint(addr1.address)).to.be.revertedWith("AvatarFacet: chainlink is not initialized");
    })

    it('should exist VRF subscription config', async () => {
        const { s_subscriptionId, vrfCoordinator, keyHash, callbackGasLimit, requestConfirmations, numWords } = await vrfFacet.getVRFSubscriptionConfig()

        assert.equal(s_subscriptionId, 2796, 'subscription id not match')
        assert.equal(vrfCoordinator, mockVRFCoordinator.address, 'vrfCoordinator address not match')
        assert.equal(keyHash, '0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f', 'keyHash not match')
        assert.equal(callbackGasLimit, 100000, 'callbackGasLimit not match')
        assert.equal(requestConfirmations, 3, 'requestConfirmations not match')
        assert.equal(numWords, 1, 'numWords not match')
    })

    it('should revert when querying not exist Avatar', async () => {
        await expect(avatarFacet.getByTokenId(999)).to.be.revertedWith('AvatarFacet: avatar not exist');
    })

    it('should mint successfully after chainlink subscription is open', async () => {
        await vrfFacet.vrfSwitch()

        const [_, addr1] = await ethers.getSigners()

        assert.equal(await avatarFacet.totalNormalAvatar(), 0, 'avatar num not match before mint')

        await expect(avatarFacet.mint(addr1.address))
            .to.emit(libERC721Factory.attach(avatarFacet.address), 'Transfer').withArgs(ethers.constants.AddressZero, addr1.address, 100 + 1)
            .to.emit(mockVRFCoordinator, 'RandomWordsRequested')
        // check the current status of the newly minted normal Avatar
        const {owner, status, avatarType, rank, mintTime} = await avatarFacet.getByTokenId(100 + 1)

        assert.equal(owner, addr1.address, 'owner not match')
        assert.equal(status, 2, 'status not match')
        assert.isTrue(mintTime > 0, 'mint time not match')

        // NOT inited
        assert.equal(avatarType, 0, 'avatar type not match')
        assert.equal(rank, 0, 'rank not match')

        // total num of normal avatar will change
        assert.equal(await avatarFacet.totalNormalAvatar(), 1, 'avatar num not match after mint')

        // balance of addr1 will change
        assert(await avatarFacet.balanceOf(addr1.address), 1, 'avatar balance not match')
    })

    it('should return 0 for balance of a new user', async () => {
        const [_, addr1, addr2] = await ethers.getSigners()
        assert(await avatarFacet.balanceOf(addr2.address), 0, 'avatar balance not match for new user')
    })

    it('should revert when request id is not exist for random number fulfillment', async() => {
        let currentCounter = await mockVRFCoordinator.getCounter()
        
        await expect(mockVRFCoordinator.fulfillRandomWords(currentCounter + 999, diamondAddress))
            .to.be.revertedWith('LibRandomWord: request record not exist!')
    })

    it('should render the Avatar type when random number fulfills', async () => {
        let currentCounter = await mockVRFCoordinator.getCounter()
        
        const [_, addr1] = await ethers.getSigners()
        await expect(mockVRFCoordinator.fulfillRandomWords(currentCounter, diamondAddress))
            .to.emit(libAvatar.attach(vrfFacet.address), 'AvatarRendered').withArgs(addr1.address, 101, currentCounter)
        
        // check the status & feature intialization for current avatar
        const {owner, status, avatarType, rank, mintTime, randomNumber, lastUpdateTime, chronosis, echo, convergence} = await avatarFacet.getByTokenId(100 + 1)

        assert.equal(owner, addr1.address, 'owner not match')
        assert.equal(status, 1, 'status not match')
        assert.isTrue(mintTime > 0, 'mint time not match')
        assert.equal(avatarType, randomNumber % 12 + 1, 'avatar type not match')
        assert.equal(rank, 1, 'rank not match')
        assert.isTrue(lastUpdateTime > 0, 'last update time not match')
        assert.equal(chronosis, 500)
        assert.equal(echo, 500)
        assert.equal(convergence, 500)
    })

    // it('should revert when mint the 1000th Avatar, it may take some time', async () => {
    //     const [_, addr1] = await ethers.getSigners()
    //     for (let i = 1; i <= 1000; i++) {
    //         let currentAvatarNum = await avatarFacet.totalNormalAvatar()
    //         if (currentAvatarNum < 899) {
    //             await avatarFacet.mint(addr1.address)
    //         } else {
    //             await expect(avatarFacet.mint(addr1.address))
    //                 .to.be.revertedWith('AvatarFacet: out of Avatars!')
    //             break
    //         }
    //     }
    // })


})