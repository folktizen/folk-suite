import {
  Address,
  BigInt,
  ByteArray,
  Bytes,
  store,
} from "@graphprotocol/graph-ts";
import {
  CollectionPurchased as CollectionPurchasedEvent,
  FulfillmentUpdated as FulfillmentUpdatedEvent,
  FolksyMarket,
} from "../generated/FolksyMarket/FolksyMarket";
import {
  AgentCreated,
  Balance,
  CollectionCreated,
  CollectionPrice,
  CollectionPurchased,
  CollectionWorker,
  FulfillmentUpdated,
  Price,
} from "../generated/schema";
import { FolksyCollectionManager } from "../generated/FolksyCollectionManager/FolksyCollectionManager";
import { FolksyAgents } from "../generated/FolksyAgents/FolksyAgents";

export function handleCollectionPurchased(
  event: CollectionPurchasedEvent
): void {
  let entity = new CollectionPurchased(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.orderId))
  );
  entity.buyer = event.params.buyer;
  entity.paymentToken = event.params.paymentToken;
  entity.orderId = event.params.orderId;
  entity.collectionId = event.params.collectionId;
  entity.amount = event.params.amount;
  entity.artistShare = event.params.artistShare;
  entity.fulfillerShare = event.params.fulfillerShare;
  entity.agentShare = event.params.agentShare;
  entity.remixShare = event.params.remixShare;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  let market = FolksyMarket.bind(event.address);

  let collectionManager = FolksyCollectionManager.bind(
    Address.fromString("0x94BAF3CB73bCCeC41496f8da648caD9d02aAA0ab")
  );
  let agentContract = FolksyAgents.bind(
    Address.fromString("0x652CE0ff95c1dECB1FCdaD09FB7919dB062e5969")
  );
  entity.mintedTokens = market.getOrderMintedTokens(event.params.orderId);
  entity.totalPrice = market.getOrderTotalPrice(event.params.orderId);
  entity.collection = Bytes.fromByteArray(
    ByteArray.fromBigInt(event.params.collectionId)
  );
  entity.fulfillment = market.getOrderFulfillmentDetails(event.params.orderId);
  entity.fulfiller = collectionManager.getCollectionFulfillerId(
    event.params.collectionId
  );
  entity.save();

  let entityCollection = CollectionCreated.load(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.collectionId))
  );

  if (entityCollection) {
    let sold = collectionManager.getCollectionAmountSold(
      event.params.collectionId
    );

    entityCollection.tokenIds = collectionManager.getCollectionTokenIds(
      event.params.collectionId
    );
    entityCollection.amountSold = sold;

    entityCollection.save();

    if (sold.equals(entityCollection.amount)) {
      let agents = entityCollection.agentIds;

      if (agents) {
        for (let i = 0; i < (agents as BigInt[]).length; i++) {
          let entityAgent = AgentCreated.load(
            Bytes.fromByteArray(ByteArray.fromBigInt((agents as BigInt[])[i]))
          );

          if (entityAgent) {
            let newWorkers: Bytes[] = [];
            let newBalances: Bytes[] = [];
            let workers = entityAgent.workers;
            if (workers) {
              for (let j = 0; j < (workers as Bytes[]).length; j++) {
                let worker = CollectionWorker.load((workers as Bytes[])[j]);
                if (worker && worker.collectionId) {
                  if ((worker.collectionId as BigInt).equals(entity.collectionId)) {
                    store.remove(
                      "CollectionWorker",
                      (workers as Bytes[])[j].toHexString()
                    );
                  } else {
                    newWorkers.push((workers as Bytes[])[j]);
                  }
                }
              }
            }

            let balances = entityAgent.balances;

            if (balances) {
              for (let j = 0; j < (balances as Bytes[]).length; j++) {
                let updateBalance = Balance.load((balances as Bytes[])[j]);

                if (updateBalance && updateBalance.collectionId) {
                  if ((updateBalance.collectionId as BigInt).equals( entity.collectionId)) {
                    store.remove(
                      "Balance",
                      (balances as Bytes[])[j].toHexString()
                    );
                  } else {
                    newBalances.push((balances as Bytes[])[j]);
                  }
                }
              }
            }

            let active = agentContract.getAgentActiveCollectionIds(
              entityAgent.SkypodsAgentManager_id
            );
            let cols: Bytes[] = [];

            for (let k = 0; k < (active as BigInt[]).length; k++) {
              cols.push(
                Bytes.fromByteArray(
                  ByteArray.fromBigInt((active as BigInt[])[k])
                )
              );
            }

            entityAgent.activeCollectionIds = cols;
            entityAgent.balances = newBalances;
            entityAgent.workers = newWorkers;
            entityAgent.save();
          }
        }
      }
    }

    for (let i = 0; i < (entityCollection.prices as Bytes[]).length; i++) {
      let price = Price.load((entityCollection.prices as Bytes[])[i]);

      if (price) {
        let tokenHex = (price.token as Bytes).toHexString();
        let collectionHex = entity.collectionId.toHexString();
        let combinedPriceHex = tokenHex + collectionHex;
        if (combinedPriceHex.length % 2 !== 0) {
          combinedPriceHex = "0" + combinedPriceHex;
        }

        let collectionPrice = CollectionPrice.load(
          Bytes.fromByteArray(ByteArray.fromUTF8(combinedPriceHex))
        );

        if (collectionPrice) {
          collectionPrice.amountSold = sold;

          if (sold == entityCollection.amount) {
            collectionPrice.soldOut = true;
          }

          collectionPrice.save();
        }
      }
    }
  }
}

export function handleFulfillmentUpdated(event: FulfillmentUpdatedEvent): void {
  let entity = new FulfillmentUpdated(
    event.transaction.hash.concatI32(event.logIndex.toI32())
  );
  entity.fulfillment = event.params.fulfillment;
  entity.orderId = event.params.orderId;

  entity.blockNumber = event.block.number;
  entity.blockTimestamp = event.block.timestamp;
  entity.transactionHash = event.transaction.hash;

  entity.save();

  let orderEntity = new CollectionPurchased(
    Bytes.fromByteArray(ByteArray.fromBigInt(event.params.orderId))
  );

  if (orderEntity) {
    orderEntity.fulfillment = event.params.fulfillment;
    orderEntity.save();
  }
}
