import { Hook } from 'apollo-client-devtools/src/backend/hook';

declare global {
    interface Window {
        __APOLLO_CLIENT__: any
        __APOLLO_DEVTOOLS_GLOBAL_HOOK__: Hook
    }
}

export {}
