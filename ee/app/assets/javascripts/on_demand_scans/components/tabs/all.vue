<script>
import { __ } from '~/locale';
import BaseTab from './base_tab.vue';

export default {
  components: {
    BaseTab,
  },
  i18n: {
    title: __('All'),
  },
};
</script>

<template>
  <base-tab :title="$options.i18n.title" v-bind="$attrs" />
</template>
