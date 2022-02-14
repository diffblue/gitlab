import { defaultDataIdFromObject } from '@apollo/client/core';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ThreatMonitoringApp from './components/app.vue';
import { isValidEnvironmentId } from './utils';
import createStore from './store';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(
    {},
    {
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

  const environmentId = parseInt(defaultEnvironmentId, 10);
  // We require the project to have at least one available environment.
  // An invalid default environment id means there there are no available
  // environments, therefore infrastructure cannot be set up. A valid default
  // environment id only means that infrastructure *might* be set up.
  const hasEnvironment = isValidEnvironmentId(environmentId);

  const store = createStore();
  store.dispatch('threatMonitoring/setStatisticsEndpoint', networkPolicyStatisticsEndpoint);
  store.dispatch('threatMonitoring/setEnvironmentEndpoint', environmentsEndpoint);
  store.dispatch('threatMonitoring/setHasEnvironment', hasEnvironment);
  if (hasEnvironment) {
    store.dispatch('threatMonitoring/setCurrentEnvironmentId', environmentId);
  }

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
          newPolicyPath,
        },
      });
    },
  });
};
