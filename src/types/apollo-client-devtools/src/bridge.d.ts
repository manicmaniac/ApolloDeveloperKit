import { EventEmitter } from 'events'

type Message = string | { event: string, payload: object }

interface Wall {
  listen(fn: (message: Message) => void): void
  send(message: Message): void
}

export default class Bridge extends EventEmitter {
  constructor(wall: Wall)
  send(event: string, payload: unknown): void
  log(message: string): void
}
