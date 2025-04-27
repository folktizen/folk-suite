import {
  Address,
  BigInt,
  ByteArray,
  Bytes,
  log,
} from "@graphprotocol/graph-ts";
import {
  ActivateAgent as ActivateAgentEvent,
  AgentPaidRent as AgentPaidRentEvent,
  AgentRecharged as AgentRechargedEvent,
  BalanceAdded as BalanceAddedEvent,
  RewardsCalculated as RewardsCalculatedEvent,
  FolksyAgents,
  WorkerAdded as WorkerAddedEvent,
  WorkerUpdated as WorkerUpdatedEvent,
  WorkerRemoved as WorkerRemovedEvent,
  CollectorPaid as CollectorPaidEvent,
  OwnerPaid as OwnerPaidEvent,
  DevTreasuryPaid as DevTreasuryPaidEvent,
  ArtistPaid as ArtistPaidEvent,
} from "../generated/FolksyAgents/FolksyAgents";
import {
  ActivateAgent,
  AgentCreated,
  AgentPaidRent,
  AgentRecharged,
  Balance,
  BalanceAdded,
  CollectionWorker,
  RewardsCalculated,
  WorkerAdded,
  WorkerUpdated,
  WorkerRemoved,
  CollectorPaid,
  OwnerPaid,
  DevTreasuryPaid,
  ArtistPaid,
} from "../generated/schema";
import { FolksyCollectionManager } from "../generated/FolksyCollectionManager/FolksyCollectionManager";

export function handleActivateAgent(event: ActivateAgentEvent): void {
  let entity = new ActivateAgent(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.wallet = event.params.wallet;
  entity.agentId = event.params.agentId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleAgentPaidRent(event: AgentPaidRentEvent): void {
  let entity = new AgentPaidRent(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.tokens = event.params.tokens.map<Bytes>((target: Bytes) => target);
  entity.collectionIds = event.params.collectionIds;
  entity.amounts = event.params.amounts;
  entity.bonuses = event.params.bonuses;
  entity.agentId = event.params.agentId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityAgent = AgentCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(entity.agentId))
  );

  if (entityAgent) {
    let agents = FolksyAgents.bind(event.address);
    let balances = entityAgent.balances;

    if (!balances) {
      balances = [];
    }

    for (let i = 0; i < (entity.collectionIds as BigInt[]).length; i++) {
      let collectionIdHex = entity.collectionIds[i].toHexString();
      let tokenHex = entity.tokens[i].toHexString();
      let agentHex = entity.agentId.toHexString();
      let agentWalletHex = entityAgent.wallets[0].toHexString();
      let combinedHex = collectionIdHex + tokenHex + agentHex + agentWalletHex;
      if (combinedHex.length % 2 !== 0) {
        combinedHex = "0" + combinedHex;
      }

      let newBalance = Balance.load(
        Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex))
      );
      if (!newBalance) {
        newBalance = new Balance(
          Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex))
        );
        newBalance.collectionId = entity.collectionIds[i];
        newBalance.token = entity.tokens[i];
        balances.push(Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex)));
      }

      newBalance.rentBalance = agents.getAgentRentBalance(
        event.params.tokens[i],
        entity.agentId,
        entity.collectionIds[i]
      );
      newBalance.historicalRentBalance = agents.getAgentHistoricalRentBalance(
        event.params.tokens[i],
        entity.agentId,
        entity.collectionIds[i]
      );
      newBalance.bonusBalance = agents.getAgentBonusBalance(
        event.params.tokens[i],
        entity.agentId,
        entity.collectionIds[i]
      );
      newBalance.historicalBonusBalance = agents.getAgentHistoricalBonusBalance(
        event.params.tokens[i],
        entity.agentId,
        entity.collectionIds[i]
      );

      let workerHex = collectionIdHex + agentHex;
      if (workerHex.length % 2 !== 0) {
        workerHex = "0" + workerHex;
      }

      newBalance.worker = Bytes.fromByteArray(
        ByteArray.fromHexString(workerHex)
      );
      newBalance.collection = Bytes.fromByteArray(
        ByteArray.fromBigInt((entity.collectionIds as BigInt[])[i])
      );
      newBalance.save();
    }
    entityAgent.balances = balances;

    let activeCollectionIds: Bytes[] = [];
    let collectionIdsHistory: Bytes[] = [];

    let activeIds: BigInt[] = agents.getAgentActiveCollectionIds(
      entity.agentId
    );
    let historyIds: BigInt[] = agents.getAgentCollectionIdsHistory(
      entity.agentId
    );
    for (let i = 0; i < (activeIds as BigInt[]).length; i++) {
      activeCollectionIds.push(
        Bytes.fromByteArray(ByteArray.fromBigInt((activeIds as BigInt[])[i]))
      );
    }

    for (let i = 0; i < (historyIds as BigInt[]).length; i++) {
      collectionIdsHistory.push(
        Bytes.fromByteArray(ByteArray.fromBigInt((historyIds as BigInt[])[i]))
      );
    }

    entityAgent.activeCollectionIds = activeCollectionIds;
    entityAgent.collectionIdsHistory = collectionIdsHistory;

    entityAgent.save();
  }
}

