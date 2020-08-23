import type { FetchResult, Operation as LinkOperation } from 'apollo-link'
import type { ApolloCache, DataProxy } from 'apollo-cache'
import type { StateChange as DevtoolsStateChange } from 'apollo-client-devtools'
import type { Operation, StateChange as DeveloperKitStateChange } from 'apollo-developer-kit'
import { parse } from 'graphql/language/parser'
import { print } from 'graphql/language/printer'
import { ApolloLink, fromPromise } from 'apollo-link'
import ApolloCachePretender from './ApolloCachePretender'

export default class ApolloClientPretender implements DataProxy {
  readonly version = '2.0.0'
  readonly link: ApolloLink = new ApolloLink((operation) => fromPromise(requestOperation(operation)))
  readonly cache: ApolloCache<unknown> = new ApolloCachePretender(this.startListening.bind(this))

  private devToolsHookCb?: (event: DevtoolsStateChange) => void
  private eventSource?: EventSource

  readQuery(options: DataProxy.Query<unknown>, optimistic = false): null {
    return this.cache.readQuery(options, optimistic)
  }

  readFragment(options: DataProxy.Fragment<unknown>, optimistic = false): null {
    return this.cache.readFragment(options, optimistic)
  }

  writeQuery(options: DataProxy.WriteQueryOptions<unknown, unknown>): void {
    this.cache.writeQuery(options)
  }

  writeFragment(options: DataProxy.WriteFragmentOptions<unknown, unknown>): void {
    this.cache.writeFragment(options)
  }

  writeData(options: DataProxy.WriteDataOptions<unknown>): void {
    this.cache.writeData(options)
  }

  startListening(): void {
    this.eventSource = new EventSource('/events')
    this.eventSource.onmessage = message => {
      const event = JSON.parse(message.data) as DeveloperKitStateChange
      const newEvent = translateApolloStateChangeEvent(event)
      this.devToolsHookCb?.(newEvent)
    }
    this.eventSource.addEventListener('stdout', event => onLogMessageReceived(event as MessageEvent))
    this.eventSource.addEventListener('stderr', event => onLogMessageReceived(event as MessageEvent))
  }

  stopListening(): void {
    this.eventSource?.close()
  }

  __actionHookForDevTools(cb: (event: DevtoolsStateChange) => void): void {
    this.devToolsHookCb = cb
  }
}

async function requestOperation(operation: LinkOperation): Promise<FetchResult> {
  const body: Operation = {
    variables: operation.variables,
    operationName: operation.operationName,
    query: print(operation.query)
  }
  const options: RequestInit = {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body)
  }
  const response = await fetch('/request', options)
  if (!response.ok) {
    throw new Error(response.statusText)
  }
  return await response.json()
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
