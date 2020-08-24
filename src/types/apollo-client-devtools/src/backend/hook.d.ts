export function installHook(window: Window, devToolsVersion: string): void

export interface Hook {
  ApolloClient: unknown
  actionLog: string[]
  devToolsVersion: string
  on(event: string, fn: (...args: unknown[]) => void): void
  once(event: string, fn: (...args: unknown[]) => void): void
  off(event: string, fn: (...args: unknown[]) => void): void
  emit(event: string): void
}
