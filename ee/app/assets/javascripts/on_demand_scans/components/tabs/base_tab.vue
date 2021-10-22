<script>
import { GlTab, GlBadge } from '@gitlab/ui';
import EmptyState from '../empty_state.vue';

export default {
  components: {
    GlTab,
    GlBadge,
    EmptyState,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    itemsCount: {
      type: Number,
      required: true,
    },
    emptyStateTitle: {
      type: String,
      required: false,
      default: undefined,
    },
    emptyStateText: {
      type: String,
      required: false,
      default: undefined,
    },
  },
};
</script>

<template>
  <gl-tab v-bind="$attrs">
    <template #title>
      {{ title }}
      <gl-badge size="sm" class="gl-tab-counter-badge">{{ itemsCount }}</gl-badge>
    </template>
    <empty-state :title="emptyStateTitle" :text="emptyStateText" no-primary-button />
  </gl-tab>
</template>
