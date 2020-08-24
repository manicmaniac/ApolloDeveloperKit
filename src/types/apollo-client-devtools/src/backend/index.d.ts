import { Hook } from './hook'
import Bridge from '../bridge'

export const sendBridgeReady: () => void
export const initBackend: (bridge: Bridge, hook: Hook, storage: Storage) => void
