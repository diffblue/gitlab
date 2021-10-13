import Vue from 'vue';
import { createRouter } from './router';
import OnDemandScans from './components/on_demand_scans.vue';
import { HELP_PAGE_PATH } from './constants';

export default () => {
  const el = document.querySelector('#js-on-demand-scans');
  if (!el) {
    return null;
  }

  const { newDastScanPath, emptyStateSvgPath } = el.dataset;

  return new Vue({
    el,
    router: createRouter(),
    provide: {
      newDastScanPath,
      helpPagePath: HELP_PAGE_PATH,
      emptyStateSvgPath,
    },
    render(h) {
      return h(OnDemandScans);
    },
  });
};
