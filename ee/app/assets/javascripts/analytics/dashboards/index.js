import Vue from 'vue';
import EmptyComponent from '~/vue_shared/components/empty_component';

export default () => {
  const el = document.querySelector('#js-group-analytics-dashboards');

  return new Vue({
    el,
    name: 'GroupAnalyticsDashboards',
    render: (createElement) => createElement(EmptyComponent),
  });
};
