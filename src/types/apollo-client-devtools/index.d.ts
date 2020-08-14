// Type definitions for apollo-client-devtools 2.2.5
// Project: https://github.com/apollographql/apollo-client-devtools
// Definitions by: Ryosuke Ito <rito.0305@gmail.com>
// TypeScript Version: 3.5.2

import { Hook } from 'apollo-client-devtools/src/backend/hook'

declare global {
  interface Window {
    __APOLLO_CLIENT__: unknown
    __APOLLO_DEVTOOLS_GLOBAL_HOOK__: Hook
  }
}

export {}
