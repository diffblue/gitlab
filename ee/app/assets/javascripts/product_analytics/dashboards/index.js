import Vue from 'vue';
import AnalyticsDashboard from './components/analytics_dashboard.vue';

export default () => {
  const el = document.getElementById('js-analytics-dashboard');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    render(h) {
      return h(AnalyticsDashboard);
    },
  });
};
