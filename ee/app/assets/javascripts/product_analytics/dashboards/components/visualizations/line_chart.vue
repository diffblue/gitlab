<script>
import { s__ } from '~/locale';

export default {
  name: 'LineChart',
  props: {
    data: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    options: {
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
