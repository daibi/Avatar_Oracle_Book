/* global ethers */
/* eslint prefer-const: "off" */

const { ethers } = require('hardhat')
const { getSelectors, FacetCutAction } = require('./libraries/diamond.js')

async function deployDiamond (vrfCoordinatorAddress) {
  const accounts = await ethers.getSigners()
  const contractOwner = accounts[0]

  // deploy DiamondCutFacet
  const DiamondCutFacet = await ethers.getContractFactory('DiamondCutFacet')
  const diamondCutFacet = await DiamondCutFacet.deploy()
  await diamondCutFacet.deployed()
  console.log('DiamondCutFacet deployed:', diamondCutFacet.address)

  // deploy Diamond
  const Diamond = await ethers.getContractFactory('Diamond')
  const diamond = await Diamond.deploy(contractOwner.address, diamondCutFacet.address)
  await diamond.deployed()
  console.log('Diamond deployed:', diamond.address)

  // deploy DiamondInit
  // DiamondInit provides a function that is called when the diamond is upgraded to initialize state variables
  // Read about how the diamondCut function works here: https://eips.ethereum.org/EIPS/eip-2535#addingreplacingremoving-functions
  const DiamondInit = await ethers.getContractFactory('DiamondInit')
  const diamondInit = await DiamondInit.deploy()
  await diamondInit.deployed()
  console.log('DiamondInit deployed:', diamondInit.address)

  // deploy facets
  console.log('')
  console.log('Deploying facets')
  const FacetNames = [
    'DiamondLoupeFacet',
    'OwnershipFacet',
  ]
  const cut = []
  for (const FacetName of FacetNames) {
    const Facet = await ethers.getContractFactory(FacetName)
    const facet = await Facet.deploy()
    await facet.deployed()
    console.log(`${FacetName} deployed: ${facet.address}`)
    cut.push({
      facetAddress: facet.address,
      action: FacetCutAction.Add,
      functionSelectors: getSelectors(facet)
    })
  }

  const diamondCut = await ethers.getContractAt('IDiamondCut', diamond.address)
  let tx
  let receipt
  // call to init function
  let functionCall = diamondInit.interface.encodeFunctionData('init')
  console.log('function call:', functionCall)
  tx = await diamondCut.diamondCut(cut, diamondInit.address, functionCall)
  console.log('Diamond cut tx: ', tx.hash)
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed diamond cut')

  // upgrade diamond with Avatar Facet
  const AvatarFacet = await ethers.getContractFactory('AvatarFacet')
  const avatarFacet = await AvatarFacet.deploy()

  await avatarFacet.deployed()

  // deploy the init contract for avatarFacet plugin
  const AvatarFacetInit = await ethers.getContractFactory('AvatarFacetInit')
  const avatarFacetInit = await AvatarFacetInit.deploy()
  await avatarFacetInit.deployed()

  const selectors = getSelectors(avatarFacet)
  let avatarInitCalldata = avatarFacetInit.interface.encodeFunctionData('init')

  tx = await diamondCut.diamondCut(
      [{
        facetAddress: avatarFacet.address,
        action: FacetCutAction.Add,
        functionSelectors: selectors
      }],
      avatarFacetInit.address, avatarInitCalldata, { gasLimit: 800000 })
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed AvatarFacet')

  // upgrade diamond with VRFFacet
  const VRFFacet = await ethers.getContractFactory('VRFFacet')
  const vrfFacet = await VRFFacet.deploy()
  await vrfFacet.deployed()

  // deploy the init contract for VRFFacet
  const VRFFacetInit = await ethers.getContractFactory('VRFFacetInit')
  const vrfFacetInit = await VRFFacetInit.deploy()
  await vrfFacetInit.deployed()

  const vrfSelectors = getSelectors(vrfFacet)
  let vrfInitCalldata = vrfFacetInit.interface.encodeFunctionData('init', ['0x7a1bac17ccc5b313516c5e16fb24f7659aa5ebed', 3190, "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f", 100000, 3, 1])
  tx = await diamondCut.diamondCut(
    [{
      facetAddress: vrfFacet.address,
      action: FacetCutAction.Add,
      functionSelectors: vrfSelectors
    }],
    vrfFacetInit.address, vrfInitCalldata, { gasLimit: 800000 })
  
  receipt = await tx.wait()
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`)
  }
  console.log('Completed VRFFacet')

  return diamond.address
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
if (require.main === module) {
  deployDiamond()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error)
      process.exit(1)
    })
}

exports.deployDiamond = deployDiamond