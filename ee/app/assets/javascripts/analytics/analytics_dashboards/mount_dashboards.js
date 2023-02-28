import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { convertObjectPropsToCamelCase, parseBoolean } from '~/lib/utils/common_utils';
import createRouter from './router';

export default (id, App) => {
  const el = document.getElementById(id);

  if (!el) {
    return false;
  }

  const {
    jitsuKey,
    projectId,
    projectFullPath,
    collectorHost,
    chartEmptyStateIllustrationPath,
    routerBase,
    features,
    showInstrumentationDetailsButton,
  } = el.dataset;
  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    router: createRouter(routerBase),
    provide: {
      jitsuKey,
      projectFullPath,
      projectId,
      collectorHost,
      chartEmptyStateIllustrationPath,
      features: convertObjectPropsToCamelCase(JSON.parse(features)),
      showInstrumentationDetailsButton: parseBoolean(showInstrumentationDetailsButton),
    },
    render(h) {
      return h(App);
    },
  });
};
