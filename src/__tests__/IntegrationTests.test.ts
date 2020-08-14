import {} from '../types/apollo-client-devtools';
import Bridge from 'apollo-client-devtools/src/bridge';
import { initBackend } from 'apollo-client-devtools/src/backend';
import { installHook } from 'apollo-client-devtools/src/backend/hook';
import ApolloClientPretender from '../ApolloClientPretender';

describe('integration', () => {
  let bridge: Bridge;

  beforeAll(done => {
    window.__APOLLO_CLIENT__ = new ApolloClientPretender();
    bridge = new Bridge({
      listen(fn: Function) {
        const listener = (evt: any) => {
          fn(evt.data.payload);
        };
        window.addEventListener('message', listener);
      },
      send(data: { event: string, payload: any }) {
        window.postMessage({ payload: data }, '*');
      }
    });
    installHook(window, 'test');
    setTimeout(done, 1000); // Wait until hook finds ApolloClient
  });

  describe('#initBackend', () => {
    it('emits `ready` event', done => {
      bridge.addListener('ready', (message: string) => {
        expect(message).toBe('2.0.0');
        done();
      });
      initBackend(bridge, window.__APOLLO_DEVTOOLS_GLOBAL_HOOK__, window.localStorage);
    });
  });
});
