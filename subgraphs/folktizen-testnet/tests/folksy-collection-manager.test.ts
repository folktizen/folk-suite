import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { BigInt, Address } from "@graphprotocol/graph-ts"
import { AgentDetailsUpdated } from "../generated/schema"
import { AgentDetailsUpdated as AgentDetailsUpdatedEvent } from "../generated/FolksyCollectionManager/FolksyCollectionManager"
import { handleAgentDetailsUpdated } from "../src/folksy-collection-manager"
import { createAgentDetailsUpdatedEvent } from "./folksy-collection-manager-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let customInstructions = ["Example string value"]
    let agentIds = [BigInt.fromI32(234)]
    let collectionId = BigInt.fromI32(234)
    let newAgentDetailsUpdatedEvent = createAgentDetailsUpdatedEvent(
      customInstructions,
      agentIds,
      collectionId
    )
    handleAgentDetailsUpdated(newAgentDetailsUpdatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("AgentDetailsUpdated created and stored", () => {
    assert.entityCount("AgentDetailsUpdated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "AgentDetailsUpdated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "customInstructions",
      "[Example string value]"
    )
    assert.fieldEquals(
      "AgentDetailsUpdated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "agentIds",
      "[234]"
    )
    assert.fieldEquals(
      "AgentDetailsUpdated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "collectionId",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
