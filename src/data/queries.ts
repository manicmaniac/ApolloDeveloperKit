import { QueryStoreValue } from 'apollo-client/data/queries.d';

export class QueryStore {
  private store: { [queryId: string]: QueryStoreValue } = {};

  public getStore(): { [queryId: string]: QueryStoreValue } {
    return this.store;
  }
}