import type { DocumentNode } from 'graphql'
import type { Transaction } from 'apollo-cache'
import ApolloCachePretender from '../ApolloCachePretender'

describe('ApolloCachePretender', () => {
  const query: DocumentNode = {
    kind: 'Document',
    definitions: []
  }

  let cache: ApolloCachePretender
  const onExtract = jest.fn()

  beforeEach(() => {
    cache = new ApolloCachePretender(onExtract)
    onExtract.mockClear()
  })

  describe('#extract', () => {
    it('returns some object', () => {
      expect(cache.extract()).toStrictEqual({})
    })

    it('invokes the callback', () => {
      cache.extract()
      expect(onExtract).toHaveBeenCalledTimes(1)
    })
  })

  describe('#read', () => {
    it('returns null', () => {
      expect(cache.read({ query, optimistic: true })).toBeNull()
    })
  })

  describe('#write', () => {
    it('does not throw any error', () => {
      expect(() => cache.write({ query, dataId: '', result: ''})).not.toThrow()
    })
  })

  describe('#diff', () => {
    it('returns empty object', () => {
      expect(cache.diff({ query, optimistic: true })).toMatchObject({})
    })
  })

  describe('#watch', () => {
    it('returns empty thunk', () => {
      const callback = jest.fn()
      expect(cache.watch({ query, callback, optimistic: true })).toBeInstanceOf(Function)
      expect(callback).not.toHaveBeenCalled()
    })
  })

  describe('#evict', () => {
    it('tells success', () => {
      expect(cache.evict({ query })).toMatchObject({ success: true })
    })
  })

  describe('#reset', () => {
    it('returns an empty promise', async () => {
      expect(async () => await cache.reset()).not.toThrow()
    })
  })

  describe('#restore', () => {
    it('returns itself', () => {
      expect(cache.restore(null)).toBe(cache)
    })
  })

  describe('#removeOptimistic', () => {
    it('does not throw any error', () => {
      expect(() => cache.removeOptimistic('')).not.toThrowError()
    })
  })

  describe('#performTransaction', () => {
    it('does not throw any error', () => {
      const transaction: Transaction<unknown> = jest.fn()
      expect(() => cache.performTransaction(transaction)).not.toThrowError()
      expect(transaction).toHaveBeenCalledTimes(1)
    })
  })

  describe('#recordOptimisticTransaction', () => {
    it('does not throw any error', () => {
      const transaction: Transaction<unknown> = jest.fn()
      expect(() => cache.recordOptimisticTransaction(transaction, '')).not.toThrowError()
      expect(transaction).toHaveBeenCalledTimes(1)
    })
  })
})
