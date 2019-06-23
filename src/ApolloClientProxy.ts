import { parse } from 'graphql/language/parser';
import { print } from 'graphql/language/printer';
import { ApolloLink, Observable } from 'apollo-link';

export default class ApolloClientProxy {
  public readonly version = '2.0.0';
  public readonly link: ApolloLink;

  private devToolsHookCb?: Function;
  private eventSource?: EventSource;

  constructor() {
    this.link = new ApolloLink((operation, forward) => {
      return new Observable(observer => {
        const body = {
          variables: operation.variables,
          extensions: operation.extensions,
          operationName: operation.operationName,
          query: print(operation.query)
        };
        const options = {
          method: "POST",
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

  public get cache() {
    const self = this;
    return {
      extract(optimistic: boolean = false): object {
        self.startListening();
        return {};
      },

      readQuery(options: any, optimistic: boolean = false): null {
        return null;
      }
    };
  }

  public startListening() {
    this.eventSource = new EventSource('/events');
    this.eventSource.onmessage = message => {
      const event = this.transformEvent(JSON.parse(message.data));
      console.log(event);
      if (this.devToolsHookCb) {
        this.devToolsHookCb(event);
      }
    };
  }

  public stopListening() {
    if (this.eventSource) {
      this.eventSource.close();
    }
  }

  public __actionHookForDevTools(cb: () => any) {
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
