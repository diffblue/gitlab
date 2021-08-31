import Vue from 'vue';
import { urlQueryToFilter } from '~/vue_shared/components/filtered_search_bar/filtered_search_utils';
import CodeAnalyticsApp from './components/app.vue';
import store from './store';

export default () => {
  const container = document.getElementById('js-code-review-analytics');
  const {
    projectId,
    projectPath,
    newMergeRequestUrl,
    emptyStateSvgPath,
    milestonePath,
    labelsPath,
  } = container.dataset;
  if (!container) return;

  store.dispatch('filters/setEndpoints', {
    milestonesEndpoint: milestonePath,
    labelsEndpoint: labelsPath,
    projectEndpoint: projectPath,
  });
  const { milestone_title = null, label_name = [] } = urlQueryToFilter(window.location.search, {
    legacySpacesDecode: true,
  });
  store.dispatch('filters/initialize', {
    selectedMilestone: milestone_title,
    selectedLabelList: label_name,
  });

  // eslint-disable-next-line no-new
  new Vue({
    el: container,
    store,
    render(h) {
      return h(CodeAnalyticsApp, {
        props: {
          projectId: Number(projectId),
          projectPath,
          newMergeRequestUrl,
          emptyStateSvgPath,
        },
      });
    },
  });
};
