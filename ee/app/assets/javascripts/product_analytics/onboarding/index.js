import Vue from 'vue';

import ProductAnalyticsSettingsInstrumentationInstructions from './settings_instrumentation_instructions.vue';

export function initProductAnalyticsSettingsInstrumentationInstructions() {
  const el = document.getElementById('js-product-analytics-instrumentation-settings');
  if (!el) {
    return null;
  }

  const { collectorHost, trackingKey, dashboardsPath, onboardingPath } = el.dataset;

  return new Vue({
    el,
    provide: {
      collectorHost,
    },
    render: (createElement) =>
      createElement(ProductAnalyticsSettingsInstrumentationInstructions, {
        props: {
          trackingKey,
          dashboardsPath,
          onboardingPath,
        },
      }),
  });
}
