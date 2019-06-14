// import { Cache } from 'apollo-cache';
import { parse } from 'graphql/language/parser';
import { ApolloLink } from 'apollo-link';
import ApolloCacheProxy from './ApolloCacheProxy';

export default class ApolloClientProxy {
  public version: string;
  public cache: ApolloCacheProxy;
  public link: any;

  private devToolsHookCb: Function;
  private eventSource?: EventSource;

  constructor() {
    this.version = '2.0.0';
    this.cache = new ApolloCacheProxy();
    this.eventSource = null;
    this.link = ApolloLink.empty();
  }

  public startListening() {
    this.eventSource = new EventSource('/events');
    this.eventSource.onmessage = message => {
      const event = this.transformEvent(JSON.parse(message.data));
      console.log(event);
      this.devToolsHookCb(event);
    };
    this.eventSource.onerror = error => {
      console.error(error);
    };
  }

  public stopListening() {
    if (this.eventSource) {
      this.eventSource.close();
      this.eventSource = null;
    }
  }

  public __actionHookForDevTools(cb: () => any) {
    this.devToolsHookCb = cb;
  }

  private transformEvent(event: any): any {
    Object.keys(event.state.queries).forEach(key => {
      event.state.queries[key].document = parse(event.state.queries[key].document);
    });
    return event;
  }
}