/* global ethers */
/* eslint prefer-const: "off" */

const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')
require("dotenv").config()

async function deployChianlinkOutsideFacet () {

    const { DIAMOND_ADDRESS, ACCU_WEATHER_API_KEY } = process.env;

    console.log('diamondAddress: ', DIAMOND_ADDRESS, 'apiKey: ', ACCU_WEATHER_API_KEY)

    const diamondCut = await ethers.getContractAt('IDiamondCut', DIAMOND_ADDRESS)

    // upgrade diamond with Chainlink outside API Facet
    const ChainlinkOutsideAPIFacet = await ethers.getContractFactory('ChainlinkAPIFacet')
    const chainlinkOutsideAPIFacet = await ChainlinkOutsideAPIFacet.deploy()
    await chainlinkOutsideAPIFacet.deployed()

    // deploy the init contract for chainlink outside API plugin
    const ChainlinkOutsideAPIInit = await ethers.getContractFactory('ChainlinkOutsideAPIInit')
    const chainlinkOutsideAPIInit = await ChainlinkOutsideAPIInit.deploy()
    await chainlinkOutsideAPIInit.deployed()

    // get selectors from chainlink outside API facet
    const selectors = getSelectors(chainlinkOutsideAPIFacet)
    let chainlinkInitData = chainlinkOutsideAPIInit.interface.encodeFunctionData('init', [DIAMOND_ADDRESS, ACCU_WEATHER_API_KEY])

    tx = await diamondCut.diamondCut(
        [{
          facetAddress: chainlinkOutsideAPIFacet.address,
          action: FacetCutAction.Add,
          functionSelectors: selectors
        }],
        chainlinkOutsideAPIInit.address, chainlinkInitData, { gasLimit: 18800000 })

    let receipt = await tx.wait()
    if (!receipt.status) {
        throw Error(`Diamond upgrade failed: ${tx.hash}`)
    }
    console.log('Completed chainlink outside API facet')
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
    deployChianlinkOutsideFacet()
      .then(() => process.exit(0))
      .catch(error => {
        console.error(error)
        process.exit(1)
      })
  }
  
  exports.deployChianlinkOutsideFacet = deployChianlinkOutsideFacet