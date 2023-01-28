/*
 * @Author: daibi dbfornewsletter@outlook.com
 * @Date: 2023-01-23 19:50:51
 * @LastEditors: daibi dbfornewsletter@outlook.com
 * @LastEditTime: 2023-01-23 19:56:46
 * @FilePath: /Avatar_Oracle_Book/test/metadataCalculateTest.js
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
const { deployMockVRFCoordinator, deployDiamond } = require('../scripts/testDeploy.js')

const { assert, expect } = require('chai')
const { ethers } = require('hardhat')

describe ('metadataCalculateTest', async function() {
    
    let mockVRFCoordinator
    let diamondAddress
    let diamondCutFacet
    let diamondLoupeFacet
    let avatarFacet
    let vrfFacet

    // 

    before(async function () {
        mockVRFCoordinator = await deployMockVRFCoordinator()
        diamondAddress = await deployDiamond(mockVRFCoordinator.address)
        diamondCutFacet = await ethers.getContractAt('DiamondCutFacet', diamondAddress)
        diamondLoupeFacet = await ethers.getContractAt('DiamondLoupeFacet', diamondAddress)
        avatarFacet = await ethers.getContractAt('AvatarFacet', diamondAddress)
        vrfFacet = await ethers.getContractAt('VRFFacet', diamondAddress)
    })
})