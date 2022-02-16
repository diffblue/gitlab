<script>
import { GlIcon, GlToken, GlFilteredSearchToken, GlFilteredSearchSuggestion } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  statuses: [
    {
      id: 1,
      value: 'satisfied',
      text: __('Satisfied'),
      icon: 'status-success',
      iconClass: 'gl-text-green-700',
      containerClass: 'gl-bg-green-100 gl-text-gray-900',
    },
    {
      id: 2,
      value: 'failed',
      text: __('Failed'),
      icon: 'status-failed',
      iconClass: 'gl-text-red-700',
      containerClass: 'gl-bg-red-100 gl-text-gray-900',
    },
    {
      id: 3,
      value: 'missing',
      text: __('Missing'),
      icon: 'status-waiting',
      iconClass: 'gl-text-gray-900',
      containerClass: 'gl-bg-gray-100 gl-text-gray-900',
    },
  ],
  components: {
    GlIcon,
    GlToken,
    GlFilteredSearchToken,
    GlFilteredSearchSuggestion,
  },
  props: {
    config: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: true,
    },
  },
  computed: {
    activeStatus() {
      return this.$options.statuses.find((status) => status.value === this.value.data);
    },
  },
};
</script>

<template>
  <gl-filtered-search-token v-bind="{ ...$props, ...$attrs }" v-on="$listeners">
    <template #view-token>
      <gl-token
        v-if="activeStatus"
        variant="search-value"
        :class="['gl-display-flex', activeStatus.containerClass]"
      >
        <gl-icon :name="activeStatus.icon" :class="activeStatus.iconClass" />
        <div class="gl-ml-2">{{ activeStatus.text }}</div>
      </gl-token>
    </template>
    <template #suggestions>
      <gl-filtered-search-suggestion
        v-for="status in $options.statuses"
        :key="status.id"
        :value="status.value"
      >
        <div class="gl-display-flex">
          <gl-icon :name="status.icon" :class="status.iconClass" />
          <div class="gl-ml-2">{{ status.text }}</div>
        </div>
      </gl-filtered-search-suggestion>
    </template>
  </gl-filtered-search-token>
</template>
