import Vue from 'vue';
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
    jitsuHost,
    jitsuProjectId,
    chartEmptyStateIllustrationPath,
  } = el.dataset;

  return new Vue({
    el,
    router: createRouter(),
    provide: {
      jitsuKey,
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
