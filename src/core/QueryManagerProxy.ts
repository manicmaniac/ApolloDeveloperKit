import { MutationStore } from '../data/mutations';
import { QueryStore } from '../data/queries';

export default class QueryManagerProxy {
  public mutationStore: MutationStore = new MutationStore();
  public queryStore: QueryStore = new QueryStore();
}