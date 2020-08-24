import type { Cache, Transaction } from 'apollo-cache'
import { ApolloCache } from 'apollo-cache'

type CacheObject = {}

export default class ApolloCachePretender extends ApolloCache<unknown> {
  private onExtract?: () => void

  constructor(onExtract?: () => void) {
    super()
    this.onExtract = onExtract
  }

  read(_query: Cache.ReadOptions<unknown>): null {
    return null
  }

  write(_write: Cache.WriteOptions): void {
  }

  diff<T>(_query: Cache.DiffOptions): Cache.DiffResult<T> {
    return {}
  }

  watch(_watch: Cache.WatchOptions): () => void {
    return () => {}
  }

  evict(_query: Cache.EvictOptions): Cache.EvictionResult {
    return { success: true }
  }

  async reset(): Promise<void> {
  }

  restore(_serializedState: unknown): this {
    return this
  }

  extract(_optimistic = false): CacheObject {
    this.onExtract?.()
    return {}
  }

  removeOptimistic(_id: string): void {
  }

  performTransaction(_transaction: Transaction<unknown>): void {
  }

  recordOptimisticTransaction(_transaction: Transaction<unknown>, id: string): void {
  }
}
