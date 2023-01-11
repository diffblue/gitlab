import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import AnalyticsApp from './product_analytics_app.vue';
import createRouter from './router';

export default () => {
  const el = document.getElementById('js-analytics-dashboard');

  if (!el) {
    return false;
  }

  const {
    jitsuKey,
    projectId,
    projectFullPath,
    jitsuHost,
    jitsuProjectId,
    chartEmptyStateIllustrationPath,
  } = el.dataset;
  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    router: createRouter(),
    provide: {
      jitsuKey,
      projectFullPath,
      projectId,
      jitsuHost,
      jitsuProjectId,
      chartEmptyStateIllustrationPath,
    },
    render(h) {
      return h(AnalyticsApp);
    },
  });
};
