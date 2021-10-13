import Vue from 'vue';
import { createRouter } from './router';
import OnDemandScans from './components/on_demand_scans.vue';

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
      emptyStateSvgPath,
    },
    render(h) {
      return h(OnDemandScans);
    },
  });
};
