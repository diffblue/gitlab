<script>
import MetricImagesTab from '~/vue_shared/components/metric_images/metric_images_tab.vue';
import service from 'ee_component/issues/show/components/incidents/service';
import createStore from '~/vue_shared/components/metric_images/store';

export default {
  components: {
    MetricImagesTab,
  },
  inject: ['uploadMetricsFeatureAvailable'],
  store: createStore({}, service),
};
</script>

<template>
  <metric-images-tab v-if="uploadMetricsFeatureAvailable" data-testid="metrics-tab" />
</template>
