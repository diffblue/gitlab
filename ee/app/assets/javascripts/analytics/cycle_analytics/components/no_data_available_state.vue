<script>
import { GlEmptyState } from '@gitlab/ui';
import { NO_DATA_AVAILABLE_TITLE, NO_DATA_AVAILABLE_DESCRIPTION } from '../constants';

export default {
  name: 'NoDataAvailableState',
  components: {
    GlEmptyState,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: NO_DATA_AVAILABLE_TITLE,
    },
    description: {
      type: String,
      required: false,
      default: NO_DATA_AVAILABLE_DESCRIPTION,
    },
  },
};
</script>
<template>
  <gl-empty-state class="gl-mt-0" :content-class="['gl-text-center']">
    <template #title>
      <div class="gl-font-weight-bold" data-testid="vsa-no-data-title">{{ title }}</div>
    </template>
    <template #description>
      <div class="gl-text-gray-500" data-testid="vsa-no-data-description">{{ description }}</div>
    </template>
  </gl-empty-state>
</template>
