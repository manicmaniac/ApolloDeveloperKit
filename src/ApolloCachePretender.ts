import { ApolloCache, Cache, Transaction } from 'apollo-cache'

type CacheObject = {}

export default class ApolloCachePretender extends ApolloCache<object> {
  private onExtract?: () => void

  constructor(onExtract?: () => void) {
    super()
    this.onExtract = onExtract
  }

  read(query: Cache.ReadOptions<unknown>): null {
    return null
  }

  write(write: Cache.WriteOptions): void {
  }

  diff<T>(query: Cache.DiffOptions): Cache.DiffResult<T> {
    return {}
  }

  watch(watch: Cache.WatchOptions): () => void {
    return () => {}
  }

  evict(query: Cache.EvictOptions): Cache.EvictionResult {
    return { success: false }
  }

  reset(): Promise<void> {
    return new Promise(() => {})
  }

  restore(serializedState: object): ApolloCache<object> {
    return this
  }

  extract(optimistic: boolean = false): CacheObject {
    this.onExtract?.()
    return {}
  }

  removeOptimistic(id: string): void {
  }

  performTransaction(transaction: Transaction<object>): void {
  }

  recordOptimisticTransaction(transaction: Transaction<object>, id: string): void {
  }
}
