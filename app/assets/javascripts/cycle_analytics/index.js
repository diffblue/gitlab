import Vue from 'vue';
import Translate from '../vue_shared/translate';
import CycleAnalytics from './components/base.vue';
import createStore from './store';

Vue.use(Translate);

export default () => {
  const store = createStore();
  const el = document.querySelector('#js-cycle-analytics');
  const {
    noAccessSvgPath,
    noDataSvgPath,
    requestPath,
    fullPath,
    projectId,
    groupId,
    groupPath,
    labelsPath,
    milestonesPath,
  } = el.dataset;

  store.dispatch('initializeVsa', {
    projectId: parseInt(projectId, 10),
    endpoints: {
      requestPath,
      fullPath,
      labelsPath,
      milestonesPath,
      groupId: parseInt(groupId, 10),
      groupPath,
    },
    features: {
      cycleAnalyticsForGroups: Boolean(gon?.licensed_features?.cycleAnalyticsForGroups),
    },
  });

  // eslint-disable-next-line no-new
  new Vue({
    el,
    name: 'CycleAnalytics',
    store,
    render: (createElement) =>
      createElement(CycleAnalytics, {
        props: {
          noDataSvgPath,
          noAccessSvgPath,
          fullPath,
        },
      }),
  });
};
