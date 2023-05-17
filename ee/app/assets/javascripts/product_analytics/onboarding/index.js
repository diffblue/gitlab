import Vue from 'vue';

import InstrumentationInstructions from './components/instrumentation_instructions.vue';

export function initProductAnalyticsInstrumentationInstructions() {
  const el = document.getElementById('js-product-analytics-instrumentation-settings');
  if (!el) {
    return null;
  }

  const { collectorHost, trackingKey, dashboardsPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      collectorHost,
    },
    render: (createElement) =>
      createElement(InstrumentationInstructions, {
        props: {
          trackingKey,
          dashboardsPath,
        },
      }),
  });
}