export function handleAgentRecharged(event: AgentRechargedEvent): void {
  let entity = new AgentRecharged(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.recharger = event.params.recharger;
  entity.token = event.params.token;
  entity.agentId = event.params.agentId;
  entity.collectionId = event.params.collectionId;
  entity.amount = event.params.amount;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityAgent = AgentCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(entity.agentId))
  );

  if (entityAgent) {
    let agents = FolksyAgents.bind(event.address);
   

    let collectionIdHex = entity.collectionId.toHexString();
    let tokenHex = entity.token.toHexString();
    let agentHex = entity.agentId.toHexString();
    let agentWalletHex = (entityAgent.wallets as Bytes[])[0].toHexString();
    let combinedHex = collectionIdHex + tokenHex + agentHex + agentWalletHex;
    if (combinedHex.length % 2 !== 0) {
      combinedHex = "0" + combinedHex;
    }

    let balances = entityAgent.balances;

    if (!balances) {
      balances = [];
    }

    let newBalance = Balance.load(
      Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex))
    );
    if (!newBalance) {
      newBalance = new Balance(
        Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex))
      );
      newBalance.collectionId = entity.collectionId;
      newBalance.token = entity.token;
      balances.push(Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex)));
    }

    newBalance.rentBalance = agents.getAgentRentBalance(
      event.params.token,
      entity.agentId,
      entity.collectionId
    );
    newBalance.historicalRentBalance = agents.getAgentHistoricalRentBalance(
      event.params.token,
      entity.agentId,
      entity.collectionId
    );
    newBalance.bonusBalance = agents.getAgentBonusBalance(
      event.params.token,
      entity.agentId,
      entity.collectionId
    );
    newBalance.historicalBonusBalance = agents.getAgentHistoricalBonusBalance(
      event.params.token,
      entity.agentId,
      entity.collectionId
    );

    let workerHex = collectionIdHex + agentHex;
    if (workerHex.length % 2 !== 0) {
      workerHex = "0" + workerHex;
    }

    newBalance.worker = Bytes.fromByteArray(ByteArray.fromHexString(workerHex));
    newBalance.collection = Bytes.fromByteArray(
      ByteArray.fromBigInt(event.params.collectionId)
    );

    newBalance.save();

    entityAgent.balances = balances;

    let activeCollectionIds: Bytes[] = [];
    let collectionIdsHistory: Bytes[] = [];

    let activeIds: BigInt[] = agents.getAgentActiveCollectionIds(
      entity.agentId
    );
    let historyIds: BigInt[] = agents.getAgentCollectionIdsHistory(
      entity.agentId
    );
    for (let i = 0; i < (activeIds as BigInt[]).length; i++) {
      activeCollectionIds.push(
        Bytes.fromByteArray(ByteArray.fromBigInt((activeIds as BigInt[])[i]))
      );
    }

    for (let i = 0; i < (historyIds as BigInt[]).length; i++) {
      collectionIdsHistory.push(
        Bytes.fromByteArray(ByteArray.fromBigInt((historyIds as BigInt[])[i]))
      );
    }

    entityAgent.activeCollectionIds = activeCollectionIds;
    entityAgent.collectionIdsHistory = collectionIdsHistory;

    entityAgent.save();
  }
}

