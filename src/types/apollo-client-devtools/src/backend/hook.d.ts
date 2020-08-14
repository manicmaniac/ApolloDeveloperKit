export function installHook(window: Window, devToolsVersion: string): void;

export interface Hook {
  ApolloClient: any;
  actionLog: string[];
  devToolsVersion: string;
  on(event: string, fn: Function): void;
  once(event: string, fn: Function): void;
  off(event: string, fn: Function): void;
  emit(event: string): void;
}
