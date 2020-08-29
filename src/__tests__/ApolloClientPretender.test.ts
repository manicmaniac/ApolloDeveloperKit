import type { DataProxy } from 'apollo-cache'
import type { DocumentNode } from 'graphql'
import EventSourceMock, { sources } from 'eventsourcemock'
import { mocked } from 'ts-jest/utils'
import ApolloClientPretender from '../ApolloClientPretender'
import ApolloCachePretender from '../ApolloCachePretender'

jest.mock('../ApolloCachePretender')
jest.spyOn(console, 'log')

describe('ApolloClientPretender', () => {
  const query: DocumentNode = {
    kind: 'Document',
    definitions: []
  }

  let originalEventSource: typeof EventSource
  let client: ApolloClientPretender
  let cache: ApolloCachePretender

  beforeEach(() => {
    mocked(ApolloCachePretender).mockClear()
    mocked(console.log).mockClear()
    originalEventSource = window.EventSource
    window.EventSource = EventSourceMock as typeof EventSource
    client = new ApolloClientPretender()
    cache = mocked(ApolloCachePretender).mock.instances[0]
  })

  afterEach(() => {
    window.EventSource = originalEventSource
  })

  describe('#version', () => {
    it('is 2.0.0', () => {
      expect(client.version).toBe('2.0.0')
    })
  })

  describe('#cache', () => {
    it('returns its own cache', () => {
      expect(client.cache).toStrictEqual(cache)
    })
  })

  describe('#readQuery', () => {
    it('proxies method call to its own cache', () => {
      const options: DataProxy.Query<unknown> = { query }
      client.readQuery(options)
      expect(cache.readQuery).toHaveBeenCalledWith(options)
    })
  })

  describe('#readFragment', () => {
    it('proxies method call to its own cache', () => {
      const options: DataProxy.Fragment<unknown> = {
        id: '',
        fragment: query
      }
      client.readFragment(options)
      expect(cache.readFragment).toHaveBeenCalledWith(options)
    })
  })

  describe('#writeQuery', () => {
    it('proxies method call to its own cache', () => {
      const options: DataProxy.WriteQueryOptions<unknown, unknown> = {
        query,
        data: ''
      }
      client.writeQuery(options)
      expect(cache.writeQuery).toHaveBeenCalledWith(options)
    })
  })

  describe('#writeFragment', () => {
    it('proxies method call to its own cache', () => {
      const options: DataProxy.WriteFragmentOptions<unknown, unknown> = {
        id: '',
        fragment: query,
        data: ''
      }
      client.writeFragment(options)
      expect(cache.writeFragment).toHaveBeenCalledWith(options)
    })
  })

  describe('#writeData', () => {
    it('proxies method call to its own cache', () => {
      const options: DataProxy.WriteDataOptions<unknown> = { data: '' }
      client.writeData(options)
      expect(cache.writeData).toHaveBeenCalledWith(options)
    })
  })

  describe('#startListening', () => {
    const hook = jest.fn()

    beforeEach(() => {
      hook.mockClear()
      client.__actionHookForDevTools(hook)
      client.startListening()
    })

    afterEach(() => {
      client.stopListening()
    })

    it('starts event source', () => {
      expect(sources['/events'].readyState).toBe(0)
    })

    it('calls hook callback when it receives state change event', () => {
      const data = {
          state: {
            queries: [],
            mutations: []
          },
          dataWithOptimisticResults: {}
      }
      const event = {
        type: 'message',
        data: JSON.stringify(data)
      } as MessageEvent
      sources['/events'].emitMessage(event)
      expect(hook).toHaveBeenCalledWith(data)
    })

    it('writes data to console when it receives stdout event', () => {
      const event = {
        type: 'stdout',
        data: 'blah',
      } as MessageEvent
      sources['/events'].emit('stdout', event)
      expect(console.log).toHaveBeenCalledWith('%cblah', 'color: cadetblue')
    })

    it('writes data to console when it receives stderr event', () => {
      const event = {
        type: 'stderr',
        data: 'blah',
      } as MessageEvent
      sources['/events'].emit('stderr', event)
      expect(console.log).toHaveBeenCalledWith('%cblah', 'color: tomato')
    })
  })

  describe('#stopListening', () => {
    it('stops event source', () => {
      client.startListening()
      client.stopListening()
      expect(sources['/events'].readyState).toBe(2)
    })
  })
})
