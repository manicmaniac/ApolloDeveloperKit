import { Hook } from 'apollo-client-devtools/src/backend/hook';
import Bridge from 'apollo-client-devtools/src/bridge';

export const sendBridgeReady: () => void;
export const initBackend: (bridge: Bridge, hook: Hook, storage: Storage) => void;
