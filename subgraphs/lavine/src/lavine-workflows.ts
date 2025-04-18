import { ByteArray, Bytes, store } from "@graphprotocol/graph-ts";
import {
  WorkflowCreated as WorkflowCreatedEvent,
  WorkflowDeleted as WorkflowDeletedEvent,
} from "../generated/LavineWorkflows/LavineWorkflows";
import { WorkflowCreated, WorkflowDeleted } from "../generated/schema";
import { WorkflowMetadata } from "../generated/templates";

export function handleWorkflowCreated(event: WorkflowCreatedEvent): void {
  let entity = new WorkflowCreated(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.counter))
  );
  entity.uri = event.params.workflowMetadata;
  entity.creator = event.params.creator;
  entity.counter = event.params.counter;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let ipfsHash = (entity.uri as String).split("/").pop();
  if (ipfsHash != null) {
    entity.workflowMetadata = ipfsHash;
    WorkflowMetadata.create(ipfsHash);
  }

  entity.save();
}

export function handleWorkflowDeleted(event: WorkflowDeletedEvent): void {
  let entity = new WorkflowDeleted(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.counter = event.params.counter;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityWorkflow = WorkflowCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(entity.counter))
  );

  if (entityWorkflow) {
    store.remove(
      "WorkflowCreated",
      Bytes.fromByteArray(ByteArray.fromBigInt(entity.counter)).toHexString()
    );
  }
}
