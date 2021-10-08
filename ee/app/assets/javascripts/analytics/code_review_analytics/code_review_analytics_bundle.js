import Vue from 'vue';
import { extractFilterQueryParameters } from '~/analytics/shared/utils';
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

  const { selectedMilestone, selectedLabelList } = extractFilterQueryParameters(
    window.location.search,
  );
  store.dispatch('filters/initialize', { selectedMilestone, selectedLabelList });

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
