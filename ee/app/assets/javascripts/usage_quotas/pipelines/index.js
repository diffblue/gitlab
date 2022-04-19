import Vue from 'vue';
import PipelineUsageApp from './components/app.vue';

export default () => {
  const el = document.getElementById('js-pipeline-usage-app');

  if (!el) {
    return false;
  }

  const {
    namespaceActualPlanName,
    buyAdditionalMinutesPath,
    buyAdditionalMinutesTarget,
  } = el.dataset;

  return new Vue({
    el,
    name: 'PipelinesUsageView',
    provide: {
      namespaceActualPlanName,
      buyAdditionalMinutesPath,
      buyAdditionalMinutesTarget,
    },
    render(createElement) {
      return createElement(PipelineUsageApp);
    },
  });
};
