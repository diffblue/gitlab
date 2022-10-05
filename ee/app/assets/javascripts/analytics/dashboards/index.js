import Vue from 'vue';
import DashboardsApp from './app.vue';

export default () => {
  const el = document.querySelector('#js-analytics-dashboards-app');
  const { groupFullPath } = el.dataset;

  return new Vue({
    el,
    name: 'DashboardsApp',
    store: {},
    render: (createElement) =>
      createElement(DashboardsApp, {
        props: {
          groupFullPath,
        },
      }),
  });
};
