import Vue from 'vue';
import AnalyticsApp from './components/analytics_app.vue';
import createRouter from './router';

export default () => {
  const el = document.getElementById('js-analytics-dashboard');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    router: createRouter(),
    render(h) {
      return h(AnalyticsApp);
    },
  });
};
