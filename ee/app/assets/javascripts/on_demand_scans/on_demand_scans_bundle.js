import Vue from 'vue';
import OnDemandScans from './components/on_demand_scans.vue';

export default () => {
  const el = document.querySelector('#js-on-demand-scans');
  if (!el) {
    return null;
  }

  const { newDastScanPath, helpPagePath, emptyStateSvgPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      newDastScanPath,
      helpPagePath,
      emptyStateSvgPath,
    },
    render(h) {
      return h(OnDemandScans);
    },
  });
};
