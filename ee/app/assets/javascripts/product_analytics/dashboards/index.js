import Vue from 'vue';
import AnalyticsApp from './components/analytics_app.vue';
import createRouter from './router';

export default () => {
  const el = document.getElementById('js-analytics-dashboard');

  const { projectId } = el.dataset;

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    router: createRouter(),
    provide: {
      projectId,
    },
    render(h) {
      return h(AnalyticsApp);
    },
  });
};
