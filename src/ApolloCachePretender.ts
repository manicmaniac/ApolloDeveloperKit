import { ApolloCache, Cache, Transaction } from 'apollo-cache';

export default class ApolloCachePretender extends ApolloCache<object> {
    private onExtract?: () => void;

    constructor(onExtract?: () => void) {
        super();
        this.onExtract = onExtract;
    }

    read(query: Cache.ReadOptions<any>): null {
        return null;
    }

    write(write: Cache.WriteOptions) {
    }

    diff(query: Cache.DiffOptions): Cache.DiffResult<any> {
        return {};
    }

    watch(watch: Cache.WatchOptions): () => void {
        return () => {};
    }

    evict(query: Cache.EvictOptions): Cache.EvictionResult {
        return { success: false };
    }

    reset(): Promise<void> {
        return new Promise(() => {});
    }

    restore(serializedState: object): ApolloCache<object> {
        return this;
    }

    extract(optimistic: boolean = false): object {
        this.onExtract?.();
        return {};
    }

    removeOptimistic(id: string) {
    }

    performTransaction(transaction: Transaction<object>) {
    }

    recordOptimisticTransaction(transaction: Transaction<object>, id: string) {
    }
}
