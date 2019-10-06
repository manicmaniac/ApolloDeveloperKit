import { parse } from 'graphql/language/parser';
import { print } from 'graphql/language/printer';
import { ApolloLink, Observable } from 'apollo-link';
import { ApolloCache, DataProxy } from 'apollo-cache';
import ApolloCachePretender from './ApolloCachePretender';

export default class ApolloClientPretender implements DataProxy {
  public version = '2.0.0';
  public link: ApolloLink;
  public cache: ApolloCache<object>

  private devToolsHookCb?: Function;
  private eventSource?: EventSource;

  constructor() {
    this.cache = new ApolloCachePretender(this.startListening.bind(this));
    this.link = new ApolloLink((operation, forward) => {
      return new Observable(observer => {
        const body = {
          variables: operation.variables,
          extensions: operation.extensions,
          operationName: operation.operationName,
          query: print(operation.query)
        };
        const options = {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json'
          },
          body: JSON.stringify(body)
        };
        fetch('/request', options)
          .then(response => {
            if (response.ok) {
              return response.json();
            } else {
              throw Error(response.statusText);
            }
          })
          .then(json => observer.next(json))
          .then(() => observer.complete())
          .catch(error => observer.error(error))
      });
    });
  }

  public readQuery(options: DataProxy.Query<any>, optimistic: boolean = false): null {
    return this.cache.readQuery(options, optimistic);
  }

  public readFragment(options: DataProxy.Fragment<any>, optimistic: boolean = false): null {
    return this.cache.readFragment(options, optimistic);
  }

  public writeQuery(options: DataProxy.WriteQueryOptions<any, any>): void {
    this.cache.writeQuery(options);
  }

  public writeFragment(options: DataProxy.WriteFragmentOptions<any, any>): void {
    this.cache.writeFragment(options);
  }

  public writeData(options: DataProxy.WriteDataOptions<any>): void {
    this.cache.writeData(options);
  }

  public startListening(): void {
    this.eventSource = new EventSource('/events');
    this.eventSource.onmessage = message => {
      try {
        const event = this.transformEvent(JSON.parse(message.data));
        if (this.devToolsHookCb) {
          this.devToolsHookCb(event);
        }
      } catch (SyntaxError) {
        console.log(message.data);
      }
    };
  }

  public stopListening(): void {
    if (this.eventSource) {
      this.eventSource.close();
    }
  }

  public __actionHookForDevTools(cb: () => any): void {
    this.devToolsHookCb = cb;
  }

  private transformEvent(event: any): any {
    Object.keys(event.state.queries).forEach(key => {
      event.state.queries[key].document = parse(event.state.queries[key].document);
    });
    Object.keys(event.state.mutations).forEach(key => {
      event.state.mutations[key].mutation = parse(event.state.mutations[key].mutation);
    });
    return event;
  }
}
