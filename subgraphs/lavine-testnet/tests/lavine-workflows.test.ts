import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt } from "@graphprotocol/graph-ts"
import { WorkflowCreated } from "../generated/schema"
import { WorkflowCreated as WorkflowCreatedEvent } from "../generated/LavineWorkflows/LavineWorkflows"
import { handleWorkflowCreated } from "../src/lavine-workflows"
import { createWorkflowCreatedEvent } from "./lavine-workflows-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let workflowMetadata = "Example string value"
    let creator = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let counter = BigInt.fromI32(234)
    let newWorkflowCreatedEvent = createWorkflowCreatedEvent(
      workflowMetadata,
      creator,
      counter
    )
    handleWorkflowCreated(newWorkflowCreatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("WorkflowCreated created and stored", () => {
    assert.entityCount("WorkflowCreated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "WorkflowCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "workflowMetadata",
      "Example string value"
    )
    assert.fieldEquals(
      "WorkflowCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "creator",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "WorkflowCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "counter",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
