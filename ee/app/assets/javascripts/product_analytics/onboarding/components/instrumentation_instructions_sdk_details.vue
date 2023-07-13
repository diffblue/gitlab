<script>
import { s__ } from '~/locale';
import AnalyticsClipboardInput from '../../shared/analytics_clipboard_input.vue';

export default {
  name: 'ProductAnalyticsInstrumentationInstructionsSdkDetails',
  components: {
    AnalyticsClipboardInput,
  },
  inject: {
    collectorHost: {
      type: String,
    },
  },
  props: {
    trackingKey: {
      type: String,
      required: true,
    },
  },
  i18n: {
    sdkHost: s__('ProductAnalytics|SDK host'),
    sdkHostDescription: s__('ProductAnalytics|The host to send all tracking events to'),
    sdkAppId: s__('ProductAnalytics|SDK application ID'),
    sdkAppIdDescription: s__('ProductAnalytics|The sender of tracking events'),
  },
};
</script>

<template>
  <section class="gl-display-flex gl-flex-wrap gl-mb-6">
    <analytics-clipboard-input
      class="gl-mr-6 gl-mb-6 gl-md-mb-0"
      :label="$options.i18n.sdkHost"
      :description="$options.i18n.sdkHostDescription"
      :value="collectorHost"
    />

    <analytics-clipboard-input
      :label="$options.i18n.sdkAppId"
      :description="$options.i18n.sdkAppIdDescription"
      :value="trackingKey"
    />
  </section>
</template>
