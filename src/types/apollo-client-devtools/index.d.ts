declare module 'apollo-client-devtools/src/backend' {
    import Bridge from 'apollo-client-devtools/src/bridge';
    import { Hook } from 'apollo-client-devtools/src/backend/hook';

    export const sendBridgeReady: () => void;
    export const initBackend: (bridge: Bridge, hook: Hook, storage: any) => void;
}

declare module 'apollo-client-devtools/src/bridge' {
    import EventEmitter = require('events');

    type Message = string | { event: string, payload: object }

    interface Wall {
        listen(fn: (message: Message) => void): void;
        send(message: Message): void;
    }

    export default class Bridge extends EventEmitter {
        constructor(wall: Wall);
        send(event: string, payload: any): void
        log(message: string): void
    }
}

declare module 'apollo-client-devtools/src/backend/hook' {
    global {
        interface Window {
            __APOLLO_DEVTOOLS_GLOBAL_HOOK__: Hook
        }
    }

    export function installHook(window: Window, devToolsVersion: string): void;

    export interface Hook {
        ApolloClient: any,
        actionLog: string[],
        devToolsVersion: string,
        on(event: string, fn: Function): void;
        once(event: string, fn: Function): void;
        off(event: string, fn: Function): void;
        emit(event: string): void;
    }
}