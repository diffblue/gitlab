import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import {
  convertObjectPropsToCamelCase,
  convertArrayToCamelCase,
  parseBoolean,
} from '~/lib/utils/common_utils';
import createRouter from './router';

const buildAnalyticsDashboardPointer = (analyticsDashboardPointerJSON = '') => {
  return analyticsDashboardPointerJSON.length
    ? convertObjectPropsToCamelCase(JSON.parse(analyticsDashboardPointerJSON))
    : null;
};

export default (id, App) => {
  const el = document.getElementById(id);

  if (!el) {
    return false;
  }

  const {
    dashboardProject: analyticsDashboardPointerJSON = '',
    jitsuKey,
    projectId,
    projectFullPath,
    collectorHost,
    chartEmptyStateIllustrationPath,
    dashboardEmptyStateIllustrationPath,
    routerBase,
    features,
    showInstrumentationDetailsButton,
  } = el.dataset;

  const analyticsDashboardPointer = buildAnalyticsDashboardPointer(analyticsDashboardPointerJSON);

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    router: createRouter(routerBase),
    provide: {
      customDashboardsProject: analyticsDashboardPointer,
      jitsuKey,
      projectFullPath,
      projectId,
      collectorHost,
      chartEmptyStateIllustrationPath,
      dashboardEmptyStateIllustrationPath,
      features: convertArrayToCamelCase(JSON.parse(features)),
      showInstrumentationDetailsButton: parseBoolean(showInstrumentationDetailsButton),
    },
    render(h) {
      return h(App);
    },
  });
};
