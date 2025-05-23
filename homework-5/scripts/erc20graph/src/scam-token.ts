import {
    Transfer as TransferEvent
} from "../generated/ScamToken/ScamToken"
import {Transfer, Account} from "../generated/schema"
import {BigInt} from "@graphprotocol/graph-ts";

export function handleTransfer(event: TransferEvent): void {
    let accountFrom = Account.load(event.params.from)
    if (!accountFrom) {
        accountFrom = new Account(event.params.from)
        accountFrom.balance = BigInt.zero()
    }
    let accountTo = Account.load(event.params.to)
    if (!accountTo) {
        accountTo = new Account(event.params.to)
        accountTo.balance = BigInt.zero()
    }
    accountFrom.balance = accountFrom.balance.minus(event.params.value)
    accountTo.balance = accountTo.balance.plus(event.params.value)
    accountFrom.save()
    accountTo.save()

    let entity = new Transfer(
        event.transaction.hash.concatI32(event.logIndex.toI32())
    )

    entity.from = accountFrom.id
    entity.to = accountTo.id
    entity.value = event.params.value

    entity.blockNumber = event.block.number
    entity.blockTimestamp = event.block.timestamp
    entity.transactionHash = event.transaction.hash

    entity.save()
}
