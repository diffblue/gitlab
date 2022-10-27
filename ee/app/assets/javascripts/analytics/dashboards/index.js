import Vue from 'vue';
import DashboardsApp from './components/app.vue';

export default () => {
  const el = document.querySelector('#js-analytics-dashboards-app');
  const { groupFullPath, groupName } = el.dataset;

  return new Vue({
    el,
    name: 'DashboardsApp',
    render: (createElement) =>
      createElement(DashboardsApp, {
        props: {
          groupFullPath,
          groupName,
        },
      }),
  });
};