export function handleBalanceAdded(event: BalanceAddedEvent): void {
  let entity = new BalanceAdded(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.token = event.params.token;
  entity.agentId = event.params.agentId;
  entity.amount = event.params.amount;
  entity.collectionId = event.params.collectionId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityAgent = AgentCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(entity.agentId))
  );

  if (entityAgent) {
    let agents = FolksyAgents.bind(event.address);
   

    let collectionIdHex = entity.collectionId.toHexString();
    let tokenHex = entity.token.toHexString();
    let agentHex = entity.agentId.toHexString();
    let agentWalletHex = (entityAgent.wallets as Bytes[])[0].toHexString();
    let combinedHex = collectionIdHex + tokenHex + agentHex + agentWalletHex;
    if (combinedHex.length % 2 !== 0) {
      combinedHex = "0" + combinedHex;
    }

    let balances = entityAgent.balances;

    if (!balances) {
      balances = [];
    }

    let newBalance = Balance.load(
      Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex))
    );
    if (!newBalance) {
      newBalance = new Balance(
        Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex))
      );
      newBalance.collectionId = entity.collectionId;
      newBalance.token = entity.token;
      balances.push(Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex)));
    }

    newBalance.rentBalance = agents.getAgentRentBalance(
      event.params.token,
      entity.agentId,
      entity.collectionId
    );
    newBalance.historicalRentBalance = agents.getAgentHistoricalRentBalance(
      event.params.token,
      entity.agentId,
      entity.collectionId
    );
    newBalance.bonusBalance = agents.getAgentBonusBalance(
      event.params.token,
      entity.agentId,
      entity.collectionId
    );
    newBalance.historicalBonusBalance = agents.getAgentHistoricalBonusBalance(
      event.params.token,
      entity.agentId,
      entity.collectionId
    );

    let workerHex = collectionIdHex + agentHex;
    if (workerHex.length % 2 !== 0) {
      workerHex = "0" + workerHex;
    }

    newBalance.worker = Bytes.fromByteArray(ByteArray.fromHexString(workerHex));
    newBalance.collection = Bytes.fromByteArray(
      ByteArray.fromBigInt(event.params.collectionId)
    );

    newBalance.save();

    entityAgent.balances = balances;

    let activeCollectionIds: Bytes[] = [];
    let collectionIdsHistory: Bytes[] = [];

    let activeIds: BigInt[] = agents.getAgentActiveCollectionIds(
      entity.agentId
    );
    let historyIds: BigInt[] = agents.getAgentCollectionIdsHistory(
      entity.agentId
    );
    for (let i = 0; i < (activeIds as BigInt[]).length; i++) {
      activeCollectionIds.push(
        Bytes.fromByteArray(ByteArray.fromBigInt((activeIds as BigInt[])[i]))
      );
    }

    for (let i = 0; i < (historyIds as BigInt[]).length; i++) {
      collectionIdsHistory.push(
        Bytes.fromByteArray(ByteArray.fromBigInt((historyIds as BigInt[])[i]))
      );
    }

    entityAgent.activeCollectionIds = activeCollectionIds;
    entityAgent.collectionIdsHistory = collectionIdsHistory;

    entityAgent.save();
  }
}

export function handleRewardsCalculated(event: RewardsCalculatedEvent): void {
  let entity = new RewardsCalculated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.token = event.params.token;
  entity.amount = event.params.amount;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleWorkerAdded(event: WorkerAddedEvent): void {
  let entity = new WorkerAdded(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.agentId = event.params.agentId;
  entity.collectionId = event.params.collectionId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityAgent = AgentCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.agentId))
  );

  if (entityAgent) {
    let workers = entityAgent.workers;
    if (!workers) {
      workers = [];
    }

    let agents = FolksyAgents.bind(event.address);

    let collectionIdHex = event.params.agentId.toHexString();
    let agentHex = event.params.collectionId.toHexString();
    let combinedHex = collectionIdHex + agentHex;
    if (combinedHex.length % 2 !== 0) {
      combinedHex = "0" + combinedHex;
    }

    workers.push(Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex)));
    let newWorker = new CollectionWorker(
      Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex))
    );

    newWorker.instructions = agents.getWorkerInstructions(
      event.params.agentId,
      event.params.collectionId
    );
    let collectionManager = FolksyCollectionManager.bind(
      Address.fromString("0x94BAF3CB73bCCeC41496f8da648caD9d02aAA0ab")
    );
    newWorker.tokens = collectionManager
      .getCollectionERC20Tokens(event.params.collectionId)
      .map<Bytes>((target: Bytes) => target);
    newWorker.collectionId = event.params.collectionId;

    newWorker.publish = agents.getWorkerPublish(
      event.params.agentId,
      event.params.collectionId
    );
    newWorker.lead = agents.getWorkerLead(
      event.params.agentId,
      event.params.collectionId
    );
    newWorker.remix = agents.getWorkerRemix(
      event.params.agentId,
      event.params.collectionId
    );
    newWorker.publishFrequency = agents.getWorkerPublishFrequency(
      event.params.agentId,
      event.params.collectionId
    );
    newWorker.leadFrequency = agents.getWorkerLeadFrequency(
      event.params.agentId,
      event.params.collectionId
    );
    newWorker.remixFrequency = agents.getWorkerRemixFrequency(
      event.params.agentId,
      event.params.collectionId
    );
    newWorker.mintFrequency = agents.getWorkerMintFrequency(
      event.params.agentId,
      event.params.collectionId
    );
    newWorker.mint = agents.getWorkerMint(
      event.params.agentId,
      event.params.collectionId
    );
    newWorker.collection = Bytes.fromByteArray(
      ByteArray.fromBigInt(event.params.collectionId)
    );

    entityAgent.workers = workers;

    newWorker.save();
    entityAgent.save();
  }
}

