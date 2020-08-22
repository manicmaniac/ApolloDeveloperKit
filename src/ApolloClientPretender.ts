import { parse } from 'graphql/language/parser'
import { print } from 'graphql/language/printer'
import { ApolloLink, Observable, RequestHandler } from 'apollo-link'
import { ApolloCache, DataProxy } from 'apollo-cache'
import { StateChange as DevtoolsStateChange } from './types/apollo-client-devtools'
import { Operation, StateChange as DeveloperKitStateChange } from './types/apollo-developer-kit'
import ApolloCachePretender from './ApolloCachePretender'

const requestHandler: RequestHandler = (operation, _forward) => {
  return new Observable(observer => {
    const body: Operation = {
      variables: operation.variables,
      operationName: operation.operationName,
      query: print(operation.query)
    }
    const options: RequestInit = {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(body)
    }
    fetch('/request', options)
      .then(response => {
        if (response.ok) {
          return response.json()
        }
        throw Error(response.statusText)
      })
      .then(json => observer.next(json))
      .then(() => observer.complete())
      .catch(error => observer.error(error))
  })
}

export default class ApolloClientPretender implements DataProxy {
  public readonly version = '2.0.0'
  public readonly link: ApolloLink = new ApolloLink(requestHandler)
  public readonly cache: ApolloCache<unknown> = new ApolloCachePretender(this.startListening.bind(this))

  private devToolsHookCb?: (event: DevtoolsStateChange) => void
  private eventSource?: EventSource

  public readQuery(options: DataProxy.Query<unknown>, optimistic = false): null {
    return this.cache.readQuery(options, optimistic)
  }

  public readFragment(options: DataProxy.Fragment<unknown>, optimistic = false): null {
    return this.cache.readFragment(options, optimistic)
  }

  public writeQuery(options: DataProxy.WriteQueryOptions<unknown, unknown>): void {
    this.cache.writeQuery(options)
  }

  public writeFragment(options: DataProxy.WriteFragmentOptions<unknown, unknown>): void {
    this.cache.writeFragment(options)
  }

  public writeData(options: DataProxy.WriteDataOptions<unknown>): void {
    this.cache.writeData(options)
  }

  public startListening(): void {
    this.eventSource = new EventSource('/events')
    this.eventSource.onmessage = message => {
      const event = JSON.parse(message.data) as DeveloperKitStateChange
      const newEvent = translateApolloStateChangeEvent(event)
      this.devToolsHookCb?.(newEvent)
    }
    this.eventSource.addEventListener('stdout', event => onLogMessageReceived(event as MessageEvent))
    this.eventSource.addEventListener('stderr', event => onLogMessageReceived(event as MessageEvent))
  }

  public stopListening(): void {
    this.eventSource?.close()
  }

  public __actionHookForDevTools(cb: (event: DevtoolsStateChange) => void): void {
    this.devToolsHookCb = cb
  }
}

function onLogMessageReceived(event: MessageEvent): void {
  const color = event.type === 'stdout' ? 'cadetblue' : 'tomato'
  console.log(`%c${event.data}`, `color: ${color}`)
}

function translateApolloStateChangeEvent(event: DeveloperKitStateChange): DevtoolsStateChange {
  const newEvent: DevtoolsStateChange = {
    state: {
      queries: [],
      mutations: []
    },
    dataWithOptimisticResults: event.dataWithOptimisticResults
  }
  for (const query of Object.values(event.state.queries)) {
    newEvent.state.queries.push({
      ...query,
      document: parse(query.document)
    })
  }
  for (const mutation of Object.values(event.state.mutations)) {
    newEvent.state.mutations.push({
      ...mutation,
      mutation: parse(mutation.mutation)
    })
  }
  return newEvent
}
