import type { EventEmitter } from 'events'

type EventSourceConfigurationType = {
  withCredentials: boolean
}

type ReadyStateType = 0 | 1 | 2

declare const defaultOptions: {
  withCredentials: false
}

export const sources: { [key: string]: EventSource }

export default class EventSource {
  static CONNECTING: ReadyStateType
  static OPEN: ReadyStateType
  static CLOSED: ReadyStateType

  CONNECTING: ReadyStateType
  OPEN: ReadyStateType
  CLOSED: ReadyStateType

  __emitter: EventEmitter
  onerror: ((this: EventSource, ev: Event) => any) | null
  onmessage: ((this: EventSource, ev: MessageEvent) => any) | null
  onopen: ((this: EventSource, ev: Event) => any) | null
  readyState: ReadyStateType
  url: string
  withCredentials: boolean

  constructor(
    url: string,
    configuration?: EventSourceInit
  )

  addEventListener(eventName: string, listener: Function): void
  removeEventListener(eventName: string, listener: Function): void
  close(): void
  emit(eventName: string, messageEvent?: MessageEvent): void
  emitError(error: any): void
  emitOpen(): void
  emitMessage(message: any): void

  // Actually missing
  dispatchEvent(event: Event): boolean
}
