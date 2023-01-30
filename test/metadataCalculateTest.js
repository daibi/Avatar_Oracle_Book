const { deployMockVRFCoordinator, deployDiamond } = require('../scripts/testDeploy.js')

const { assert, expect } = require('chai')
const { ethers } = require('hardhat')

describe ('metadataCalculateTest', async function() {
    
    let mockVRFCoordinator
    let diamondAddress
    let avatarFacet
    let vrfFacet
    let avatarInitializeFacet;


    before(async function () {
        mockVRFCoordinator = await deployMockVRFCoordinator()
        diamondAddress = await deployDiamond(mockVRFCoordinator.address)
        avatarFacet = await ethers.getContractAt('AvatarFacet', diamondAddress)
        vrfFacet = await ethers.getContractAt('VRFFacet', diamondAddress)
        avatarInitializeFacet = await ethers.getContractAt('AvatarInitializeFacet', diamondAddress)

        // open mint switch
        await avatarFacet.mintSwitch()
        await vrfFacet.vrfSwitch()
    })

    it('all properties are initialized with value 500, EGG level, elapsed time less than 23 minutes, no properties reach their threshold', async() => {
        const [_, addr1] = await ethers.getSigners()
        
        // 22 minutes ago, chronosis will hit its threshold first
        const minuteElapsed = 22
        const lastUpdate = Math.round(new Date().getTime() / 1000) - minuteElapsed * 60 

        // snapshot values
        const chronosisSnapshot = 500;
        const echoSnapshot = 500;
        const convergenceSnapshot = 500;

        // mock avatar
        await avatarInitializeFacet.mockAvatar(addr1.address, chronosisSnapshot, echoSnapshot, convergenceSnapshot, lastUpdate, 1, 1)
        
        // query this avatar's updated properties with decaying effect
        const {owner, status, avatarType, rank, mintTime, randomNumber, lastUpdateTime, chronosis, echo, convergence} = await avatarFacet.getByTokenId(100 + 1)
        // no property reaches its threshold, decaying in a constant rate
        // chronosis's current decay rate
        let chronosisDecayRate = 20;
        chronosisDecayRate = affectByEcho(chronosisDecayRate, echoSnapshot, 500)
        chronosisDecayRate = affectByConvergence(chronosisDecayRate, convergenceSnapshot, 500)

        // echo's decay rate
        const echoDecayRate = echoCorrelateDecayRate(chronosisDecayRate)
        // convergence's decay rate
        const convergenceDecayRate = convergenceCorrelateDecayRate(chronosisDecayRate);

        assert.equal(chronosis, Math.floor(chronosisSnapshot - minuteElapsed * chronosisDecayRate))
        assert.equal(echo, Math.floor(echoSnapshot - minuteElapsed * echoDecayRate))
        assert.equal(convergence, Math.floor(convergenceSnapshot - minuteElapsed * convergenceDecayRate))
    })

    it('all properties are initialized with value 500, EGG level, elapsed time equals to 23 minutes, echo & convergence reach its threshold', async() => {
        const [_, addr1] = await ethers.getSigners()
        
        // 23 minutes ago, echo & convergence will hit their threshold first
        const minuteElapsed = 23
        const lastUpdate = Math.round(new Date().getTime() / 1000) - minuteElapsed * 60 

        // snapshot values
        const chronosisSnapshot = 500;
        const echoSnapshot = 500;
        const convergenceSnapshot = 500;

        // mock avatar
        await avatarInitializeFacet.mockAvatar(addr1.address, chronosisSnapshot, echoSnapshot, convergenceSnapshot, lastUpdate, 1, 1)
        
        // query this avatar's updated properties with decaying effect
        const {owner, status, avatarType, rank, mintTime, randomNumber, lastUpdateTime, chronosis, echo, convergence} = await avatarFacet.getByTokenId(100 + 2)
        // no property reaches its threshold, decaying in a constant rate
        // chronosis's current decay rate
        let chronosisDecayRate = 20;
        chronosisDecayRate = affectByEcho(chronosisDecayRate, echoSnapshot, 500)
        chronosisDecayRate = affectByConvergence(chronosisDecayRate, convergenceSnapshot, 500)

        // echo's decay rate
        const echoDecayRate = echoCorrelateDecayRate(chronosisDecayRate)
        // convergence's decay rate
        const convergenceDecayRate = convergenceCorrelateDecayRate(chronosisDecayRate);

        assert.equal(chronosis, Math.floor(chronosisSnapshot - minuteElapsed * chronosisDecayRate))
        assert.equal(echo, Math.floor(echoSnapshot - minuteElapsed * echoDecayRate))
        assert.equal(convergence, Math.floor(convergenceSnapshot - minuteElapsed * convergenceDecayRate))
    })

    it('all properties are initialized with value 500, EGG level, elapsed time is greater than 23 minutes, echo & convergence reach its threshold first, then chronosis', async() => {
        const [_, addr1] = await ethers.getSigners()
        
        // 26 minutes ago, chronosis will hit its threshold first
        const minuteElapsed = 26
        const lastUpdate = Math.round(new Date().getTime() / 1000) - minuteElapsed * 60 

        // snapshot values
        let chronosisSnapshot = 500;
        let echoSnapshot = 500;
        let convergenceSnapshot = 500;

        // mock avatar
        await avatarInitializeFacet.mockAvatar(addr1.address, chronosisSnapshot, echoSnapshot, convergenceSnapshot, lastUpdate, 1, 1)
        
        // query this avatar's updated properties with decaying effect
        const {owner, status, avatarType, rank, mintTime, randomNumber, lastUpdateTime, chronosis, echo, convergence} = await avatarFacet.getByTokenId(100 + 3)
        // no property reaches its threshold, decaying in a constant rate
        // chronosis's current decay rate
        const originalChronosisDecayRate = 20;
        const originalChronosisExponentialDecayRate = 20;
        let chronosisDecayRate = originalChronosisDecayRate;
        chronosisDecayRate = affectByEcho(chronosisDecayRate, echoSnapshot, 500)
        chronosisDecayRate = affectByConvergence(chronosisDecayRate, convergenceSnapshot, 500)

        // echo's decay rate
        let echoDecayRate = echoCorrelateDecayRate(chronosisDecayRate)
        // convergence's decay rate
        let convergenceDecayRate = convergenceCorrelateDecayRate(chronosisDecayRate)

        // 1. all snapshots decay for 23 minutes - to reach echo & convergence's threshold
        chronosisSnapshot = Math.floor(chronosisSnapshot - 23 * chronosisDecayRate)
        echoSnapshot = Math.floor(echoSnapshot - 23 * echoDecayRate)
        convergenceSnapshot = Math.floor(convergenceSnapshot - 23 * convergenceDecayRate)
        console.log('current snapshot 0: ', chronosisSnapshot, echoSnapshot, convergenceSnapshot)

        // 2. update chronsis, echo, convergence's decay rate
        chronosisDecayRate = originalChronosisDecayRate
        chronosisDecayRate = affectByEcho(chronosisDecayRate, echoSnapshot, 500)
        chronosisDecayRate = affectByConvergence(chronosisDecayRate, convergenceSnapshot, 500)
        echoDecayRate = echoCorrelateDecayRate(chronosisDecayRate)
        convergenceDecayRate = convergenceCorrelateDecayRate(chronosisDecayRate)
        console.log('current decay rate 0: ', chronosisDecayRate, echoDecayRate, convergenceDecayRate)

        // 3. since the original chronosis decay rate is slower than current rate, chronosis should also reach the threshold at 24th minute
        chronosisSnapshot = Math.floor(chronosisSnapshot - 1 * chronosisDecayRate)
        echoSnapshot = Math.floor(echoSnapshot - 1 * echoDecayRate)
        convergenceSnapshot = Math.floor(convergenceSnapshot - 1 * convergenceDecayRate)
        console.log('current snapshot 1: ', chronosisSnapshot, echoSnapshot, convergenceSnapshot)

        // 4. now chronosis's decay rate becomes exponential, but will not reach echo & convergence's next threshold.
        // Let's do another two minute's exponential decay
        chronosisDecayRate = originalChronosisExponentialDecayRate
        chronosisDecayRate = affectByEcho(chronosisDecayRate, echoSnapshot, 500)
        chronosisDecayRate = affectByConvergence(chronosisDecayRate, convergenceSnapshot, 500)
        echoDecayRate = echoCorrelateDecayRate(chronosisDecayRate)
        convergenceDecayRate = convergenceCorrelateDecayRate(chronosisDecayRate)
        console.log('current decay rate 1: ', chronosisDecayRate, echoDecayRate, convergenceDecayRate)

        chronosisSnapshot = Math.floor(chronosisSnapshot - 2 * 2 * chronosisDecayRate)
        echoSnapshot = Math.floor(echoSnapshot - 2 * 2 * echoDecayRate)
        convergenceSnapshot = Math.floor(convergenceSnapshot - 2 * 2 * convergenceDecayRate)
        console.log('current snapshot 2: ', chronosisSnapshot, echoSnapshot, convergenceSnapshot)

        assert.equal(chronosis, Math.floor(chronosisSnapshot))
        assert.equal(echo, Math.floor(echoSnapshot))
        assert.equal(convergence, Math.floor(convergenceSnapshot))
    })
    
    it('all properties are initialized with value 500, EGG level, elapsed time is greater than 27 minutes, echo & convergence reach its threshold first, then chronosis', async() => {
        const [_, addr1] = await ethers.getSigners()
        
        // 29 minutes ago, echo & convergence will reach 0 finally
        const minuteElapsed = 29
        const lastUpdate = Math.round(new Date().getTime() / 1000) - minuteElapsed * 60 

        // snapshot values
        let chronosisSnapshot = 500;
        let echoSnapshot = 500;
        let convergenceSnapshot = 500;

        // mock avatar
        await avatarInitializeFacet.mockAvatar(addr1.address, chronosisSnapshot, echoSnapshot, convergenceSnapshot, lastUpdate, 1, 1)
        
        // query this avatar's updated properties with decaying effect
        const {owner, status, avatarType, rank, mintTime, randomNumber, lastUpdateTime, chronosis, echo, convergence} = await avatarFacet.getByTokenId(100 + 4)
        // no property reaches its threshold, decaying in a constant rate
        // chronosis's current decay rate
        const originalChronosisDecayRate = 20;
        const originalChronosisExponentialDecayRate = 20;
        let chronosisDecayRate = originalChronosisDecayRate;
        chronosisDecayRate = affectByEcho(chronosisDecayRate, echoSnapshot, 500)
        chronosisDecayRate = affectByConvergence(chronosisDecayRate, convergenceSnapshot, 500)

        // echo's decay rate
        let echoDecayRate = echoCorrelateDecayRate(chronosisDecayRate)
        // convergence's decay rate
        let convergenceDecayRate = convergenceCorrelateDecayRate(chronosisDecayRate)

        // 1. all snapshots decay for 23 minutes - to reach echo & convergence's threshold
        chronosisSnapshot = Math.floor(chronosisSnapshot - 23 * chronosisDecayRate)
        echoSnapshot = Math.floor(echoSnapshot - 23 * echoDecayRate)
        convergenceSnapshot = Math.floor(convergenceSnapshot - 23 * convergenceDecayRate)
        console.log('current snapshot 0: ', chronosisSnapshot, echoSnapshot, convergenceSnapshot)

        // 2. update chronsis, echo, convergence's decay rate
        chronosisDecayRate = originalChronosisDecayRate
        chronosisDecayRate = affectByEcho(chronosisDecayRate, echoSnapshot, 500)
        chronosisDecayRate = affectByConvergence(chronosisDecayRate, convergenceSnapshot, 500)
        echoDecayRate = echoCorrelateDecayRate(chronosisDecayRate)
        convergenceDecayRate = convergenceCorrelateDecayRate(chronosisDecayRate)
        console.log('current decay rate 0: ', chronosisDecayRate, echoDecayRate, convergenceDecayRate)

        // 3. since the original chronosis decay rate is slower than current rate, chronosis should also reach the threshold at 24th minute
        chronosisSnapshot = Math.floor(chronosisSnapshot - 1 * chronosisDecayRate)
        echoSnapshot = Math.floor(echoSnapshot - 1 * echoDecayRate)
        convergenceSnapshot = Math.floor(convergenceSnapshot - 1 * convergenceDecayRate)
        console.log('current snapshot 1: ', chronosisSnapshot, echoSnapshot, convergenceSnapshot)

        // 4. now chronosis's decay rate becomes exponential, and will reach echo & convergence's threshold in three minutes
        chronosisDecayRate = originalChronosisExponentialDecayRate
        chronosisDecayRate = affectByEcho(chronosisDecayRate, echoSnapshot, 500)
        chronosisDecayRate = affectByConvergence(chronosisDecayRate, convergenceSnapshot, 500)
        echoDecayRate = echoCorrelateDecayRate(chronosisDecayRate)
        convergenceDecayRate = convergenceCorrelateDecayRate(chronosisDecayRate)
        console.log('current decay rate 1: ', chronosisDecayRate, echoDecayRate, convergenceDecayRate)

        chronosisSnapshot = Math.floor(chronosisSnapshot - 3 * 3 * chronosisDecayRate)
        echoSnapshot = Math.floor(echoSnapshot - 3 * 3 * echoDecayRate)
        convergenceSnapshot = Math.floor(convergenceSnapshot - 3 * 3 * convergenceDecayRate)
        console.log('current snapshot 2: ', chronosisSnapshot, echoSnapshot, convergenceSnapshot)

        // 5. the convergence & echo's value will worsen chronosis's decay rate
        chronosisDecayRate = originalChronosisExponentialDecayRate
        chronosisDecayRate = affectByEcho(chronosisDecayRate, echoSnapshot, 500)
        chronosisDecayRate = affectByConvergence(chronosisDecayRate, echoSnapshot, 500)
        echoDecayRate = echoCorrelateDecayRate(chronosisDecayRate)
        convergenceDecayRate = convergenceCorrelateDecayRate(chronosisDecayRate)
        console.log('current decay rate 2: ', chronosisDecayRate, echoDecayRate, convergenceDecayRate)

        // 6. will take another 1 minute for chronosis's reaching 0, and the loop ends
        chronosisSnapshot = Math.max(chronosisSnapshot - 1 * 1 * chronosisDecayRate, 0)
        echoSnapshot = echoSnapshot - 1 * 1 * echoDecayRate
        convergenceSnapshot = convergenceSnapshot - 1 * 1 * convergenceDecayRate
        console.log('current snapshot 3: ', chronosisSnapshot, echoSnapshot, convergenceSnapshot)

        assert.equal(chronosis, Math.floor(chronosisSnapshot))
        assert.equal(echo, Math.floor(echoSnapshot))
        assert.equal(convergence, Math.floor(convergenceSnapshot))
    })
})

const affectByEcho = (baseChronosisDecayRate, echoValue, maxValue) => {
    if (echoValue >= maxValue * 2 / 5 && echoValue <= maxValue * 3 / 5) {
        // not affecting chronosis time decay
        return baseChronosisDecayRate;
    } else if (echoValue > maxValue * 3 / 5) {
        return baseChronosisDecayRate * 4 / 5
    } 
    return baseChronosisDecayRate * 6 / 5
}

const affectByConvergence = (baseChronosisDecayRate, convergence, maxValue) => {
    if (convergence >= maxValue * 2 / 5 && convergence <= maxValue * 3 / 5) {
        // not affecting chronosis time decay
        return baseChronosisDecayRate;
    } else if (convergence > maxValue * 3 / 5) {
        return baseChronosisDecayRate * 4 / 5
    } 
    return baseChronosisDecayRate * 6 / 5
}

const echoCorrelateDecayRate = (chronosisDecayRate) => {
    return chronosisDecayRate * 0.7
}

const convergenceCorrelateDecayRate = (chronosisDecayRate) => {
    return chronosisDecayRate * 0.7
}