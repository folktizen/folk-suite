import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt } from "@graphprotocol/graph-ts"
import {
  WorkflowCreated,
  WorkflowDeleted
} from "../generated/LavineWorkflows/LavineWorkflows"

export function createWorkflowCreatedEvent(
  workflowMetadata: string,
  creator: Address,
  counter: BigInt
): WorkflowCreated {
  let workflowCreatedEvent = changetype<WorkflowCreated>(newMockEvent())

  workflowCreatedEvent.parameters = new Array()

  workflowCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "workflowMetadata",
      ethereum.Value.fromString(workflowMetadata)
    )
  )
  workflowCreatedEvent.parameters.push(
    new ethereum.EventParam("creator", ethereum.Value.fromAddress(creator))
  )
  workflowCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "counter",
      ethereum.Value.fromUnsignedBigInt(counter)
    )
  )

  return workflowCreatedEvent
}

export function createWorkflowDeletedEvent(counter: BigInt): WorkflowDeleted {
  let workflowDeletedEvent = changetype<WorkflowDeleted>(newMockEvent())

  workflowDeletedEvent.parameters = new Array()

  workflowDeletedEvent.parameters.push(
    new ethereum.EventParam(
      "counter",
      ethereum.Value.fromUnsignedBigInt(counter)
    )
  )

  return workflowDeletedEvent
}