export function handleWorkerRemoved(event: WorkerRemovedEvent): void {
  let entity = new WorkerRemoved(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.agentId = event.params.agentId;
  entity.collectionId = event.params.collectionId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityAgent = AgentCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.agentId))
  );

  if (entityAgent) {
    let workers = entityAgent.workers;
    let newWorkers: Bytes[] = [];

    if (workers) {
      for (let i = 0; i < (workers as Bytes[]).length; i++) {
        let collectionIdHex = event.params.agentId.toHexString();
        let agentHex = event.params.collectionId.toHexString();
        let combinedHex = collectionIdHex + agentHex;
        if (combinedHex.length % 2 !== 0) {
          combinedHex = "0" + combinedHex;
        }

        if (
          Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex)) !==
          (workers as Bytes[])[i]
        ) {
          newWorkers.push((workers as Bytes[])[i]);
        }
      }
    }

    entityAgent.workers = newWorkers;
    entityAgent.save();
  }
}

export function handleWorkerUpdated(event: WorkerUpdatedEvent): void {
  let entity = new WorkerUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.agentId = event.params.agentId;
  entity.collectionId = event.params.collectionId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let entityAgent = AgentCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.agentId))
  );

  if (entityAgent) {
    let workers = entityAgent.workers;
    if (!workers) {
      workers = [];
    }

    let agents = FolksyAgents.bind(event.address);

    let collectionIdHex = event.params.agentId.toHexString();
    let agentHex = event.params.collectionId.toHexString();
    let combinedHex = collectionIdHex + agentHex;
    if (combinedHex.length % 2 !== 0) {
      combinedHex = "0" + combinedHex;
    }

    let newWorker = CollectionWorker.load(
      Bytes.fromByteArray(ByteArray.fromUTF8(combinedHex))
    );

    if (newWorker) {
      let collectionManager = FolksyCollectionManager.bind(
        Address.fromString("0x94BAF3CB73bCCeC41496f8da648caD9d02aAA0ab")
      );
      newWorker.instructions = agents.getWorkerInstructions(
        event.params.agentId,
        event.params.collectionId
      );
      newWorker.tokens = collectionManager
        .getCollectionERC20Tokens(event.params.collectionId)
        .map<Bytes>((target: Bytes) => target);
      newWorker.collectionId = event.params.collectionId;

      newWorker.publish = agents.getWorkerPublish(
        event.params.agentId,
        event.params.collectionId
      );
      newWorker.lead = agents.getWorkerLead(
        event.params.agentId,
        event.params.collectionId
      );
      newWorker.remix = agents.getWorkerRemix(
        event.params.agentId,
        event.params.collectionId
      );
      newWorker.publishFrequency = agents.getWorkerPublishFrequency(
        event.params.agentId,
        event.params.collectionId
      );
      newWorker.leadFrequency = agents.getWorkerLeadFrequency(
        event.params.agentId,
        event.params.collectionId
      );
      newWorker.remixFrequency = agents.getWorkerRemixFrequency(
        event.params.agentId,
        event.params.collectionId
      );
      newWorker.mintFrequency = agents.getWorkerMintFrequency(
        event.params.agentId,
        event.params.collectionId
      );
      newWorker.mint = agents.getWorkerMint(
        event.params.agentId,
        event.params.collectionId
      );
      newWorker.collection = Bytes.fromByteArray(
        ByteArray.fromBigInt(event.params.collectionId)
      );

      newWorker.save();
    }
  }
}

export function handleOwnerPaid(event: OwnerPaidEvent): void {
  let entity = new OwnerPaid(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.owner = event.params.owner;
  entity.token = event.params.token;
  entity.amount = event.params.amount;
  entity.collectionId = event.params.collectionId;
  entity.collection = Bytes.fromByteArray(
    ByteArray.fromBigInt(event.params.collectionId)
  );

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleCollectorPaid(event: CollectorPaidEvent): void {
  let entity = new CollectorPaid(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.collector = event.params.collector;
  entity.token = event.params.token;
  entity.amount = event.params.amount;
  entity.collectionId = event.params.collectionId;
  entity.collection = Bytes.fromByteArray(
    ByteArray.fromBigInt(event.params.collectionId)
  );

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleDevTreasuryPaid(event: DevTreasuryPaidEvent): void {
  let entity = new DevTreasuryPaid(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.token = event.params.token;
  entity.amount = event.params.amount;
  entity.collectionId = event.params.collectionId;
  entity.collection = Bytes.fromByteArray(
    ByteArray.fromBigInt(event.params.collectionId)
  );

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}

export function handleArtistPaid(event: ArtistPaidEvent): void {
  let entity = new ArtistPaid(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.forArtist = event.params.forArtist;
  entity.token = event.params.token;
  entity.amount = event.params.amount;
  entity.collectionId = event.params.collectionId;
  entity.agentId = event.params.agentId;
  entity.collection = Bytes.fromByteArray(
    ByteArray.fromBigInt(event.params.collectionId)
  );

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();
}
