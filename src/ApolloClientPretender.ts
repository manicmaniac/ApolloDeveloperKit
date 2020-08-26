import type { FetchResult, Operation as LinkOperation } from 'apollo-link'
import type { DataProxy } from 'apollo-cache'
import type { StateChange as DevtoolsStateChange } from 'apollo-client-devtools'
import type { Operation, StateChange as DeveloperKitStateChange } from 'apollo-developer-kit'
import { parse } from 'graphql/language/parser'
import { print } from 'graphql/language/printer'
import { ApolloLink, fromPromise } from 'apollo-link'
import ApolloCachePretender from './ApolloCachePretender'

export default class ApolloClientPretender implements DataProxy {
  readonly version = '2.0.0'
  readonly link = new ApolloLink((operation) => fromPromise(requestOperation(operation)))
  readonly cache = new ApolloCachePretender(this.startListening.bind(this))

  private devToolsHookCb?: (event: DevtoolsStateChange) => void
  private eventSource?: EventSource

  readQuery = this.cache.readQuery.bind(this.cache)
  readFragment = this.cache.readFragment.bind(this.cache)
  writeQuery = this.cache.writeQuery.bind(this.cache)
  writeFragment = this.cache.writeFragment.bind(this.cache)
  writeData = this.cache.writeData.bind(this.cache)

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
  return {
    ...event,
    state: {
      queries: event.state.queries.map(query => ({
        ...query,
        document: parse(query.document)
      })),
      mutations: event.state.mutations.map(mutation => ({
        ...mutation,
        mutation: parse(mutation.mutation)
      }))
    }
  }
}
