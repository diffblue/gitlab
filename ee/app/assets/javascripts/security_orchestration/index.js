import { defaultDataIdFromObject } from '@apollo/client/core';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import ThreatMonitoringApp from './components/app.vue';

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
  const { documentationPath, projectPath } = el.dataset;

  return new Vue({
    apolloProvider,
    el,
    provide: {
      documentationPath,
      projectPath,
    },
    render(createElement) {
      return createElement(ThreatMonitoringApp, {});
    },
  });
};
