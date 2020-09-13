import type { Cache, Transaction } from 'apollo-cache'
import { ApolloCache } from 'apollo-cache'

type CacheObject = Record<string, any>

export default class ApolloCachePretender extends ApolloCache<any> {
  private onExtract?: () => void

  constructor(onExtract?: () => void) {
    super()
    this.onExtract = onExtract
  }

  read(_query: Cache.ReadOptions<any>): null {
    return null
  }

  write(_write: Cache.WriteOptions): void {
    // do nothing
  }

  diff<T>(_query: Cache.DiffOptions): Cache.DiffResult<T> {
    return {}
  }

  watch(_watch: Cache.WatchOptions): () => void {
    return () => { /* do nothing */}
  }

  evict(_query: Cache.EvictOptions): Cache.EvictionResult {
    return { success: true }
  }

  async reset(): Promise<void> {
    // do nothing
  }

  restore(_serializedState: any): this {
    return this
  }

  extract(_optimistic = false): CacheObject {
    this.onExtract?.()
    return {}
  }

  removeOptimistic(_id: string): void {
    // do nothing
  }

  performTransaction(transaction: Transaction<any>): void {
    transaction(this)
  }

  recordOptimisticTransaction(transaction: Transaction<any>, _id: string): void {
    transaction(this)
  }
}
