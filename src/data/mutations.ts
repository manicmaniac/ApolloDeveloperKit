import { MutationStoreValue } from 'apollo-client/data/mutations.d';

export class MutationStore {
  private store: { [mutationId: string]: MutationStoreValue } = {};

  public getStore(): { [mutationId: string]: MutationStoreValue } {
    return this.store;
  }
}