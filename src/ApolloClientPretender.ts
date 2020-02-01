import { parse } from 'graphql/language/parser';
import { print } from 'graphql/language/printer';
import { ApolloLink, Observable, RequestHandler, DocumentNode } from 'apollo-link';
import { ApolloCache, DataProxy } from 'apollo-cache';
import ApolloCachePretender from './ApolloCachePretender';

interface ApolloStateChangeEvent {
  action?: object,
  state: {
    queries: {
      string: {
        document: DocumentNode,
        variables?: object,
        previousVariables?: object,
        networkError?: object,
        graphQLErrors?: [object]
      }
    },
    mutations: {
      string: {
        mutation: DocumentNode,
        variables?: object,
        loading: boolean,
        error?: object
      }
    }
  },
  dataWithOptimisticResults: object
}

const requestHandler: RequestHandler = (operation, _forward) => {
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
        }
        throw Error(response.statusText);
      })
      .then(json => observer.next(json))
      .then(() => observer.complete())
      .catch(error => observer.error(error))
  });
}

export default class ApolloClientPretender implements DataProxy {
  public readonly version = '2.0.0';
  public readonly link: ApolloLink = new ApolloLink(requestHandler);
  public readonly cache: ApolloCache<object> = new ApolloCachePretender(this.startListening.bind(this));

  private devToolsHookCb?: (event: ApolloStateChangeEvent) => void;
  private eventSource?: EventSource;

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
      const event = parseApolloStateChangeEvent(message.data);
      this.devToolsHookCb?.(event);
    };
    this.eventSource.addEventListener('stdout', event => onLogMessageReceived(event as MessageEvent));
    this.eventSource.addEventListener('stderr', event => onLogMessageReceived(event as MessageEvent));
  }

  public stopListening(): void {
    this.eventSource?.close();
  }

  public __actionHookForDevTools(cb: (event: ApolloStateChangeEvent) => void): void {
    this.devToolsHookCb = cb;
  }
}

function onLogMessageReceived(event: MessageEvent): void {
  const color = event.type === 'stdout' ? 'cadetblue' : 'tomato';
  console.log(`%c${event.data}`, `color: ${color}`);
}

function parseApolloStateChangeEvent(json: string): ApolloStateChangeEvent {
  const event = JSON.parse(json);
  for (let query of Object.values(event.state.queries) as [{document: any}]) {
    query.document = parse(query.document);
  }
  for (let mutation of Object.values(event.state.mutations) as [{mutation: any}]) {
    mutation.mutation = parse(mutation.mutation);
  }
  return event as ApolloStateChangeEvent;
}
