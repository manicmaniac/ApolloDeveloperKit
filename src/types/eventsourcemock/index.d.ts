import type { EventEmitter } from 'events'

type EventSourceConfigurationType = {
  withCredentials: boolean
}

type ReadyStateType = 0 | 1 | 2

declare const defaultOptions: {
  withCredentials: false
}

export const sources: Record<string, EventSource>

export default class EventSource {
  static CONNECTING: ReadyStateType
  static OPEN: ReadyStateType
  static CLOSED: ReadyStateType

  CONNECTING: ReadyStateType
  OPEN: ReadyStateType
  CLOSED: ReadyStateType

  __emitter: EventEmitter
  onerror: ((this: EventSource, ev: Event) => unknown) | null
  onmessage: ((this: EventSource, ev: MessageEvent) => unknown) | null
  onopen: ((this: EventSource, ev: Event) => unknown) | null
  readyState: ReadyStateType
  url: string
  withCredentials: boolean

  constructor(
    url: string,
    configuration?: EventSourceInit
  )

  addEventListener(eventName: string, listener: (ev: Event) => void): void
  removeEventListener(eventName: string, listener: (ev: Event) => void): void
  close(): void
  emit(eventName: string, messageEvent?: MessageEvent): void
  emitError(error: Event): void
  emitOpen(): void
  emitMessage(message: MessageEvent): void

  // Actually missing
  dispatchEvent(event: Event): boolean
}
