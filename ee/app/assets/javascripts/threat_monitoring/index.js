import { defaultDataIdFromObject } from 'apollo-cache-inmemory';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ThreatMonitoringApp from './components/app.vue';
import createStore from './store';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
      assumeImmutableResults: true,
      cacheConfig: {
        dataIdFromObject: (object) => {
          // eslint-disable-next-line no-underscore-dangle
          if (object.__typename === 'AlertManagementAlert') {
            return object.iid;
          }
          return defaultDataIdFromObject(object);
        },
      },
    },
  ),
});

export default () => {
  const el = document.querySelector('#js-threat-monitoring-app');
  const {
    networkPolicyStatisticsEndpoint,
    environmentsEndpoint,
    emptyStateSvgPath,
    networkPolicyNoDataSvgPath,
    newPolicyPath,
    documentationPath,
    defaultEnvironmentId,
    projectPath,
  } = el.dataset;

  const store = createStore();
  store.dispatch('threatMonitoring/setStatisticsEndpoint', networkPolicyStatisticsEndpoint);
  store.dispatch('threatMonitoring/setEnvironmentEndpoint', environmentsEndpoint);

  return new Vue({
    apolloProvider,
    el,
    provide: {
      documentationPath,
      emptyStateSvgPath,
      projectPath,
    },
    store,
    render(createElement) {
      return createElement(ThreatMonitoringApp, {
        props: {
          networkPolicyNoDataSvgPath,
          defaultEnvironmentId: parseInt(defaultEnvironmentId, 10),
          newPolicyPath,
        },
      });
    },
  });
};
