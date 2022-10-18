<script>
import { s__ } from '~/locale';

export default {
  name: 'CubeLineChart',
  props: {
    data: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    chartOptions: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    customizations: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  i18n: {
    content: s__('ProductAnalytics|Widgets content'),
  },
};
</script>

<template>
  <p>{{ $options.i18n.content }}</p>
</template>
